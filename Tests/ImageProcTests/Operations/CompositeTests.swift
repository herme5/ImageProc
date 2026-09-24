//
//  CompositeTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

@Suite("Combining images")
struct CompositeTests {

    static let small = Fixture.solid(.red, size: CGSize(width: 8, height: 8))
    static let large = Fixture.solid(.blue, size: CGSize(width: 16, height: 16))
    static let corner = CGPoint(x: 0.05, y: 0.05)

    @Test("drawing above keeps the receiver on top, centered")
    func drawingAboveKeepsTheReceiverOnTopCentered() throws {
        let output = try #require(Bitmap(Self.small.drawnAbove(image: Self.large)))
        #expect(output[relative: Bitmap.center] == Pixel(.red))
        #expect(output[relative: Self.corner] == Pixel(.blue))
    }

    @Test("drawing under puts the other image on top, centered")
    func drawingUnderPutsTheOtherImageOnTopCentered() throws {
        let output = try #require(Bitmap(Self.large.drawnUnder(image: Self.small)))
        #expect(output[relative: Bitmap.center] == Pixel(.red))
        #expect(output[relative: Self.corner] == Pixel(.blue))
    }

    @Test("a composite spans both images")
    func aCompositeSpansBothImages() {
        let wide = Fixture.solid(.red, size: CGSize(width: 16, height: 8))
        let tall = Fixture.solid(.blue, size: CGSize(width: 8, height: 16))
        #expect(wide.drawnAbove(image: tall).size == CGSize(width: 16, height: 16))
        #expect(wide.drawnUnder(image: tall).size == CGSize(width: 16, height: 16))
        #expect(wide.alphaExclusion(with: tall).size == CGSize(width: 16, height: 16))
    }

    /// Two overlapping bands in the top half of a 16 point canvas: the first covers x 0...10, the second 6...16.
    @Test("alpha exclusion keeps what exactly one image covers")
    func alphaExclusionKeepsWhatExactlyOneImageCovers() throws {
        let band: (CGFloat) -> UIImage = { originX in
            Fixture.render(size: CGSize(width: 16, height: 16)) { context in
                context.setFillColor(UIColor.red.cgColor)
                context.fill(CGRect(x: originX, y: 0, width: 10, height: 8))
            }
        }
        let output = try #require(Bitmap(band(0).alphaExclusion(with: band(6))))

        #expect(output[relative: CGPoint(x: 3.0 / 16, y: 0.25)].alpha == 255, "only the first")
        #expect(output[relative: CGPoint(x: 8.0 / 16, y: 0.25)].alpha == 0, "both")
        #expect(output[relative: CGPoint(x: 13.0 / 16, y: 0.25)].alpha == 255, "only the second")
        #expect(output[relative: CGPoint(x: 8.0 / 16, y: 0.75)].alpha == 0, "neither")
    }

    @Test("alpha exclusion of an image with itself is empty")
    func alphaExclusionOfAnImageWithItselfIsEmpty() {
        let shape = Fixture.catalog(.splashRounded)
        #expect(shape.alphaExclusion(with: shape).opaquePixelDensity == 0)
    }
}
