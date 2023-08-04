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
///
/// Previous shader implementation
/// ```
/// kernel vec4
/// colorize(__sample p, vec4 c) {
///   p.rgb = p.a * c.rgb;
///   p.a *= c.a;
///   return p;
/// }
/// ```
internal class ColorFilter: CIFilter {

    /// The original input image as a `CIImage`.
    var inputImage: CIImage?

    /// The input color as a `CIColor`.
    var inputColor: CIColor?

    /// The GPU-based routine that performs the colorizing algorithm.
    private static let kernel: CIColorKernel = {
        guard let bundle = Bundle(
            identifier: "com.andrearuffino.ImageProc") else {
            fatalError("Could not find the framework bundle")
        }
        guard let url = bundle.url(
          forResource: "ColorFilterKernel.ci",
          withExtension: "metallib"),
          let data = try? Data(contentsOf: url) else {
          fatalError("Unable to load metallib")
        }
        guard let kernel = try? CIColorKernel(
          functionName: "colorFilterKernel",
          fromMetalLibraryData: data) else {
          fatalError("Unable to create color kernel")
        }
        return kernel
    }()

    /// The output image produced by the original image colorized with the input color.
    override var outputImage: CIImage? {
        let inputs = [inputImage!, inputColor!] as [Any]
        return ColorFilter.kernel.apply(extent: inputImage!.extent, arguments: inputs)
    }
}
