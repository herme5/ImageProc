//
//  ColorTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 01/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import XCTest

final class ColorTests: XCTestCase {

    let validHexCodes = ["#000000", "#FFFFFF", "#123456", "#ABCDEF", "#abcDEF", "#abcdef", "#123ABC"]

    let invalidHexCodes = ["#12345", "#1234567", "123456", "#ABCDEG", "#HIJKLM", "#😮123A"]
    
    let equalityAccuracy = 0.000_000_001
    
    let iterationCount = 1_000
    
    func repeated(_ body: () -> Void) {
        for _ in 0 ..< iterationCount {
            body()
        }
    }
    
    func testInitializerSuccesses() throws {
        for validHexCode in validHexCodes {
            XCTAssertNotNil(UIColor(hexCode: validHexCode))
            XCTAssertNotNil(CGColor.from(hexCode: validHexCode))

            // Deprecated
            let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
            XCTAssertNotNil(deprecatedWrapper.uiColor(from: validHexCode, alpha: 1)
            )
        }
    }

    func testInitializerFailures() throws {
        for invalidHexCode in invalidHexCodes {
            XCTAssertNil(UIColor(hexCode: invalidHexCode))
            XCTAssertNil(CGColor.from(hexCode: invalidHexCode))

            // Deprecated
            let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
            let color = deprecatedWrapper.uiColor(from: invalidHexCode, alpha: 1)
            XCTAssertEqual(color.rgba.red, CGFloat(0))
            XCTAssertEqual(color.rgba.green, CGFloat(0))
            XCTAssertEqual(color.rgba.blue, CGFloat(0))
        }
    }

    func testGetters() throws {
        let blackRGBA = UIColor.black.rgba
        XCTAssertEqual(blackRGBA.red, CGFloat(0))
        XCTAssertEqual(blackRGBA.green, CGFloat(0))
        XCTAssertEqual(blackRGBA.blue, CGFloat(0))
        XCTAssertEqual(blackRGBA.alpha, CGFloat(1))

        let blackHSLA = UIColor.black.hsla
        XCTAssertEqual(blackHSLA.hue, CGFloat(0))
        XCTAssertEqual(blackHSLA.saturation, CGFloat(0))
        XCTAssertEqual(blackHSLA.brightness, CGFloat(0))
        XCTAssertEqual(blackHSLA.alpha, CGFloat(1))

        for validHexCode in validHexCodes {
            let hexCodeToCompare = validHexCode.uppercased()

            let uiColor = UIColor(hexCode: validHexCode)!
            XCTAssertEqual(uiColor.hexCode, hexCodeToCompare)

            let cgColor = CGColor.from(hexCode: validHexCode)!
            XCTAssertEqual(cgColor.hexCode, hexCodeToCompare)
        }
    }

    func testOperations() throws {
        let color = UIColor.random()
        measure {
            _ = color.moreOpaque()
            _ = color.lessOpaque()
            _ = color.lighter()
            _ = color.darker()
            _ = color.saturated()
            _ = color.brightened()
            _ = color.hueOffset()
        }
    }

    func testOperationBoundaries() throws {
        let color = UIColor.random()

        XCTAssertEqual(color.moreOpaque(by: 2.0).rgba.alpha, CGFloat(1))
        XCTAssertEqual(color.moreOpaque(by: -2.0).rgba.alpha, CGFloat(0))

        XCTAssertEqual(color.lessOpaque(by: 2.0).rgba.alpha, CGFloat(0))
        XCTAssertEqual(color.lessOpaque(by: -2.0).rgba.alpha, CGFloat(1))

        XCTAssertEqual(color.lighter(by: 2.0).rgba.red, CGFloat(1))
        XCTAssertEqual(color.lighter(by: 2.0).rgba.green, CGFloat(1))
        XCTAssertEqual(color.lighter(by: 2.0).rgba.blue, CGFloat(1))
        XCTAssertEqual(color.lighter(by: -2.0).rgba.red, CGFloat(0))
        XCTAssertEqual(color.lighter(by: -2.0).rgba.green, CGFloat(0))
        XCTAssertEqual(color.lighter(by: -2.0).rgba.blue, CGFloat(0))

        XCTAssertEqual(color.darker(by: 2.0).rgba.red, CGFloat(0))
        XCTAssertEqual(color.darker(by: 2.0).rgba.green, CGFloat(0))
        XCTAssertEqual(color.darker(by: 2.0).rgba.blue, CGFloat(0))
        XCTAssertEqual(color.darker(by: -2.0).rgba.red, CGFloat(1))
        XCTAssertEqual(color.darker(by: -2.0).rgba.green, CGFloat(1))
        XCTAssertEqual(color.darker(by: -2.0).rgba.blue, CGFloat(1))

        XCTAssertEqual(color.saturated(by: 2.0).hsla.saturation, CGFloat(1))
        XCTAssertEqual(color.saturated(by: 2.0).hsla.saturation, CGFloat(1))
        XCTAssertEqual(color.saturated(by: 2.0).hsla.saturation, CGFloat(1))
        XCTAssertEqual(color.saturated(by: -2.0).hsla.saturation, CGFloat(0))
        XCTAssertEqual(color.saturated(by: -2.0).hsla.saturation, CGFloat(0))
        XCTAssertEqual(color.saturated(by: -2.0).hsla.saturation, CGFloat(0))

        XCTAssertEqual(color.brightened(by: 2.0).hsla.brightness, CGFloat(1))
        XCTAssertEqual(color.brightened(by: 2.0).hsla.brightness, CGFloat(1))
        XCTAssertEqual(color.brightened(by: 2.0).hsla.brightness, CGFloat(1))
        XCTAssertEqual(color.brightened(by: -2.0).hsla.brightness, CGFloat(0))
        XCTAssertEqual(color.brightened(by: -2.0).hsla.brightness, CGFloat(0))
        XCTAssertEqual(color.brightened(by: -2.0).hsla.brightness, CGFloat(0))

        let colorHue = color.hsla.hue
        XCTAssertEqual(color.hueOffset(by: 1.0).hsla.hue, colorHue, accuracy: equalityAccuracy)
        XCTAssertEqual(color.hueOffset(by: -1.0).hsla.hue, colorHue, accuracy: equalityAccuracy)
    }

    func testPerformanceFromValue() throws {
        measure {
            repeated {
                _ = UIColor.random()
            }
        }
    }

    func testPerformanceFromHexCode() throws {
        let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
        measure {
            repeated {
                _ = deprecatedWrapper.uiColorRandomFromCode()
            }
        }
    }
}

// MARK: - DeprecatedWrapper
// Workaround to silence deprecated warnings, but still interesting to test:
// https://stackoverflow.com/questions/31540446/how-to-silence-a-warning-in-swift

class DeprecatedWrapper {

    @available(iOS, deprecated: 1.0)
    static func uiColor(from hexcode: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(from: hexcode, alpha: alpha)
    }

    @available(iOS, deprecated: 1.0)
    static func uiColorRandomFromCode() -> UIColor {
        return UIColor.randomFromCode()
    }
}

private protocol Silenced {

    static func uiColor(from hexcode: String, alpha: CGFloat) -> UIColor

    static func uiColorRandomFromCode() -> UIColor
}

extension DeprecatedWrapper: Silenced { }
