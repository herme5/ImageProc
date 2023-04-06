//
//  CGColorExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreGraphics

// MARK: - CGColor extension

public extension CGColor {

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

    /// Initializes a color object represented by the specified hexadecimal color code in string. If the string is not
    /// well formatted a full opaque black color is returned.
    ///
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    static func from(hexCode: String, alpha: CGFloat = 1.0) -> CGColor? {
        guard hexCode.count == 7 && hexCode[0] == "#" else {
            return nil
        }

        guard let value = HexadecimalHelper.valueFrom(string: hexCode[1..<7]) else {
            return nil
        }
        return CGColor.from(value: value, alpha: alpha)
    }

    /// The hexadecimal color code as a string prefixed with a `#` and representing the RGB components.
    var hexCode: String {
        let rgbaColor = converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)!
        let hexRed   = HexadecimalHelper.stringFrom(value: UInt(rgbaColor.components![0] * 255), digitCount: 2)
        let hexGreen = HexadecimalHelper.stringFrom(value: UInt(rgbaColor.components![1] * 255), digitCount: 2)
        let hexBlue  = HexadecimalHelper.stringFrom(value: UInt(rgbaColor.components![2] * 255), digitCount: 2)
        return "#\(hexRed)\(hexGreen)\(hexBlue)"
    }
}
