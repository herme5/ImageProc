//
//  ResourceLoader.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreImage
import Foundation

internal enum KernelLoader {

    /// The name of the compiled metal library, produced by the `CIKernelCompiler` build tool plugin.
    private static let resourceName = "ImageProcKernel.ci"

    /// The metal library extension.
    private static let resourceExtension = "metallib"

    /// The message printed when the compiled kernels cannot be loaded.
    private static let errorMessage =
        "Could not load the ImageProc Metal kernels. The operations relying on them return the " +
        "source image unchanged. This means the compiled kernel is missing from the package " +
        "resources, which is a packaging problem rather than a usage error."

    /// The compiled library, or `nil` when it is missing from the package resources.
    ///
    /// Loading is resolved against `Bundle.module` so it follows the package resource bundle,
    /// whatever the consumer's product or bundle identifier happens to be.
    private static func libraryData() -> Data? {
        guard let url = Bundle.module.url(forResource: resourceName, withExtension: resourceExtension),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data
    }

    /// Returns the color kernel for the given Metal function, or `nil` if the library cannot be loaded.
    static func loadFunction(named functionName: String) -> CIColorKernel? {
        guard let data = libraryData(),
              let kernel = try? CIColorKernel(functionName: functionName, fromMetalLibraryData: data)
        else {
            print("\(errorMessage) (function: \"\(functionName)\")")
            return nil
        }
        return kernel
    }

    /// Returns the general kernel for the given Metal function, or `nil` if the library cannot be loaded.
    ///
    /// A `CIColorKernel` may only read the pixel it is producing, so a function that samples its neighbours — the
    /// expansion does, all around a circle — has to be loaded as a plain `CIKernel` instead.
    static func loadGeneralFunction(named functionName: String) -> CIKernel? {
        guard let data = libraryData(),
              let kernel = try? CIKernel(functionName: functionName, fromMetalLibraryData: data)
        else {
            print("\(errorMessage) (function: \"\(functionName)\")")
            return nil
        }
        return kernel
    }
}
