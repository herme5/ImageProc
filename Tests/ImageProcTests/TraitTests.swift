//
//  TraitTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 09/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

/// An image or a color can resolve differently for the interface style and the accessibility contrast. Processing one
/// has to run per variant and hand back something that still follows the environment.
final class TraitTests: XCTestCase {

    static func traits(_ style: UIUserInterfaceStyle,
                       _ contrast: UIAccessibilityContrast = .normal,
                       scale: CGFloat = 2) -> UITraitCollection {
        return UIImage._colorTraitCollection(style: style, contrast: contrast, scale: scale)
    }

    func solid(_ color: UIColor, side: CGFloat = 8, scale: CGFloat = 2) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    /// An image resolving to a different color per interface style.
    func dynamicImage(light: UIColor = .red, dark: UIColor = .blue, side: CGFloat = 8) -> UIImage {
        let asset = UIImageAsset()
        asset.register(solid(light, side: side), with: Self.traits(.light))
        asset.register(solid(dark, side: side), with: Self.traits(.dark))
        return asset.image(with: Self.traits(.light))
    }

    /// The color of the variant this image resolves to for the given traits, sampled at a relative position so the
    /// point stays meaningful whatever the operation did to the size.
    func hex(_ image: UIImage, _ traits: UITraitCollection, at spot: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> String {
        let resolved = image.imageAsset?.image(with: traits) ?? image
        guard let cgImage = resolved.cgImage else { return "noCGImage" }
        let coordinate = CGImage.PixelCoordinate(column: Int(CGFloat(cgImage.width) * spot.x),
                                                 row: Int(CGFloat(cgImage.height) * spot.y))
        return cgImage.color(at: coordinate)?.hexCode ?? "nil"
    }

    /// What a real view hierarchy displays for the given interface style.
    func displayed(_ image: UIImage, style: UIUserInterfaceStyle) -> String {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        window.overrideUserInterfaceStyle = style
        let view = UIImageView(image: image)
        view.frame = window.bounds
        window.addSubview(view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2
        let shot = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        return shot.cgImage.flatMap {
            $0.color(at: CGImage.PixelCoordinate(column: $0.width / 2, row: $0.height / 2))?.hexCode
        } ?? "nil"
    }

    func testVarianceDetection() throws {
        XCTAssertFalse(solid(.red)._colorTraitVariance.varies)
        XCTAssertFalse(UIImage(named: "splash-rounded-100", in: Bundle.module, with: nil)!
            ._colorTraitVariance.varies)
        XCTAssertTrue(dynamicImage()._colorTraitVariance.varies)
        XCTAssertTrue(dynamicImage()._colorTraitVariance.style)
        XCTAssertFalse(dynamicImage()._colorTraitVariance.contrast)

        XCTAssertFalse(UIColor.red._colorTraitVariance.varies)
        XCTAssertTrue(UIColor { $0.userInterfaceStyle == .dark ? .white : .black }._colorTraitVariance.style)
        // System colors shift with both dimensions.
        XCTAssertTrue(UIColor.systemPink._colorTraitVariance.style)
        XCTAssertTrue(UIColor.systemPink._colorTraitVariance.contrast)
    }

    /// A color that compares by identity rather than by value used to look like it varied, which sent the operation
    /// fanning out over itself until the stack ran out.
    func testColorsThatCompareByIdentityDoNotLookDynamic() throws {
        XCTAssertFalse(UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0"))._colorTraitVariance.varies)
        XCTAssertFalse(UIColor.black._colorTraitVariance.varies)
        XCTAssertFalse(UIColor(white: 0.5, alpha: 1)._colorTraitVariance.varies)
    }

    /// And even if a participant did misreport itself, the fan-out must not re-enter: each operation calls itself
    /// once per variant, so a second level would never terminate.
    func testFanOutIsNotReentrant() throws {
        let dynamicColor = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
        var nested: UIImage??

        _ = solid(.red)._perColorTrait(alsoVarying: dynamicColor._colorTraitVariance) { image, _ in
            nested = image._perColorTrait(alsoVarying: dynamicColor._colorTraitVariance) { inner, _ in inner }
            return image
        }

        XCTAssertNotNil(nested, "the body never ran")
        XCTAssertNil(nested ?? nil, "a nested fan-out must decline instead of recursing")
        XCTAssertFalse(UIImage._isFanningOutOverColorTraits, "the flag has to be cleared on the way out")
    }

    /// An invariant image with an invariant color keeps taking the plain path.
    func testInvariantStaysInvariant() throws {
        let source = solid(.red)
        let output = source.colorized(with: .green)
        XCTAssertFalse(output._colorTraitVariance.varies)
        XCTAssertEqual(output.scale, source.scale)
    }

    /// Each variant is processed on its own: expanding, smoothening and the rest just carry the traits over.
    func testUnaryOperationsProcessEachVariant() throws {
        let source = dynamicImage()
        let ops: [(String, (UIImage) -> UIImage)] = [
            ("expanded", { $0.expanded(bySize: 2, each: 90) }),
            ("smoothened", { $0.smoothened(by: 1, sizeKept: true) }),
            ("scaled", { $0.scaled(uniform: 0.5) }),
            ("rotated", { $0.rotated(by: 90) }),
            ("cropped", { $0.cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4)) }),
            ("flippedHorizontally", { $0.flippedHorizontally() }),
            ("withAlphaComponent", { $0.withAlphaComponent(1) })
        ]
        for (name, op) in ops {
            let output = op(source)
            XCTAssertTrue(output._colorTraitVariance.varies, name)
            XCTAssertEqual(hex(output, Self.traits(.light)), "#FF0000", name)
            XCTAssertEqual(hex(output, Self.traits(.dark)), "#0000FF", name)
        }
    }

    /// `colorized` pairs each variant with the matching resolution of the color.
    func testColorizedMatchesVariants() throws {
        let dynamicColor = UIColor { $0.userInterfaceStyle == .dark ? .green : .yellow }

        // An invariant image and a dynamic color: the output gains the color's variance.
        let fromInvariant = solid(.red).colorized(with: dynamicColor)
        XCTAssertTrue(fromInvariant._colorTraitVariance.varies)
        XCTAssertEqual(hex(fromInvariant, Self.traits(.light)), "#FFFF00")
        XCTAssertEqual(hex(fromInvariant, Self.traits(.dark)), "#00FF00")

        // A dynamic image and an invariant color: every variant is colorized with the same color.
        let fromInvariantColor = dynamicImage().colorized(with: .yellow)
        XCTAssertTrue(fromInvariantColor._colorTraitVariance.varies)
        XCTAssertEqual(hex(fromInvariantColor, Self.traits(.light)), "#FFFF00")
        XCTAssertEqual(hex(fromInvariantColor, Self.traits(.dark)), "#FFFF00")

        // Both dynamic: the traits are matched.
        let both = dynamicImage().colorized(with: dynamicColor)
        XCTAssertEqual(hex(both, Self.traits(.light)), "#FFFF00")
        XCTAssertEqual(hex(both, Self.traits(.dark)), "#00FF00")
    }

    /// `stroked` behaves like `colorized` for its color, over an opaque source whose interior stays put.
    func testStrokedMatchesVariants() throws {
        let dynamicColor = UIColor { $0.userInterfaceStyle == .dark ? .green : .yellow }
        let output = solid(.red).stroked(with: dynamicColor, size: 2, each: 90)
        XCTAssertTrue(output._colorTraitVariance.varies)

        // The border is what the color drives; the middle stays the source color.
        XCTAssertEqual(hex(output, Self.traits(.light)), "#FF0000")
        XCTAssertEqual(hex(output, Self.traits(.dark)), "#FF0000")

        // Halfway down the left edge, inside the stroke the horizontal expansion laid down.
        let onBorder = CGPoint(x: 0.05, y: 0.5)
        XCTAssertEqual(hex(output, Self.traits(.light), at: onBorder), "#FFFF00")
        XCTAssertEqual(hex(output, Self.traits(.dark), at: onBorder), "#00FF00")
    }

    /// The three cases the two-image operations have to cover.
    func testCompositesMatchVariants() throws {
        let smallInvariant = solid(.green, side: 4)
        let smallDynamic = dynamicImage(light: .green, dark: .yellow, side: 4)

        // Both invariant: nothing becomes dynamic.
        XCTAssertFalse(solid(.red).drawnUnder(image: smallInvariant)._colorTraitVariance.varies)

        // Only the receiver varies: the invariant one is paired with each of its variants. The argument is drawn
        // over the middle, so the receiver is what shows in the ring around it.
        let receiverVaries = dynamicImage().drawnUnder(image: smallInvariant)
        let inTheRing = CGPoint(x: 0.05, y: 0.5)
        XCTAssertTrue(receiverVaries._colorTraitVariance.varies)
        XCTAssertEqual(hex(receiverVaries, Self.traits(.light), at: inTheRing), "#FF0000")
        XCTAssertEqual(hex(receiverVaries, Self.traits(.dark), at: inTheRing), "#0000FF")
        XCTAssertEqual(hex(receiverVaries, Self.traits(.light)), "#00FF00")
        XCTAssertEqual(hex(receiverVaries, Self.traits(.dark)), "#00FF00")

        // Only the argument varies.
        let argumentVaries = solid(.red).drawnUnder(image: smallDynamic)
        XCTAssertTrue(argumentVaries._colorTraitVariance.varies)
        XCTAssertEqual(hex(argumentVaries, Self.traits(.light)), "#00FF00")
        XCTAssertEqual(hex(argumentVaries, Self.traits(.dark)), "#FFFF00")

        // Both vary: the traits are matched, the smaller one is drawn over the middle.
        let both = dynamicImage().drawnUnder(image: smallDynamic)
        XCTAssertEqual(hex(both, Self.traits(.light)), "#00FF00")
        XCTAssertEqual(hex(both, Self.traits(.dark)), "#FFFF00")

        // `drawnAbove` keeps the receiver on top, and stays dynamic too.
        let above = dynamicImage().drawnAbove(image: smallDynamic)
        XCTAssertTrue(above._colorTraitVariance.varies)
        XCTAssertEqual(hex(above, Self.traits(.light)), "#FF0000")
        XCTAssertEqual(hex(above, Self.traits(.dark)), "#0000FF")
    }

    /// The whole point: the result has to follow a real trait environment, not just answer questions about itself.
    func testOutputFollowsTheEnvironment() throws {
        let outputs: [(String, UIImage)] = [
            ("expanded", dynamicImage().expanded(bySize: 1, each: 90)),
            ("scaled", dynamicImage().scaled(uniform: 0.5)),
            ("colorizedByColor", solid(.red).colorized(with: UIColor { $0.userInterfaceStyle == .dark ? .green : .yellow }))
        ]
        for (name, output) in outputs {
            XCTAssertNotEqual(displayed(output, style: .light), displayed(output, style: .dark), name)
        }

        XCTAssertEqual(displayed(dynamicImage().scaled(uniform: 0.5), style: .light), "#FF0000")
        XCTAssertEqual(displayed(dynamicImage().scaled(uniform: 0.5), style: .dark), "#0000FF")
    }

    /// Only the dimensions that actually vary are rendered, so a style-only input costs two renders and not four.
    func testOnlyVaryingDimensionsAreRendered() throws {
        var renders = 0
        let source = dynamicImage()
        _ = source._perColorTrait { image, _ in
            renders += 1
            return image
        }
        XCTAssertEqual(renders, 2)

        renders = 0
        _ = source._perColorTrait(alsoVarying: UIColor.systemPink._colorTraitVariance) { image, _ in
            renders += 1
            return image
        }
        XCTAssertEqual(renders, 4)
    }

    /// The options still travel, apart from the baseline offset which cannot survive registration.
    func testOptionsOnDynamicOutput() throws {
        let source = dynamicImage()
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        let output = source.scaled(uniform: 0.5)

        XCTAssertEqual(output.renderingMode, .alwaysTemplate)
        XCTAssertEqual(output.alignmentRectInsets, UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        XCTAssertEqual(output.scale, source.scale)
    }
}
