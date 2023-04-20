//
//  UIImageExtension+Expand.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

// MARK: - UIImage extension

internal extension UIImage {

    private static let _concurrentExpandMethodQueue = DispatchQueue(
        label: "fr.andrearuffino.ImageProc.expandMethodQueue",
        attributes: .concurrent)
    private static var _cachedRangeDegree = CGFloat(2)
    private static var _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
    private static var _cachedRange = _cachedRangeStride.map { $0 }

    static func _setupCachedRange(_ degree: CGFloat) {
        if degree != _cachedRangeDegree {
            _cachedRangeDegree = degree
            _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
            _cachedRange = _cachedRangeStride.map { $0 }
        }
    }

    func _expandBasic(context: CGContext, tRect: CGRect, tVector: CGVector) {
        let range = UIImage._cachedRangeStride

        // Perform a translatation transform in each direction so that the context draw the shape shifted all
        // around the original position. Remember to perform the inverse translation for next iteration.
        for angle in range {
            let vector = tVector.rotated(around: .zero, byDegrees: angle)
            context.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
            context.draw(cgImage!, in: tRect)
            context.concatenate(CGAffineTransform(translationX: -vector.dx, y: -vector.dy))
        }
    }

    func _expandConcurrent(context: CGContext, tRect: CGRect, tVector: CGVector, newSize: CGSize) {
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let angles = UIImage._cachedRange

        // Each iteration is a new layers that will be drawn at the end.
        // Use concurrentPerform method to let the native API manage the parallelism.
        DispatchQueue.concurrentPerform(iterations: angles.count) { iteration in
            let vector = tVector.rotated(around: .zero, byDegrees: angles[iteration])

            // Create new context just for the layer.
            UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
            let layerContext = UIGraphicsGetCurrentContext()!

            // Apply the same property as output context
            layerContext.interpolationQuality = context.interpolationQuality
            layerContext.concatenate(verticalFlip)

            // Perform a translatation transform in the right direction and save it for drawing later.
            // Here we don't need to perform inverse translation as we are not working on the final output
            // context.
            layerContext.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
            layerContext.draw(cgImage!, in: tRect)
            UIImage._concurrentExpandMethodQueue.sync(flags: .barrier) {
                context.draw(layerContext.makeImage()!, in: CGRect(origin: .zero, size: newSize))
            }
            UIGraphicsEndImageContext()
        }
    }

    func _stroked(with color: UIColor, size delta: CGFloat, each degree: CGFloat = 2, alpha: CGFloat = 1) -> UIImage {
        
        // MARK: - Colorized
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
        let channels = color.rgba

        // Throw away existing colors, and fill the non transparent pixels with the input color
        // s.r = dot(s, redVector), s.g = dot(s, greenVector), s.b = dot(s, blueVector), s.a = dot(s, alphaVector)
        // s = s + bias
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        colorMatrixFilter.setValue(CIVector(x: channels.red, y: channels.green, z: channels.blue, w: 0),
                                   forKey: "inputBiasVector")
        colorMatrixFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)
        
        let ciContext = CIContext(options: [.workingColorSpace: CGColor.defaultRGB])
        let ciOutput = colorMatrixFilter.outputImage!
        var cgOutput = ciContext.createCGImage(ciOutput, from: ciOutput.extent)!
        
        // MARK: - Expand
        let newSize = CGSize(width: size.width + (2 * delta), height: size.height + (2 * delta))
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let translationRect = CGRect(x: delta, y: delta, width: size.width, height: size.height).integral
        let translationVector = CGVector(dx: delta, dy: 0)
        let interpQuality = CGInterpolationQuality.default
        UIImage._setupCachedRange(degree)

        // Create the final output context (only one will be used if basic optimisation)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let cgContext = UIGraphicsGetCurrentContext()!
        
        cgContext.interpolationQuality = interpQuality
        cgContext.concatenate(verticalFlip)
        let angles = UIImage._cachedRange

        // Each iteration is a new layers that will be drawn at the end.
        // Use concurrentPerform method to let the native API manage the parallelism.
        DispatchQueue.concurrentPerform(iterations: angles.count) { iteration in
            let vector = translationVector.rotated(around: .zero, byDegrees: angles[iteration])

            // Create new context just for the layer.
            UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
            let layerContext = UIGraphicsGetCurrentContext()!

            // Apply the same property as output context
            layerContext.interpolationQuality = cgContext.interpolationQuality
            layerContext.concatenate(verticalFlip)

            // Perform a translatation transform in the right direction and save it for drawing later.
            // Here we don't need to perform inverse translation as we are not working on the final output
            // context.
            layerContext.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
            layerContext.draw(cgOutput, in: translationRect)
            UIImage._concurrentExpandMethodQueue.sync(flags: .barrier) {
                cgContext.draw(layerContext.makeImage()!, in: CGRect(origin: .zero, size: newSize))
            }
            UIGraphicsEndImageContext()
        }

        // MARK: - Drawn cgOutput under self
        let newRect = CGRect(origin: .zero, size: newSize)
        cgOutput = cgContext.makeImage()!
        cgContext.clear(newRect)

        let otherImageRect = CGRect(center: newRect.center, size: CGSize(width: cgOutput.width, height: cgOutput.height) / scale)
        cgContext.saveGState()
        cgContext.setBlendMode(.normal)
        cgContext.setAlpha(alpha)
        cgContext.draw(cgOutput, in: otherImageRect)
        cgContext.restoreGState()

        let thisImageRect = CGRect(center: newRect.center, size: self.size)
        cgContext.draw(self.cgImage!, in: thisImageRect)

        let newImage = UIImage(cgImage: cgContext.makeImage()!,
                               scale: self.scale,
                               orientation: self.imageOrientation)
        UIGraphicsEndImageContext()

        return newImage
    }
}
