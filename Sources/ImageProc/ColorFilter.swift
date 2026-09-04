//
//  ColorFilter.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreImage

/// An image processor that produces a monochromatic image.
///
/// The ColorFilter class produces a CIImage object as output. The filter takes an image and a color as input.
/// The input color has to be RGBA compliant; `UIImage._colorizedFilter(color:cgImage:)` sees to that.
///
/// Note that the input color alpha component is taken into account to produce a more transparent (and always more
/// transparent) image.
internal class ColorFilter: CIFilter {

    /// The original input image as a `CIImage`.
    var inputImage: CIImage?

    /// The input color as a `CIColor`.
    var inputColor: CIColor?

    /// The Metal function name.
    private static let functionName = "colorize"

    /// The Metal kernel, or `nil` when the compiled library could not be loaded.
    private static let kernel: CIColorKernel? = {
        return KernelLoader.loadFunction(named: functionName)
    }()

    /// The resulting image, or `nil` when the kernel is unavailable.
    override var outputImage: CIImage? {
        guard let kernel = ColorFilter.kernel, let inputImage, let inputColor else {
            return nil
        }
        let inputs = [inputImage, inputColor] as [Any]
        return kernel.apply(extent: inputImage.extent, arguments: inputs)
    }
}
