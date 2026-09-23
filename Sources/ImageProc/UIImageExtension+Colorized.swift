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

    /// The message printed when the input color cannot be expressed as a `CIColor`.
    ///
    /// Nothing is known to reach it, but `colorized(with:)` and `stroked(...)` then return the source image
    /// unchanged, and a silent no-op is a poor way to learn that a color space is not accepted.
    private static let _colorConversionErrorMessage =
        "Could not build a CIColor for the input color. `colorized(with:)` and `stroked(...)` return the source " +
        "image unchanged. Please report the color and the platform, this is not supposed to happen."

    /// Builds the filter that throws away existing colors and fills the non transparent pixels with the input color.
    ///
    /// The color is made RGB compliant here rather than by the callers, so that it cannot be forgotten.
    static func _colorizedFilter(color: UIColor, cgImage: CGImage) -> CIFilter {
        // Use a custom CIFilter based on a Metal routine
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage)
        colorFilter.inputColor = _colorizedInputColor(color)
        if colorFilter.inputColor == nil {
            print(_colorConversionErrorMessage)
        }
        return colorFilter
    }

    /// Colorizes a recipe rather than a buffer, for the chain, which has no `CGImage` to hand over between steps.
    ///
    /// - returns: The colorized recipe, or `nil` when the kernel or the color is unusable, which leaves the chain
    ///            with the image it already had.
    static func _colorized(_ input: CIImage, with color: UIColor) -> CIImage? {
        let colorFilter = ColorFilter()
        colorFilter.inputImage = input
        colorFilter.inputColor = _colorizedInputColor(color)
        if colorFilter.inputColor == nil {
            print(_colorConversionErrorMessage)
        }
        return colorFilter.outputImage
    }

    /// The input color the kernel takes, in the working color space.
    ///
    /// Not `CIColor(color:)`: it is annotated non-optional on iOS, but is an Objective-C initializer, and under
    /// "My Mac (Designed for iPad)" it did return nil for `UIColor.black` — the nil landing silently in the
    /// optional property, where the filter used to force unwrap it. Which colors it rejects there was never
    /// pinned down; naming the components and the color space removes the question instead.
    private static func _colorizedInputColor(_ color: UIColor) -> CIColor? {
        let rgba = _rgbCompliant(color).rgba
        return CIColor(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha,
                       colorSpace: CGColor.defaultRGBColorSpace)
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
