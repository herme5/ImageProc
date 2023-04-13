//
//  ColorTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 01/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import XCTest

final class ColorTests: XCTestCase {

    let validHexCodes = [
        "#000000",
        "#FFFFFF",
        "#123456",
        "#ABCDEF",
        "#abcDEF",
        "#abcdef",
        "#123ABC"
    ]

    let invalidHexCodes = [
        "#12345",
        "#1234567",
        "123456",
        "#ABCDEG",
        "#HIJKLM",
        "#😮123A"
    ]

    let equalityAccuracy = 0.000_000_001

    let iterationCount = 10_000

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
        // XCTAssertEqual(blackHSLA.hue, CGFloat(0))
        // XCTAssertEqual(blackHSLA.saturation, CGFloat(0))
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
        var color = UIColor.random().withAlphaComponent(0.5)
        XCTAssertEqual(color.rgba.alpha, color.hsla.alpha)
        XCTAssertEqual(color.rgba.alpha, color.moreOpaque().lessOpaque().rgba.alpha)
        XCTAssertEqual(color.hsla.alpha, color.moreOpaque().lessOpaque().hsla.alpha)

        color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        XCTAssertEqual(color.hexCode, color.lighter().darker().hexCode)

        let hue = CGFloat.random(in: 0.0 ..< 1.0)
        color = UIColor(hue: hue, saturation: 0.5, brightness: 0.5, alpha: 1.0)
        XCTAssertEqual(color.hexCode, color.saturated(by: 0.2).saturated(by: -0.2).hexCode)
        XCTAssertEqual(color.hexCode, color.brightened(by: 0.2).brightened(by: -0.2).hexCode)
        XCTAssertEqual(color.hexCode, color.hueOffset(by: 0.2).hueOffset(by: -0.2).hexCode)
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
        XCTAssertEqual(color.brightened(by: 2.0).hsla.brightness, CGFloat(1))
        XCTAssertEqual(color.saturated(by: -2.0).hsla.saturation, CGFloat(0))
        XCTAssertEqual(color.brightened(by: -2.0).hsla.brightness, CGFloat(0))

        let colorHue = color.hsla.hue
        XCTAssertEqual(color.hueOffset(by: 1.0).hsla.hue, colorHue, accuracy: equalityAccuracy)
        XCTAssertEqual(color.hueOffset(by: -1.0).hsla.hue, colorHue, accuracy: equalityAccuracy)
        
        let cgColorWhite = UIColor.white.cgColor
        XCTAssertEqual(cgColorWhite.hexCode, "#FFFFFF")
    }

    func testInitializationPerformanceFromValue() throws {
        measure {
            repeated {
                _ = UIColor.random()
            }
        }
    }

    func testInitializationPerformanceFromHexCode() throws {
        let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
        measure {
            repeated {
                _ = deprecatedWrapper.uiColorRandomFromCode()
            }
        }
    }

    func testUIColorHexCodePerformance() throws {
        measure {
            repeated {
                let color = UIColor.random()
                _ = color.cgColor.hexCode
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
