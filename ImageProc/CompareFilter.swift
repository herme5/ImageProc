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

    /// The metal routine name of the color filter.
    private static let functionName = "compare"

    /// The GPU-based routine.
    private static let kernel: CIColorKernel = {
        return KernelLoader.loadFunction(named: functionName)
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
