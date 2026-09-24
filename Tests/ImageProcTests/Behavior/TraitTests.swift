//
//  TraitTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 09/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// An image or a color can resolve differently for the interface style and the accessibility contrast. Processing one
/// has to run per variant and hand back something that still follows the environment.
@Suite("Dynamic colors", .tags(.traits))
struct TraitTests {

    static let light = TraitEnvironment.traits(.light)
    static let dark = TraitEnvironment.traits(.dark)

    static let yellowOrGreen = UIColor { $0.userInterfaceStyle == .dark ? .green : .yellow }

    func pixel(_ image: UIImage, _ traits: UITraitCollection, at point: CGPoint = Bitmap.center) -> Pixel? {
        return TraitEnvironment.pixel(image, traits, at: point)
    }

    // MARK: Detecting variance

    @Test("variance is detected per dimension")
    func varianceIsDetectedPerDimension() {
        #expect(!Fixture.solid(.red)._colorTraitVariance.varies)
        #expect(!Fixture.catalog(.splashRounded)._colorTraitVariance.varies)
        #expect(Fixture.dynamic()._colorTraitVariance.style)
        #expect(!Fixture.dynamic()._colorTraitVariance.contrast)

        #expect(!UIColor.red._colorTraitVariance.varies)
        #expect(Self.yellowOrGreen._colorTraitVariance.style)
        // System colors shift with both dimensions.
        #expect(UIColor.systemPink._colorTraitVariance.style)
        #expect(UIColor.systemPink._colorTraitVariance.contrast)
    }

    /// A color that compares by identity rather than by value used to look like it varied, which sent the operation
    /// fanning out over itself until the stack ran out.
    @Test("colors that compare by identity do not look dynamic")
    func colorsThatCompareByIdentityDoNotLookDynamic() {
        #expect(!UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0"))._colorTraitVariance.varies)
        #expect(!UIColor.black._colorTraitVariance.varies)
        #expect(!UIColor(white: 0.5, alpha: 1)._colorTraitVariance.varies)
    }

    /// And even if a participant did misreport itself, the fan-out must not re-enter: each operation calls itself once
    /// per variant, so a second level would never terminate.
    @Test("the fan-out does not re-enter")
    func theFanOutDoesNotReEnter() {
        let variance = Self.yellowOrGreen._colorTraitVariance
        var nested: UIImage??

        _ = Fixture.solid(.red)._perColorTrait(alsoVarying: variance) { image, _ in
            nested = image._perColorTrait(alsoVarying: variance) { inner, _ in inner }
            return image
        }

        #expect(nested != nil, "the body never ran")
        #expect((nested ?? nil) == nil, "a nested fan-out must decline instead of recursing")
        #expect(!UIImage._isFanningOutOverColorTraits, "the flag has to be cleared on the way out")
    }

    /// Only the dimensions that actually vary are rendered, so a style-only input costs two renders and not four.
    @Test("only the varying dimensions are rendered")
    func onlyTheVaryingDimensionsAreRendered() {
        var renders = 0
        let source = Fixture.dynamic()
        _ = source._perColorTrait { image, _ in
            renders += 1
            return image
        }
        #expect(renders == 2)

        renders = 0
        _ = source._perColorTrait(alsoVarying: UIColor.systemPink._colorTraitVariance) { image, _ in
            renders += 1
            return image
        }
        #expect(renders == 4)
    }

    // MARK: Processing each variant

    @Test("invariant inputs give an invariant output")
    func invariantInputsGiveAnInvariantOutput() {
        let source = Fixture.solid(.red)
        let output = source.colorized(with: .green)
        #expect(!output._colorTraitVariance.varies)
        #expect(output.scale == source.scale)
    }

    /// Each variant is processed on its own. The composites are covered below, since their second image matters too.
    @Test("a dynamic image stays dynamic through every operation", arguments: Operation.unary)
    func aDynamicImageStaysDynamicThroughEveryOperation(_ operation: Operation) {
        #expect(operation(Fixture.dynamic())._colorTraitVariance.varies)
    }

    @Test("each variant is processed on its own")
    func eachVariantIsProcessedOnItsOwn() {
        let output = Fixture.dynamic().scaled(uniform: 0.5)
        #expect(pixel(output, Self.light) == Pixel(.red))
        #expect(pixel(output, Self.dark) == Pixel(.blue))
    }

