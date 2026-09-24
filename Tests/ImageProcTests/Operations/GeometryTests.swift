//
//  GeometryTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Geometry on `Fixture.blocks`: 32x16 points of 8 point blocks, red green blue yellow over magenta cyan white gray.
@Suite("Geometry")
struct GeometryTests {

    static let topLeft = CGPoint(x: 0.05, y: 0.05)
    static let topRight = CGPoint(x: 0.95, y: 0.05)
    static let bottomLeft = CGPoint(x: 0.05, y: 0.95)

    func pixel(_ image: UIImage, at point: CGPoint) throws -> Pixel {
        return try #require(Bitmap(image))[relative: point]
    }

    func expectColor(_ image: UIImage, at point: CGPoint, _ color: UIColor,
                     sourceLocation: SourceLocation = #_sourceLocation) throws {
        let found = try pixel(image, at: point)
        #expect(found.distance(to: Pixel(color)) <= Tolerance.rounding, "found \(found)",
                sourceLocation: sourceLocation)
    }

    // MARK: Scaling

    @Test("scaling to a size gives exactly that size")
    func scalingToASizeGivesExactlyThatSize() throws {
        let output = Fixture.blocks().scaled(to: CGSize(width: 10, height: 20))
        #expect(output.size == CGSize(width: 10, height: 20))
        try expectColor(output, at: Self.topLeft, .red)
    }

    @Test("scaling uniformly multiplies both sides")
    func scalingUniformlyMultipliesBothSides() {
        #expect(Fixture.blocks().scaled(uniform: 0.5).size == CGSize(width: 16, height: 8))
    }

    @Test("scaling the width follows the aspect ratio unless told otherwise")
    func scalingTheWidthFollowsTheAspectRatioUnlessToldOtherwise() {
        #expect(Fixture.blocks().scaledWidth(to: 16).size == CGSize(width: 16, height: 8))
        #expect(Fixture.blocks().scaledWidth(to: 16, keepAspectRatio: false).size == CGSize(width: 16, height: 16))
    }

    @Test("scaling the height follows the aspect ratio unless told otherwise")
    func scalingTheHeightFollowsTheAspectRatioUnlessToldOtherwise() {
        #expect(Fixture.blocks().scaledHeight(to: 8).size == CGSize(width: 16, height: 8))
        #expect(Fixture.blocks().scaledHeight(to: 8, keepAspectRatio: false).size == CGSize(width: 32, height: 8))
    }

    @Test("scaling keeps the scale factor")
    func scalingKeepsTheScaleFactor() {
        let source = Fixture.blocks(scale: 3)
        #expect(source.scaled(uniform: 0.5).scale == 3)
    }

    // MARK: Cropping

    @Test("cropping selects the requested region")
    func croppingSelectsTheRequestedRegion() throws {
        let output = Fixture.blocks().cropped(to: CGRect(x: 8, y: 8, width: 8, height: 8))
        #expect(output.size == CGSize(width: 8, height: 8))
        try expectColor(output, at: Bitmap.center, .cyan)
    }

    @Test("cropping past the edge keeps what overlaps")
    func croppingPastTheEdgeKeepsWhatOverlaps() {
        let output = Fixture.blocks().cropped(to: CGRect(x: 24, y: 8, width: 16, height: 16))
        #expect(output.size == CGSize(width: 8, height: 8))
    }

    @Test("cropping outside the image returns it unchanged")
    func croppingOutsideTheImageReturnsItUnchanged() {
        let source = Fixture.blocks()
        #expect(source.cropped(to: CGRect(x: 40, y: 40, width: 8, height: 8)) === source)
        #expect(source.cropped(to: .zero) === source)
    }

    // MARK: Rotating and flipping

    @Test("rotating a quarter turn swaps the size and turns clockwise")
    func rotatingAQuarterTurnSwapsTheSizeAndTurnsClockwise() throws {
        let output = Fixture.blocks().rotated(by: 90)
        // `cos(90°)` is not exactly zero, which used to give a right angle an extra transparent point per side.
        #expect(output.size == CGSize(width: 16, height: 32))
        // The left column, read from the bottom up, becomes the top row.
        try expectColor(output, at: Self.topLeft, .magenta)
        try expectColor(output, at: Self.topRight, .red)
    }

    @Test("a right angle adds no margin", arguments: [CGFloat(90), 180, 270, 360, -90, 450])
    func aRightAngleAddsNoMargin(_ degrees: CGFloat) {
        let quarterTurns = Int((degrees / 90).rounded())
        let expected = quarterTurns.isMultiple(of: 2) ? CGSize(width: 32, height: 16) : CGSize(width: 16, height: 32)
        #expect(Fixture.blocks().rotated(by: degrees).size == expected)
    }

    @Test("rotating by any angle grows the canvas to the rotated bounds")
    func rotatingByAnyAngleGrowsTheCanvasToTheRotatedBounds() {
        let output = Fixture.blocks().rotated(by: 30)
        let radians = CGFloat.pi / 6
        let width = 32 * cos(radians) + 16 * sin(radians)
        let height = 32 * sin(radians) + 16 * cos(radians)
        #expect(abs(output.size.width - width) <= 1.5, "width \(output.size.width), expected about \(width)")
        #expect(abs(output.size.height - height) <= 1.5, "height \(output.size.height), expected about \(height)")
    }

    @Test("a full turn gives the image back")
    func aFullTurnGivesTheImageBack() {
        let source = Fixture.blocks()
        #expect(mismatch(source.rotated(by: 360), source) == nil)
    }

    @Test("flipping horizontally mirrors left and right")
    func flippingHorizontallyMirrorsLeftAndRight() throws {
        let output = Fixture.blocks().flippedHorizontally()
        #expect(output.size == CGSize(width: 32, height: 16))
        try expectColor(output, at: Self.topLeft, .yellow)
        try expectColor(output, at: Self.topRight, .red)
    }

    @Test("flipping vertically mirrors top and bottom")
    func flippingVerticallyMirrorsTopAndBottom() throws {
        let output = Fixture.blocks().flippedVertically()
        try expectColor(output, at: Self.topLeft, .magenta)
        try expectColor(output, at: Self.bottomLeft, .red)
    }

    @Test("flipping twice gives the image back")
    func flippingTwiceGivesTheImageBack() {
        let source = Fixture.blocks()
        #expect(mismatch(source.flippedHorizontally().flippedHorizontally(), source) == nil)
        #expect(mismatch(source.flippedVertically().flippedVertically(), source) == nil)
    }
}
