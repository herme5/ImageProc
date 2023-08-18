//
//  UIColorExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit

public extension UIColor {

    private static let maximumHexValue = UInt(pow(16.0, 6))

    /// The RGBA components as a tuple associated to the color object.
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    /// The HSLA components as a tuple associated to the color object.
    var hsla: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }

    /// The hexadecimal color code as a string prefixed with a `#` and representing the RGB components.
    var hexCode: String {
        cgColor.hexCode
    }

    /// Initializes a color object using the specified opacity and hexadecimal RGB value.
    ///
    /// - parameters:
    ///   - hex: The hexadecimal value of the RGB components specified between `0` (0x000000) and `UInt.max` (0xFFFFFF).
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    convenience init(value hex: UInt, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(hex & 0xFF) / 255.0,
                  alpha: alpha)
    }

    /// Initializes a color object represented by the specified hexadecimal color code in string. Returns nil if the
    /// string is not well formatted.
    ///
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    convenience init?(hexCode: String, alpha: CGFloat = 1.0) {
        guard hexCode.count == 7 && hexCode[0] == "#" else {
            return nil
        }
        guard let value = HexadecimalHelper.valueFrom(string: hexCode[1..<7]) else {
            return nil
        }
        self.init(value: value, alpha: alpha)
    }

    /// Initializes a color object represented by the specified hexadecimal color code in string. If the string is not
    /// well formatted a full opaque black color is returned.
    ///
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    @available(*, deprecated, renamed: "init(hexCode:alpha:)")
    convenience init(from hexCode: String, alpha: CGFloat = 1.0) {
        if UIColor.init(hexCode: hexCode, alpha: alpha) != nil {
            self.init(hexCode: hexCode, alpha: alpha)!
        }
        self.init(value: 0)
    }

    /// Returns an opaque random color.
    static func random() -> UIColor {
        return UIColor(value: UInt.random(in: 0 ..< maximumHexValue))
    }

    /// Returns an opaque random color.
    @available(*, deprecated, renamed: "random()")
    static func randomFromCode() -> UIColor {
        return UIColor(hexCode: HexadecimalHelper.randomCode())!
    }

    /// Returns a color object that has an alpha value added to the specified value.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be more opaque, otherwise it will be more transparent.
    func moreOpaque(by value: CGFloat = 0.25) -> UIColor {
        var alpha = rgba.alpha + value
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

    /// Brings the color closer to white by adding `value` to the three RGB components. In the HSL color space the hue
    /// is kept.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be lighter, otherwise it will be darker.
    func lighter(by value: CGFloat = 0.15) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        red   += value; red   = (red   > 1.0) ? 1.0 : ((red   < 0.0) ? 0.0 : red)
        green += value; green = (green > 1.0) ? 1.0 : ((green < 0.0) ? 0.0 : green)
        blue  += value; blue  = (blue  > 1.0) ? 1.0 : ((blue  < 0.0) ? 0.0 : blue)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Returns a darker or lighter color by substracting `value` to the three RGB components. In the HSL color space
    /// the hue is kept.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be darker, otherwise it will be lighter.
    func darker(by value: CGFloat = 0.15) -> UIColor {
        return lighter(by: -value)
    }

    /// Returns a color object by adding `value` to the saturation component in the HSL color space.
    ///
    /// - parameters:
    ///   - value: If value is positive the returned color will be more saturated, otherwise it will be closer to a grey
    ///            level color.
    func saturated(by value: CGFloat = 0.15) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
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
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness += value
        brightness = (brightness > 1.0) ? 1.0 : ((brightness < 0.0) ? 0.0 : brightness)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    /// Returns a color object by offsetting the hue component in the HSL color space. The brightness and saturation
    /// stay the same.
    ///
    /// - parameters:
    ///   - value: The hue is offset by the value, and the modulo to 1.0 is considered.
    func hueOffset(by value: CGFloat = 0.15) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        hue = fmod(hue + value, 1.0)
        hue += hue < 0.0 ? 1.0 : 0.0
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}
