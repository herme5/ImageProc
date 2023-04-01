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
    
    let iterationCount = Int(pow(10.0, 6))
    
    let equalityAccuracy = CGFloat(pow(10.0, -9))
    
    
    func testInitializerSuccesses() throws {
        for validHexCode in validHexCodes {
            XCTAssertNotNil(UIColor(hexCode: validHexCode))
            
            // Deprecated
            let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
            XCTAssertNotNil(deprecatedWrapper.uiColor(from: validHexCode, alpha: 1)
            )
        }
    }
    
    func testInitializerFailures() throws {
        for invalidHexCode in invalidHexCodes {
            XCTAssertNil(UIColor(hexCode: invalidHexCode))
            
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
            let color = UIColor(hexCode: validHexCode)
            XCTAssertEqual(color!.hexCode, validHexCode.uppercased())
        }
    }
    
    func testOperations() throws {
        let color = UIColor.random()
        measure {
            _ = color.moreOpaque()
            _ = color.lessOpaque()
            _ = color.lighter()
            _ = color.darker()
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
            for _ in 0 ..< iterationCount {
                let _ = UIColor.random()
            }
        }
    }
    
    func testPerformanceFromHexCode() throws {
        let deprecatedWrapper = DeprecatedWrapper.self as Silenced.Type
        measure {
            for _ in 0 ..< iterationCount {
                let _ = deprecatedWrapper.uiColorRandomFromCode()
            }
        }
    }
}


// MARK: - Workaround to silence deprecated method warnings, but still interesting to test:
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
