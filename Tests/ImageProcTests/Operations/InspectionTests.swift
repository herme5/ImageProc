//
//  InspectionTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

@Suite("Inspecting an image")
struct InspectionTests {

    @Test("the size in pixels is the size times the scale")
    func theSizeInPixelsIsTheSizeTimesTheScale() {
        #expect(Fixture.blocks(scale: 3).sizeInPixel == CGSize(width: 64, height: 32))
        #expect(Fixture.solid(.red, size: CGSize(width: 8, height: 4), scale: 3).sizeInPixel
                == CGSize(width: 24, height: 12))
    }

    @Test("an opaque image has a density of one")
    func anOpaqueImageHasADensityOfOne() {
        #expect(Fixture.catalog(.notSoBlue).opaquePixelDensity == 1)
    }

    @Test("the density is the share of the canvas that is opaque")
    func theDensityIsTheShareOfTheCanvasThatIsOpaque() throws {
        let density = try #require(Fixture.catalog(.gradientQuarter).opaquePixelDensity)
        #expect(abs(density - 0.25) < 0.001)
    }

    @Test("a translucent pixel counts for its opacity")
    func aTranslucentPixelCountsForItsOpacity() throws {
        let density = try #require(Fixture.solid(UIColor.red.withAlphaComponent(0.5)).opaquePixelDensity)
        #expect(abs(density - 0.5) < 0.01)
    }

    @Test("the corner pixels read back as drawn")
    func theCornerPixelsReadBackAsDrawn() throws {
        let image = try #require(Fixture.catalog(.smallGradient).cgImage)
        #expect(image.color(at: .topLeft(in: image))?.hexCode == "#FF0000")
        #expect(image.color(at: .topRight(in: image))?.hexCode == "#FFFF00")
        #expect(image.color(at: .bottomLeft(in: image))?.hexCode == "#FF00FF")
        #expect(image.color(at: .bottomRight(in: image))?.hexCode == "#FFFFFF")
    }

    @Test("reading a coordinate outside the image gives no color")
    func readingACoordinateOutsideTheImageGivesNoColor() throws {
        let image = try #require(Fixture.blocks().cgImage)
        let colors = image.colors(at: [CGImage.PixelCoordinate(column: -1, row: 0), .topLeft(in: image)])
        #expect(colors.count == 2)
        #expect(colors[0] == nil)
        #expect(colors[1]?.hexCode == "#FF0000")
        #expect(image.colors(at: []).isEmpty)
    }

    @Test("the bitmap lists one color per pixel")
    func theBitmapListsOneColorPerPixel() throws {
        let image = Fixture.solid(.red, size: CGSize(width: 4, height: 2), scale: 1)
        let colors = try #require(image.withBitmapAsUIColorArray { $0 })
        #expect(colors.count == 8)
        #expect(colors.allSatisfy { $0.hexCode == "#FF0000" })
    }
}
