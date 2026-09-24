//
//  UIColorTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 01/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

@Suite("UIColor hexadecimal codes")
struct HexCodeTests {

    static let valid = ["#000000", "#FFFFFF", "#123456", "#ABCDEF", "#abcDEF", "#abcdef", "#123ABC"]
    static let invalid = ["#12345", "#1234567", "123456", "#ABCDEG", "#HIJKLM", "#😮123A"]

    @Test("a valid code creates a color carrying that code", arguments: valid)
    func aValidCodeCreatesAColorCarryingThatCode(_ code: String) throws {
        let color = try #require(UIColor(hexCode: code))
        #expect(color.hexCode == code.uppercased())
        #expect(CGColor.from(hexCode: code)?.hexCode == code.uppercased())
    }

    @Test("an invalid code creates no color", arguments: invalid)
    func anInvalidCodeCreatesNoColor(_ code: String) {
        #expect(UIColor(hexCode: code) == nil)
        #expect(CGColor.from(hexCode: code) == nil)
    }

    @Test("a value creates the color it spells")
    func aValueCreatesTheColorItSpells() {
        #expect(UIColor(value: 0x08AF76).hexCode == "#08AF76")
        #expect(UIColor(value: 0x08AF76, alpha: 0.5).rgba.alpha == 0.5)
    }

    @Test("a monochrome color reports its RGB code")
    func aMonochromeColorReportsItsRGBCode() {
        #expect(UIColor.white.cgColor.hexCode == "#FFFFFF")
        #expect(UIColor.black.hexCode == "#000000")
    }
}

@Suite("UIColor components")
struct ComponentTests {

    @Test("black has zero RGB components and full alpha")
    func blackHasZeroRGBComponentsAndFullAlpha() {
        let rgba = UIColor.black.rgba
        #expect(rgba.red == 0 && rgba.green == 0 && rgba.blue == 0 && rgba.alpha == 1)

        let hsla = UIColor.black.hsla
        #expect(hsla.brightness == 0 && hsla.alpha == 1)
    }

    @Test("both representations report the same alpha")
    func bothRepresentationsReportTheSameAlpha() {
        let color = UIColor.random().withAlphaComponent(0.5)
        #expect(color.rgba.alpha == color.hsla.alpha)
    }

    @Test("a random color is opaque")
    func aRandomColorIsOpaque() {
        #expect(UIColor.random().rgba.alpha == 1)
    }
}

@Suite("UIColor adjustments")
struct ColorAdjustmentTests {

    /// An adjustment and the opposite one, which have to cancel out.
    struct RoundTrip: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let adjust: @Sendable (UIColor) -> UIColor
    }

    // Components are deliberately kept away from a half 8-bit step: `hexCode` rounds to the nearest byte, so a
    // component landing exactly on `x.5 / 255` flips between two codes for a one ulp difference, which an operation
    // followed by its inverse is free to introduce.
    static let roundTrips = [
        RoundTrip(testDescription: "lighter then darker") { $0.lighter().darker() },
        RoundTrip(testDescription: "saturated both ways") { $0.saturated(by: 0.2).saturated(by: -0.2) },
        RoundTrip(testDescription: "brightened both ways") { $0.brightened(by: 0.2).brightened(by: -0.2) },
        RoundTrip(testDescription: "hue offset both ways") { $0.hueOffset(by: 0.2).hueOffset(by: -0.2) }
    ]

    @Test("an adjustment followed by its opposite gives the color back", arguments: roundTrips)
    func anAdjustmentFollowedByItsOppositeGivesTheColorBack(_ roundTrip: RoundTrip) {
        let color = UIColor(hue: 0.3, saturation: 0.6, brightness: 0.6, alpha: 1)
        #expect(roundTrip.adjust(color).hexCode == color.hexCode)
    }

    @Test("opacity adjustments cancel out")
    func opacityAdjustmentsCancelOut() {
        let color = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.5)
        #expect(color.moreOpaque().lessOpaque().rgba.alpha == color.rgba.alpha)
    }

    @Test("adjustments clamp to the valid range")
    func adjustmentsClampToTheValidRange() {
        let color = UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.6)

        #expect(color.moreOpaque(by: 2).rgba.alpha == 1)
        #expect(color.moreOpaque(by: -2).rgba.alpha == 0)
        #expect(color.lessOpaque(by: 2).rgba.alpha == 0)
        #expect(color.lessOpaque(by: -2).rgba.alpha == 1)

        let white = color.lighter(by: 2).rgba, black = color.lighter(by: -2).rgba
        #expect(white.red == 1 && white.green == 1 && white.blue == 1)
        #expect(black.red == 0 && black.green == 0 && black.blue == 0)
        #expect(color.darker(by: 2).rgba.red == 0)
        #expect(color.darker(by: -2).rgba.red == 1)

        #expect(color.saturated(by: 2).hsla.saturation == 1)
        #expect(color.saturated(by: -2).hsla.saturation == 0)
        #expect(color.brightened(by: 2).hsla.brightness == 1)
        #expect(color.brightened(by: -2).hsla.brightness == 0)
    }

    @Test("a hue offset wraps around the circle")
    func aHueOffsetWrapsAroundTheCircle() {
        let color = UIColor(hue: 0.3, saturation: 0.6, brightness: 0.6, alpha: 1)
        #expect(abs(color.hueOffset(by: 1).hsla.hue - 0.3) < 1e-6)
        #expect(abs(color.hueOffset(by: -1).hsla.hue - 0.3) < 1e-6)
        #expect(abs(color.hueOffset(by: 0.5).hsla.hue - 0.8) < 1e-6)
    }
}
