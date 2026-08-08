//
//  UIImageExtension+Expanded.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 12/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

internal extension UIImage {

    private static let _concurrentExpandMethodQueue = DispatchQueue(
        label: "fr.andrearuffino.ImageProc.expandMethodQueue",
        attributes: .concurrent)

    /// Returns the directions, in degrees, to which the shape has to be replicated. The iteration goes from 0 to 360
    /// (excluded) by the given step.
    ///
    /// The result is computed for each call rather than cached: the array is small and sharing it across calls would
    /// require synchronizing every read against concurrent expansions using a different step.
    static func _expansionAngles(each degree: CGFloat) -> [CGFloat] {
        return stride(from: CGFloat(0.0), to: CGFloat(360), by: degree).map { $0 }
    }

    static func _expanded_basic(args: ExpandedArguments, cgImage: CGImage) {
        // Perform a translatation transform in each direction so that the context draw the shape shifted all
        // around the original position. Remember to perform the inverse translation for next iteration.
        for angle in args.angles {
            let vector = args.translationVector.rotated(around: .zero, byDegrees: angle)
            args.context.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
            args.context.draw(cgImage, in: args.translatedRect)
            args.context.concatenate(CGAffineTransform(translationX: -vector.dx, y: -vector.dy))
        }
    }

    static func _expanded_concurrent(args: ExpandedArguments, cgImage: CGImage) {
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: args.size.height)
        let angles = args.angles

        // Each iteration is a new layers that will be drawn at the end.
        // Use concurrentPerform method to let the native API manage the parallelism.
        DispatchQueue.concurrentPerform(iterations: angles.count) { iteration in
            let vector = args.translationVector.rotated(around: .zero, byDegrees: angles[iteration])

            // Create new context just for the layer.
            UIGraphicsBeginImageContextWithOptions(args.size, false, args.scale)
            let layerContext = UIGraphicsGetCurrentContext()!

            // Apply the same property as output context
            layerContext.interpolationQuality = args.context.interpolationQuality
            layerContext.concatenate(verticalFlip)

            // Perform a translatation transform in the right direction and save it for drawing later.
            // Here we don't need to perform inverse translation as we are not working on the final output
            // context.
            layerContext.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
            layerContext.draw(cgImage, in: args.translatedRect)
            UIImage._concurrentExpandMethodQueue.sync(flags: .barrier) {
                args.context.draw(layerContext.makeImage()!, in: CGRect(origin: .zero, size: args.size))
            }
            UIGraphicsEndImageContext()
        }
    }

    struct ExpandedArguments {
        var context: CGContext
        var translatedRect: CGRect
        var translationVector: CGVector
        var size: CGSize
        var scale: CGFloat
        var angles: [CGFloat]
    }
}
