//
//  ColorOperationTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

@Suite("Color operations")
struct ColorOperationTests {

    static let corner = CGPoint(x: 0.05, y: 0.05)

    @Test("colorizing paints the opaque pixels and leaves the transparent ones")
    func colorizingPaintsTheOpaquePixelsAndLeavesTheTransparentOnes() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).colorized(with: .blue)))
        #expect(output[relative: Bitmap.center].distance(to: Pixel(.blue)) <= Tolerance.rounding)
        #expect(output[relative: Self.corner] == .clear)
    }

    @Test("colorizing keeps the source's alpha")
    func colorizingKeepsTheSourcesAlpha() throws {
        let source = Fixture.solid(UIColor.red.withAlphaComponent(0.5))
        let output = try #require(Bitmap(source.colorized(with: .green)))
        #expect(abs(Int(output[relative: Bitmap.center].alpha) - 128) <= Tolerance.rounding)
    }

    /// `UIColor.black` belongs to a monochrome color space, which the kernel cannot take as is.
    @Test("colorizing accepts a monochrome color")
    func colorizingAcceptsAMonochromeColor() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).colorized(with: .black)))
        #expect(output[relative: Bitmap.center].distance(to: Pixel(.black)) <= Tolerance.rounding)
    }

    @Test("inverting the colors inverts RGB and keeps alpha")
    func invertingTheColorsInvertsRGBAndKeepsAlpha() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).colorInverted()))
        #expect(output[relative: Bitmap.center].distance(to: Pixel(.cyan)) <= Tolerance.rounding)
        #expect(output[relative: Self.corner].alpha == 0)
    }

    @Test("the alpha component scales the opacity")
    func theAlphaComponentScalesTheOpacity() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).withAlphaComponent(0.5)))
        #expect(abs(Int(output[relative: Bitmap.center].alpha) - 128) <= Tolerance.rounding)
        #expect(output[relative: Self.corner].alpha == 0)
    }
}
