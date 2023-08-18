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

    @objc dynamic
    static func _colorized_ciColorMatrix(args: ColorizedArguments, cgImage: CGImage) -> CIFilter {
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
        let channels = args.color.rgba
        let r = channels.red,
            g = channels.green,
            b = channels.blue,
            a = channels.alpha

        // Throw away existing colors, and fill the non transparent pixels with the input color
        // s.r = dot(s, redVector)
        // s.g = dot(s, greenVector)
        // s.b = dot(s, blueVector)
        // s.a = dot(s, alphaVector)
        // s = s + bias
        let keys = ["inputRVector", "inputGVector", "inputBVector", "inputAVector", "inputBiasVector"]
        let matrix = [
            keys[0]: CIVector(x: 0, y: 0, z: 0, w: 0), // inputRVector
            keys[1]: CIVector(x: 0, y: 0, z: 0, w: 0), // inputGVector
            keys[2]: CIVector(x: 0, y: 0, z: 0, w: 0), // inputBVector
            keys[3]: CIVector(x: 0, y: 0, z: 0, w: a), // inputAVector
            keys[4]: CIVector(x: r, y: g, z: b, w: 0) // inputBiasVector
        ]

        matrix.forEach { colorMatrixFilter.setValue($0.value, forKey: $0.key) }
        colorMatrixFilter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        return colorMatrixFilter
    }

    @objc dynamic
    static func _colorized_mtlColorFilter(args: ColorizedArguments, cgImage: CGImage) -> CIFilter {
        // Use a custom CIFilter based on a Metal routine
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage)
        colorFilter.inputColor = CIColor(color: args.color)
        return colorFilter
    }

    class ColorizedArguments: NSObject {
        var color: UIColor

        init(color: UIColor) {
            self.color = color
        }
    }
}
