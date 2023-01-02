//
//  ImageUtils.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//
import UIKit

// MARK: - HexadecimalConverter

fileprivate class Hexadecimal {
    
    /// The decimal to hexadecimal digits mapping table.
    static let digits: [Character:UInt] = ["0":0, "1":1, "2":2, "3":3, "4":4, "5":5, "6":6, "7":7, "8":8, "9":9, "A":10, "B":11, "C":12, "D":13, "E":14, "F":15]
    
    /// Initializer is unavailable, this class contains only static members.
    private init() { }
    
    /// Converts an hexadecimal string to integer value. The input string can be either uppercase or lowercase, but must not contain whitespace or any character that is not an hexadecimal digit. All unrecognized characters will result in the function returning 0.
    static func valueFrom(string: String) -> UInt {
        var value: UInt = 0
        for (index,char) in string.uppercased().reversed().enumerated() {
            guard let digit = digits[char] else {
                return 0
            }
            // pow(16, index)
            let weight = UInt(1) << (4 * index)
            value += digit * weight
        }
        return value
    }
    
    /// Converts an hexadecimal value to a string. The leading zeros and the case can be specified.
    ///
    /// - parameters:
    ///   - value: the integer value,
    static func stringFrom(value: UInt, digitCount: UInt? = nil, uppercased: Bool = true) -> String {
        return String(format: "%\(digitCount == nil ? "" : "0\(digitCount!)")\(uppercased ? "X" : "x")", value)
    }
}

public extension UIColor {
    
    /// The RGBA components as a tuple associated to the color object.
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    /// The HSLA components as a tuple associated to the color object.
    var hsla: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue:        CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha:      CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }
    
    /// The hexadecimal color code as a string prefixed with a `#` and representing the RGB components.
    var hexCode: String {
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hexRed   = Hexadecimal.stringFrom(value: UInt(red   * 255), digitCount: 2)
        let hexGreen = Hexadecimal.stringFrom(value: UInt(green * 255), digitCount: 2)
        let hexBlue  = Hexadecimal.stringFrom(value: UInt(blue  * 255), digitCount: 2)
        return "#\(hexRed)\(hexGreen)\(hexBlue)"
    }
    
    /// Initializes a color object using the specified opacity and hexadecimal RGB value.
    ///
    /// - parameters:
    ///   - hex: The hexadecimal value of the RGB components specified between `0` (0x000000) and `UInt.max` (0xFFFFFF).
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    convenience init(value hex: UInt, alpha: CGFloat = 1.0) {
        self.init(red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hex >> 8)  & 0xFF) / 255.0,
                  blue:  CGFloat( hex        & 0xFF) / 255.0,
                  alpha: alpha)
    }
    
    /// Initializes a color object represented by the specified hexadecimal color code in string. If the string is not well formatted a full opaque black color is returned.
    ///
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    convenience init(from hexCode: String, alpha: CGFloat = 1.0) {
        guard hexCode.count == 7 && hexCode[0] == "#" else {
            self.init(value: 0)
            return
        }
        
        let value = Hexadecimal.valueFrom(string: hexCode[1..<7])
        self.init(value: value, alpha: alpha)
    }
    
    /// Returns a color object that has an alpha value added to the specified value.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be more opaque, otherwise it will be more transparent.
    func moreOpaque(by value: CGFloat = 0.25) -> UIColor {
        var alpha = self.rgba.alpha + value
        alpha = (alpha > 1.0) ? 1.0 : ((alpha < 0.0) ? 0.0 : alpha)
        return self.withAlphaComponent(alpha)
    }
    
    /// Returns a color object that has an alpha value subtracted by the specified value.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be more transparent, otherwise it will be more opaque.
    func lessOpaque(by value: CGFloat = 0.25) -> UIColor {
        return moreOpaque(by: -value)
    }
    
    /// Returns a lighter or darker color by adding `value` to the three RGB components. In the HSL color space the hue is kept.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be lighter, otherwise it will be darker.
    func lighter(by value: CGFloat = 0.15) -> UIColor {
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        red   += value; red   = (red   > 1.0) ? 1.0 : ((red   < 0.0) ? 0.0 : red)
        green += value; green = (green > 1.0) ? 1.0 : ((green < 0.0) ? 0.0 : green)
        blue  += value; blue  = (blue  > 1.0) ? 1.0 : ((blue  < 0.0) ? 0.0 : blue)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Returns a darker or lighter color by substracting `value` to the three RGB components. In the HSL color space the hue is kept.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be darker, otherwise it will be lighter.
    func darker(by value: CGFloat = 0.15) -> UIColor {
        return lighter(by: -value)
    }
    
    /// Returns a color object by adding `value` to the saturation component in the HSL color space.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be more saturated, otherwise it will be closer to a grey level color.
    func saturated(by value: CGFloat = 0.15) -> UIColor {
        var hue:        CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha:      CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        saturation += value
        saturation = (saturation > 1.0) ? 1.0 : ((saturation < 0.0) ? 0.0 : saturation)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    /// Returns a color object by adding `value` to the brightness component in the HSL color space.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be brighter, otherwise it will be darker.
    func brightened(by value: CGFloat = 0.15) -> UIColor {
        var hue:        CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha:      CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness += value
        brightness = (brightness > 1.0) ? 1.0 : ((brightness < 0.0) ? 0.0 : brightness)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    /// Returns a color object by offsetting the hue component in the HSL color space. The brightness and saturation stay the same.
    ///
    /// - parameters:
    ///   - value: The hue is offset by the value, and the modulo to 1.0 is considered.
    func hueOffset(by value: CGFloat = 0.15) -> UIColor {
        var hue:        CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha:      CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        hue = fmod(hue + value, 1.0)
        hue += hue < 0.0 ? 1.0 : 0.0
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

extension CGColor {
    
    /// Initializes a color object using the specified opacity and hexadecimal RGB value.
    ///
    /// - parameters:
    ///   - hex: The hexadecimal value of the RGB components specified between `0` (0x000000) and `UInt.max` (0xFFFFFF).
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    private static func from(value hex: UInt, alpha: CGFloat = 1.0) -> CGColor {
        let rgbaComponents = [CGFloat((hex >> 16) & 0xFF) / 255.0,
                              CGFloat((hex >> 8)  & 0xFF) / 255.0,
                              CGFloat( hex        & 0xFF) / 255.0,
                              alpha]
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: rgbaComponents)!
    }
    
    /// Initializes a color object represented by the specified hexadecimal color code in string. If the string is not well formatted a full opaque black color is returned.
    ///
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    static func from(hexCode: String, alpha: CGFloat = 1.0) -> CGColor {
        guard hexCode.count == 7 && hexCode[0] == "#" else {
            return CGColor.from(value: 0)
        }
        
        let value = Hexadecimal.valueFrom(string: hexCode[1..<7])
        return CGColor.from(value: value, alpha: alpha)
    }
    
    /// The hexadecimal color code as a string prefixed with a `#` and representing the RGB components.
    var hexCode: String {
        get {
            let rgbaColor = self.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)!
            let hexRed   = Hexadecimal.stringFrom(value: UInt(rgbaColor.components![0] * 255), digitCount: 2)
            let hexGreen = Hexadecimal.stringFrom(value: UInt(rgbaColor.components![1] * 255), digitCount: 2)
            let hexBlue  = Hexadecimal.stringFrom(value: UInt(rgbaColor.components![2] * 255), digitCount: 2)
            return "#\(hexRed)\(hexGreen)\(hexBlue)"
        }
    }
}

