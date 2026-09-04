//
//  ExcludeFilter.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreImage

/// An image processor that produces the difference between two images.
///
/// The CompareFilter class produces a CIImage object as output. The filter takes two images as input.
/// When using this filter, make sure the two images are the same size, otherwise it will crash.
internal class ExcludeFilter: CIFilter {

    /// The first input `CIImage`.
    var inputFirstImage: CIImage?

    /// The second input `CIImage`.
    var inputSecondImage: CIImage?

    /// The Metal function name.
    private static let functionName = "exclude"

    /// The Metal kernel, or `nil` when the compiled library could not be loaded.
    private static let kernel: CIColorKernel? = {
        return KernelLoader.loadFunction(named: functionName)
    }()

    /// The resulting image, or `nil` when the kernel is unavailable.
    override var outputImage: CIImage? {
        guard let kernel = ExcludeFilter.kernel, let inputFirstImage, let inputSecondImage else {
            return nil
        }
        let inputs = [inputFirstImage, inputSecondImage] as [Any]

        // Check is done at a higher level.
        // As long as this class stays internal the guard statement is superfluous.
        // guard inputFirstImage.extent.size == inputSecondImage.extent.size else {
        //     return nil
        // }

        return kernel.apply(extent: inputFirstImage.extent, arguments: inputs)
    }
}
