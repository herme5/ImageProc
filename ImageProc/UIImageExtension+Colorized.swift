//
//  UIImageExtension+Colorized.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

internal extension UIImage {

    /// Builds the filter that throws away existing colors and fills the non transparent pixels with the input color.
    ///
    /// The color must belong to an RGB color space, pass it through `_rgbCompliant(_:)` beforehand.
    static func _colorizedFilter(color: UIColor, cgImage: CGImage) -> CIFilter {
        // Use a custom CIFilter based on a Metal routine
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage)
        colorFilter.inputColor = CIColor(color: color)
        return colorFilter
    }

    /// Returns a color that is guaranteed to belong to an RGB color space, converting it when needed.
    ///
    /// `ColorFilter` requires an RGBA compliant color, and system colors such as `UIColor.black` belong to a
    /// monochrome color space.
    static func _rgbCompliant(_ color: UIColor) -> UIColor {
        if let colorSpace = color.cgColor.colorSpace, colorSpace.model == .rgb {
            return color
        }
        guard let converted = color.cgColor.converted(to: CGColor.defaultRGBColorSpace,
                                                      intent: .defaultIntent,
                                                      options: nil) else {
            return color
        }
        return UIColor(cgColor: converted)
    }
}
