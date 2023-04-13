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

    static func setupCachedRange(_ degree: CGFloat) {
        if degree != _cachedRangeDegree {
            _cachedRangeDegree = degree
            _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
            _cachedRange = _cachedRangeStride.map { $0 }
        }
    }

    func expandBasic(context: CGContext, tRect: CGRect, tVector: CGVector) {
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

    func expandConcurrent(context: CGContext, tRect: CGRect, tVector: CGVector, newSize: CGSize) {
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
}
