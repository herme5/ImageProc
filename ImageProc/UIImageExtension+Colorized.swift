//
//  UIImageExtension+Colorized.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

// MARK: - UIImage extension

internal extension UIImage {
    
    func colorizedBasic(color: UIColor) -> CIFilter {
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
        let channels = color.rgba

        // Throw away existing colors, and fill the non transparent pixels with the input color
        // s.r = dot(s, redVector), s.g = dot(s, greenVector), s.b = dot(s, blueVector), s.a = dot(s, alphaVector)
        // s = s + bias
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: channels.alpha), forKey: "inputAVector")
        colorMatrixFilter.setValue(CIVector(x: channels.red, y: channels.green, z: channels.blue, w: 0),
                                   forKey: "inputBiasVector")
        colorMatrixFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)

        // Down casting ColorFilter to CIFilter to finalize drawing
        return colorMatrixFilter
    }

    func colorizedConcurrent(color: UIColor) -> CIFilter {
        // Throw away existing color, and fill the non transparent pixels with the input color
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage!)
        colorFilter.inputColor = CIColor(color: color)

        // Down casting ColorFilter to CIFilter to finalize drawing
        return colorFilter
    }
}
