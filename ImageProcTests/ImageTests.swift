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

    var appBundle: Bundle!
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
        appBundle = Bundle(for: ImageTests.self)
        shape0 = UIImage(named: "splash-rounded-100", in: appBundle, with: nil)
        shape1 = UIImage(named: "splash-square-100", in: appBundle, with: nil)
        gradientQuarterImage = UIImage(named: "gradient-quarter-100", in: appBundle, with: nil)
        notSoBlueImage = UIImage(named: "not-so-blue-square-100", in: appBundle, with: nil)
        smallGradientImage = UIImage(named: "small-gradient-4", in: appBundle, with: nil)
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

    func testColorizedWithCiFilter() throws {
        // CIFilter colorization is the default unless UIImage.useMetalColorizationMethod() is called before.
        measure { _ = shape0.colorized(with: color0) }
    }

    func testColorizedWithMetal() throws {
        // Metal colorization is selected when UIImage.useMetalColorizationMethod() is called.
        UIImage.useMetalColorizationMethod()
        measure { _ = shape0.colorized(with: color0) }
    }

    func testExpand() throws {
        measure { _ = shape0.expanded(bySize: 20) }
    }

    func testStroked() throws {
        // Keep in mind that regarding of the previous test CIFilter or Metal colorization is called.
        let color = UIColor.black
        measure { _ = shape0.stroked(with: color, size: 20) }
    }
}