    @Test("colorizing pairs each variant with the matching color")
    func colorizingPairsEachVariantWithTheMatchingColor() {
        // An invariant image and a dynamic color: the output gains the color's variance.
        let fromColor = Fixture.solid(.red).colorized(with: Self.yellowOrGreen)
        #expect(fromColor._colorTraitVariance.varies)
        #expect(pixel(fromColor, Self.light) == Pixel(.yellow))
        #expect(pixel(fromColor, Self.dark) == Pixel(.green))

        // A dynamic image and an invariant color: every variant is colorized with the same color.
        let fromImage = Fixture.dynamic().colorized(with: .yellow)
        #expect(fromImage._colorTraitVariance.varies)
        #expect(pixel(fromImage, Self.light) == Pixel(.yellow))
        #expect(pixel(fromImage, Self.dark) == Pixel(.yellow))

        // Both dynamic: the traits are matched.
        let both = Fixture.dynamic().colorized(with: Self.yellowOrGreen)
        #expect(pixel(both, Self.light) == Pixel(.yellow))
        #expect(pixel(both, Self.dark) == Pixel(.green))
    }

    @Test("stroking follows its color on the border only")
    func strokingFollowsItsColorOnTheBorderOnly() {
        let output = Fixture.solid(.red).stroked(with: Self.yellowOrGreen, size: 2, each: 90)
        #expect(output._colorTraitVariance.varies)

        // The middle stays the source color.
        #expect(pixel(output, Self.light) == Pixel(.red))
        #expect(pixel(output, Self.dark) == Pixel(.red))

        // Halfway down the left edge, inside the stroke the horizontal expansion laid down.
        let onBorder = CGPoint(x: 0.05, y: 0.5)
        #expect(pixel(output, Self.light, at: onBorder) == Pixel(.yellow))
        #expect(pixel(output, Self.dark, at: onBorder) == Pixel(.green))
    }

    @Test("a composite follows whichever of its images varies")
    func aCompositeFollowsWhicheverOfItsImagesVaries() {
        let smallInvariant = Fixture.solid(.green, size: CGSize(width: 4, height: 4))
        let smallDynamic = Fixture.dynamic(light: .green, dark: .yellow, side: 4)

        // Both invariant: nothing becomes dynamic.
        #expect(!Fixture.solid(.red).drawnUnder(image: smallInvariant)._colorTraitVariance.varies)

        // Only the receiver varies: the invariant one is paired with each of its variants. The argument is drawn over
        // the middle, so the receiver is what shows in the ring around it.
        let receiverVaries = Fixture.dynamic().drawnUnder(image: smallInvariant)
        let inTheRing = CGPoint(x: 0.05, y: 0.5)
        #expect(receiverVaries._colorTraitVariance.varies)
        #expect(pixel(receiverVaries, Self.light, at: inTheRing) == Pixel(.red))
        #expect(pixel(receiverVaries, Self.dark, at: inTheRing) == Pixel(.blue))
        #expect(pixel(receiverVaries, Self.light) == Pixel(.green))
        #expect(pixel(receiverVaries, Self.dark) == Pixel(.green))

        // Only the argument varies.
        let argumentVaries = Fixture.solid(.red).drawnUnder(image: smallDynamic)
        #expect(argumentVaries._colorTraitVariance.varies)
        #expect(pixel(argumentVaries, Self.light) == Pixel(.green))
        #expect(pixel(argumentVaries, Self.dark) == Pixel(.yellow))

        // Both vary: the traits are matched, the smaller one is drawn over the middle.
        let both = Fixture.dynamic().drawnUnder(image: smallDynamic)
        #expect(pixel(both, Self.light) == Pixel(.green))
        #expect(pixel(both, Self.dark) == Pixel(.yellow))

        // `drawnAbove` keeps the receiver on top, and stays dynamic too.
        let above = Fixture.dynamic().drawnAbove(image: smallDynamic)
        #expect(above._colorTraitVariance.varies)
        #expect(pixel(above, Self.light) == Pixel(.red))
        #expect(pixel(above, Self.dark) == Pixel(.blue))
    }

    // MARK: Following the environment

    /// The whole point: the result has to follow a real trait environment, not just answer questions about itself.
    @Test("the output follows a real view hierarchy")
    @MainActor
    func theOutputFollowsARealViewHierarchy() {
        let outputs: [UIImage] = [
            Fixture.dynamic().expanded(bySize: 1, each: 90),
            Fixture.dynamic().scaled(uniform: 0.5),
            Fixture.solid(.red).colorized(with: Self.yellowOrGreen)
        ]
        for output in outputs {
            #expect(TraitEnvironment.displayed(output, style: .light) != TraitEnvironment.displayed(output, style: .dark))
        }

        let scaled = Fixture.dynamic().scaled(uniform: 0.5)
        #expect(TraitEnvironment.displayed(scaled, style: .light) == Pixel(.red))
        #expect(TraitEnvironment.displayed(scaled, style: .dark) == Pixel(.blue))
    }

    /// The options still travel, apart from the baseline offset which cannot survive registration.
    @Test("a dynamic output keeps the options it can")
    func aDynamicOutputKeepsTheOptionsItCan() {
        let source = Fixture.dynamic()
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        let output = source.scaled(uniform: 0.5)

        #expect(output.renderingMode == .alwaysTemplate)
        #expect(output.alignmentRectInsets == UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        #expect(output.scale == source.scale)
    }
}
