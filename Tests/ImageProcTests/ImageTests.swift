//
//  ImageTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 22/12/2022.
//  Copyright © 2022 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

final class ImageTests: XCTestCase {

    var fixtureBundle: Bundle!
    var shape0: UIImage!
    var shape1: UIImage!
    var gradientQuarterImage: UIImage!
    var notSoBlueImage: UIImage!
    var smallGradientImage: UIImage!
    var emptyImage: UIImage!
    var color0: UIColor!
    var color1: UIColor!
    var color2: UIColor!
    var shape0ciImage: CIImage!

    override func setUpWithError() throws {
        fixtureBundle = Bundle.module
        shape0 = UIImage(named: "splash-rounded-100", in: fixtureBundle, with: nil)
        shape1 = UIImage(named: "splash-square-100", in: fixtureBundle, with: nil)
        gradientQuarterImage = UIImage(named: "gradient-quarter-100", in: fixtureBundle, with: nil)
        notSoBlueImage = UIImage(named: "not-so-blue-square-100", in: fixtureBundle, with: nil)
        smallGradientImage = UIImage(named: "small-gradient-4", in: fixtureBundle, with: nil)
        color0 = UIColor.systemIndigo
        color1 = UIColor.systemPink
        color2 = UIColor.systemTeal
        emptyImage = UIImage(data: Data(repeating: 0, count: 0))

        // This CIImage will be used for initializion
        // A UIImage initialized this way cannot use some features of this lib.
        shape0ciImage = CIImage(data: shape0.pngData()!)
        shape0 = shape0.withBaselineOffset(fromBottom: 10.0)
    }

