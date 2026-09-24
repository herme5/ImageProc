//
//  OutlineTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Outlines on `Fixture.centeredSquare`: an 8 point square in the middle of a 16 point canvas, so from 4 to 12.
@Suite("Outline and blur")
struct OutlineTests {

    /// Expanded or stroked by 2, the canvas becomes 20 points and the square moves to 6...14. This point sits
    /// 1 point left of it, in the band the expansion grows into.
    static let grownBand = CGPoint(x: 5.0 / 20, y: 0.5)
    static let corner = CGPoint(x: 0.02, y: 0.02)

    @Test("expanding grows the canvas by twice the size")
    func expandingGrowsTheCanvasByTwiceTheSize() {
        #expect(Fixture.centeredSquare().expanded(bySize: 2).size == CGSize(width: 20, height: 20))
    }

    @Test("expanding grows the silhouette in its own color")
    func expandingGrowsTheSilhouetteInItsOwnColor() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).expanded(bySize: 2)))
        #expect(output[relative: Self.grownBand].distance(to: Pixel(.red)) <= Tolerance.rounding)
        #expect(output[relative: Self.corner].alpha == 0)
    }

    @Test("stroking paints the grown band and keeps the interior")
    func strokingPaintsTheGrownBandAndKeepsTheInterior() throws {
        let stroked = Fixture.centeredSquare(.red).stroked(with: .blue, size: 2)
        #expect(stroked.size == CGSize(width: 20, height: 20))

        let output = try #require(Bitmap(stroked))
        #expect(output[relative: Self.grownBand].distance(to: Pixel(.blue)) <= Tolerance.rounding)
        #expect(output[relative: Bitmap.center].distance(to: Pixel(.red)) <= Tolerance.rounding)
    }

    @Test("a stroke's alpha sets the border opacity")
    func aStrokesAlphaSetsTheBorderOpacity() throws {
        let output = try #require(Bitmap(Fixture.centeredSquare(.red).stroked(with: .blue, size: 2, alpha: 0.5)))
        #expect(abs(Int(output[relative: Self.grownBand].alpha) - 128) <= Tolerance.rounding)
    }

    @Test("smoothening grows the canvas so the blur is not clipped")
    func smootheningGrowsTheCanvasSoTheBlurIsNotClipped() {
        let source = Fixture.centeredSquare()
        let output = source.smoothened(by: 2)
        #expect(output.size.width > source.size.width)
        #expect(output.size.height > source.size.height)
    }

    @Test("smoothening can keep the size")
    func smootheningCanKeepTheSize() {
        let source = Fixture.centeredSquare()
        #expect(source.smoothened(by: 2, sizeKept: true).size == source.size)
    }

    @Test("smoothening softens a hard edge")
    func smootheningSoftensAHardEdge() throws {
        // Right on the square's left edge, where the source goes straight from transparent to opaque.
        let edge = CGPoint(x: 4.0 / 16, y: 0.5)
        let output = try #require(Bitmap(Fixture.centeredSquare().smoothened(by: 2, sizeKept: true)))
        let alpha = output[relative: edge].alpha
        #expect(alpha > 20 && alpha < 235, "alpha \(alpha) is not a blend")
    }
}
