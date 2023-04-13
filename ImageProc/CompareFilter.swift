//
//  File.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreImage

// MARK: - ColorFilter implementation

/// TODO
internal class CompareFilter: CIFilter {

    /// The first input `CIImage` to compare.
    var inputFirstImage: CIImage?

    /// The second input `CIImage` to compare.
    var inputSecondImage: CIImage?

    /// The GPU-based routine.
    private static let kernel: CIColorKernel = {
        let kernelCode =
        """
        kernel vec4 colorize(__sample pixel_a, __sample pixel_b) {
            vec4 pixel;
            pixel.a = abs(pixel_b.a - pixel_a.a);
            return pixel;
        }
        """
        return CIColorKernel(source: kernelCode)!
    }()

    /// The output image produced by the original image colorized with the input color.
    override var outputImage: CIImage? {
        let inputs = [inputFirstImage!, inputSecondImage!] as [Any]
        guard inputFirstImage!.extent.size == inputSecondImage!.extent.size else {
            return nil
        }
        return CompareFilter.kernel.apply(extent: inputFirstImage!.extent, arguments: inputs)
    }
}