    func testImages() throws {
        // These tests cover nominal cases
        XCTAssertNotNil(shape0.colorized(with: color0))
        XCTAssertNotNil(shape0.expanded(bySize: 1))
        XCTAssertNotNil(shape0.stroked(with: color0, size: 1))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: true))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: false))
        XCTAssertNotNil(shape0.withAlphaComponent(1))
        XCTAssertNotNil(shape0.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNotNil(shape0.scaled(uniform: 0.5))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.cropped(to: CGRect(origin: .zero, size: shape0.size / 2)))
        XCTAssertNotNil(shape0.rotated(by: 60))
        XCTAssertNotNil(shape0.flippedHorizontally())
        XCTAssertNotNil(shape0.flippedVertically())
        XCTAssertNotNil(shape0.drawnAbove(image: shape1))
        XCTAssertNotNil(shape0.drawnUnder(image: shape1))
        XCTAssertNotNil(shape0.colorInverted())
        XCTAssertNotNil(shape0.alphaExclusion(with: shape1))
    }

    func testOperationBoundaries() throws {
        // These cases should trigger an error
        // For compatibility it just prints warning and returns the original images
        let image = UIImage(ciImage: shape0ciImage)
        XCTAssertNotNil(image.colorized(with: color0))
        XCTAssertNotNil(image.expanded(bySize: 1))
        XCTAssertNotNil(image.stroked(with: color0, size: 1))
        XCTAssertNotNil(image.smoothened(by: 1, sizeKept: true))
        XCTAssertNotNil(image.smoothened(by: 1, sizeKept: false))
        XCTAssertNotNil(image.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNotNil(image.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(image.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(image.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(image.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(image.cropped(to: CGRect(origin: .zero, size: shape0.sizeInPixel * 2)))
        XCTAssertNotNil(image.cropped(to: CGRect.zero))
        XCTAssertNotNil(image.rotated(by: 60))
        XCTAssertNotNil(image.flippedHorizontally())
        XCTAssertNotNil(image.flippedVertically())
        XCTAssertNotNil(image.drawnAbove(image: shape1))
        XCTAssertNotNil(image.drawnUnder(image: shape1))
        XCTAssertNotNil(image.colorInverted())
        XCTAssertNotNil(image.alphaExclusion(with: shape0))
        XCTAssertNotNil(shape0.alphaExclusion(with: image))
        XCTAssertNil(image.withBitmapAsUIColorArray({ $0 }))
        XCTAssertNil(image.opaquePixelDensity)

        // These tests try to enhance coverage (unexpected values, specific cases)
        XCTAssertNotNil(shape0.colorized(with: UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0"))))
        XCTAssertNotNil(shape0.colorized(with: .black))
        XCTAssertNotNil(shape0.expanded(bySize: 1))
        XCTAssertNotNil(shape0.stroked(with: color0, size: 1))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: true))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: false))
        XCTAssertNotNil(shape0.withAlphaComponent(1))
        XCTAssertNotNil(shape0.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.cropped(to: CGRect(
            origin: CGPoint(x: shape0.size.width, y: shape0.size.height),
            size: shape0.size)))
        XCTAssertNotNil(shape0.rotated(by: 60))
        XCTAssertNotNil(shape0.flippedHorizontally())
        XCTAssertNotNil(shape0.flippedVertically())
        XCTAssertNotNil(shape0.drawnAbove(image: shape1))
        XCTAssertNotNil(shape0.drawnUnder(image: shape1))
        XCTAssertNotNil(shape0.cgImage!.colors(
            at: [CGImage.PixelCoordinate(column: -1, row: 0)]))
        XCTAssertNotNil(shape0.cgImage!.colors(
            at: [CGImage.PixelCoordinate(column: -1, row: 0)]))
        XCTAssertNotNil(shape0.cgImage!.colors(at: []))
    }

    func testOptionsPreservation() throws {
        // Every processing method returns an image that looks like its receiver: rendering mode, alignment insets,
        // configuration, baseline offset and scale are carried over. `drawnAbove` used to lose all of them, because
        // it was implemented by swapping the two images around `drawnUnder`, which made the argument the receiver.
        //
        // The color is deliberately an invariant one: a system color varies with the color traits, which makes the
        // output dynamic, and a dynamic image cannot carry a baseline offset. `TraitTests` covers that case.
        let invariantColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)

        for scale in [CGFloat(2), CGFloat(3)] {
            var source = UIImage(cgImage: shape0.cgImage!, scale: scale, orientation: .up)
                .withRenderingMode(.alwaysTemplate)
                .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
                .withBaselineOffset(fromBottom: 10)

            // Applying a configuration resolves it against the current trait environment, so round-trip the source
            // once to compare a resolved configuration with a resolved one.
            source = source.withConfiguration(source.configuration!)

            // The other image deliberately has a different scale, to catch an output rendered in its space.
            let other = UIImage(cgImage: shape1.cgImage!, scale: scale + 1, orientation: .up)

            let outputs: [(String, UIImage)] = [
                ("colorized", source.colorized(with: invariantColor)),
                ("expanded", source.expanded(bySize: 2, each: 90)),
                ("stroked", source.stroked(with: invariantColor, size: 2, each: 90)),
                ("smoothened(sizeKept:)", source.smoothened(by: 2, sizeKept: true)),
                ("smoothened", source.smoothened(by: 2, sizeKept: false)),
                ("withAlphaComponent", source.withAlphaComponent(0.5)),
                ("scaled(to:)", source.scaled(to: CGSize(width: 50, height: 50))),
                ("scaled(uniform:)", source.scaled(uniform: 0.5)),
                ("scaledWidth(to:)", source.scaledWidth(to: 50)),
                ("scaledHeight(to:)", source.scaledHeight(to: 50)),
                ("cropped", source.cropped(to: CGRect(origin: .zero, size: source.size / 2))),
                ("rotated", source.rotated(by: 30)),
                ("flippedHorizontally", source.flippedHorizontally()),
                ("flippedVertically", source.flippedVertically()),
                ("drawnUnder", source.drawnUnder(image: other)),
                ("drawnAbove", source.drawnAbove(image: other)),
                ("colorInverted", source.colorInverted()),
                ("alphaExclusion", source.alphaExclusion(with: other))
            ]

            for (name, output) in outputs {
                let message = "\(name) at scale \(scale)"
                XCTAssertEqual(output.scale, source.scale, message)
                XCTAssertEqual(output.renderingMode, source.renderingMode, message)
                XCTAssertEqual(output.alignmentRectInsets, source.alignmentRectInsets, message)
                XCTAssertEqual(output.baselineOffsetFromBottom, source.baselineOffsetFromBottom, message)
                XCTAssertEqual(output.configuration, source.configuration, message)
            }
        }
    }

    func testBitmapProcessing() throws {

        // Exclusion with the same image should result in full transparent image
        let density0 = shape0.alphaExclusion(with: shape0).opaquePixelDensity
        XCTAssertNotNil(density0)
        XCTAssertEqual(density0!, 0.0)

        // This image is a fully opaque
        let density1 = notSoBlueImage.opaquePixelDensity
        XCTAssertNotNil(density1)
        XCTAssertEqual(density1!, 1.0)

        // This image is a square taking quarter of the total size
        let density2 = gradientQuarterImage.opaquePixelDensity
        XCTAssertNotNil(density2)
        XCTAssertEqual(density2!, 0.25, accuracy: 0.001)

        // This is image is constructed with apparent colors in the corners
        let img = smallGradientImage.cgImage!
        let entries = [
            CGImage.PixelCoordinate.topLeft(in: img): "#FF0000",
            CGImage.PixelCoordinate.topRight(in: img): "#FFFF00",
            CGImage.PixelCoordinate.bottomLeft(in: img): "#FF00FF",
            CGImage.PixelCoordinate.bottomRight(in: img): "#FFFFFF"
        ]
        for entry in entries {
            let color = img.color(at: entry.key)
            XCTAssertNotNil(color)
            XCTAssertEqual(color!.hexCode, entry.value)
        }
    }

    func testTextRendering() throws {
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24)]

        XCTAssertNotNil(UIImage(text: "hello"))
        XCTAssertNotNil(UIImage(text: "hello", attributes: attributes))
        XCTAssertNotNil(UIImage(text: NSAttributedString(string: "hello", attributes: attributes)))

        // An explicit size wins over the size the text needs.
        let sized = UIImage(text: "hello", size: CGSize(width: 40, height: 20))
        XCTAssertEqual(sized?.size, CGSize(width: 40, height: 20))

        // Nothing to draw means no image, rather than an empty one.
        XCTAssertNil(UIImage(text: ""))
        XCTAssertNil(UIImage(text: "hello", size: .zero))
    }

    func testKernelLoading() throws {
        // The kernels ship as a package resource compiled by the CIKernelCompiler plugin. Loading
        // them used to be a fatalError, which is how the CocoaPods distribution came to crash
        // instead of degrading, so an unresolvable function must simply return nil.
        XCTAssertNil(KernelLoader.loadFunction(named: "thisFunctionDoesNotExist"))
        XCTAssertNotNil(KernelLoader.loadFunction(named: "colorize"))
        XCTAssertNotNil(KernelLoader.loadFunction(named: "exclude"))
    }

    func testColorized() throws {
        measure { _ = shape0.colorized(with: color0) }
    }

    func testExpand() throws {
        measure { _ = shape0.expanded(bySize: 20) }
    }

    func testStroked() throws {
        // UIColor.black belongs to a monochrome color space, it exercises the conversion done before colorizing.
        let color = UIColor.black
        measure { _ = shape0.stroked(with: color, size: 20) }
    }
}
