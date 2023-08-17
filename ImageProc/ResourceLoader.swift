//
//  ResourceLoader.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import Foundation

internal class KernelLoader {

    /// The bundle where the compiled metal library is located.
    private static let bundleName = "com.andrearuffino.ImageProc"

    /// The name of the compiled metal library.
    private static let resourceName = "ImageProcKernel.ci"

    /// The metal library extension.
    private static let resourceExtension = "metallib"

    private init() { }

    static func loadFunction(named functionName: String) -> CIColorKernel {
        guard let bundle = Bundle(identifier: bundleName),
              let url = bundle.url(forResource: resourceName, withExtension: resourceExtension),
              let data = try? Data(contentsOf: url),
              let kernel = try? CIColorKernel(functionName: functionName, fromMetalLibraryData: data)
        else {
            fatalError("Unable to load \"\(functionName)\" from ImageProcKernel.ci")
        }
        return kernel
    }
}
