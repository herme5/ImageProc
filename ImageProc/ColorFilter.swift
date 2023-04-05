//
//  ColorFilter.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreImage

// MARK: - ColorFilter implementation

/// An image processor that produces an monochromatic image.
///
/// The ColorFilter class produces a CIImage object as output. The filter takes an image and a color as input.
///
/// Unless you are sure to reject all the original colors, it is recommended to use a monochromatic shape image as input
/// to modify that one color footprint, (for example, giving a full opaque image will just result in a square colorized
/// with the color input).
///
/// Note that the input color alpha component is taken into account to produce a more transparent (and always more
/// transparent) image.
internal class ColorFilter: CIFilter {

    /// The original input image as a `CIImage`.
    var inputImage: CIImage?

    /// The input color as a `CIColor`.
    var inputColor: CIColor?

    /// The GPU-based routine that performs the colorizing algorithm.
    private static let kernel: CIColorKernel = {
        let kernelCode =
        """
        kernel vec4 colorize(__sample pixel, vec4 color) {
            pixel.rgb = pixel.a * color.rgb;
            return pixel;
        }
        """
        return CIColorKernel(source: kernelCode)!
    }()

    /// The output image produced by the original image colorized with the input color.
    override var outputImage: CIImage? {
        let inputs = [inputImage!, inputColor!] as [Any]
        return ColorFilter.kernel.apply(extent: inputImage!.extent, arguments: inputs)
    }
}
