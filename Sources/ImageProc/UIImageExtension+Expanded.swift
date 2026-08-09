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

    /// Shared across expansions on purpose: building a `CIContext` costs tens of milliseconds, which dwarfed the
    /// render itself when it was done per call. `CIContext` is documented as safe to use from several threads.
    private static let _expandContext = CIContext(options: [.workingColorSpace: CGColor.defaultRGBColorSpace])

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

    /// Replicates the source on the GPU, gathering instead of scattering: each output pixel reads the ring of source
    /// samples around itself, so there is no layer per direction and nothing to composite afterwards.
    ///
    /// - returns: Whether the kernel was available and the render succeeded. The caller falls back to a CPU
    ///            implementation when it was not, which is better than the source-unchanged degradation the other
    ///            kernel-backed operations settle for, since here a working implementation exists.
    static func _expanded_metal(args: ExpandedArguments, cgImage: CGImage) -> Bool {
        guard ExpandFilter.isAvailable else {
            return false
        }

        let filter = ExpandFilter()
        filter.inputImage = CIImage(cgImage: cgImage)
        // The kernel works in the pixel space of the buffer it samples.
        filter.inputRadius = args.translationVector.dx * args.scale
        filter.inputDegreeStep = args.degreeStep

        guard let ciOutput = filter.outputImage,
              let cgOutput = _expandContext.createCGImage(ciOutput, from: ciOutput.extent) else {
            return false
        }

        // The output extent is the source grown by the radius on every side, which is exactly the context the caller
        // prepared, so it lands with a single draw.
        args.context.draw(cgOutput, in: CGRect(origin: .zero, size: args.size))
        return true
    }

    struct ExpandedArguments {
        var context: CGContext
        var translatedRect: CGRect
        var translationVector: CGVector
        var size: CGSize
        var scale: CGFloat
        var angles: [CGFloat]
        var degreeStep: CGFloat
    }

    /// The available expansion implementations.
    ///
    /// This is not the return of the removed swizzling experiment: it is an internal property, the public surface is
    /// unchanged, and its reason is that the three implementations have to be timed against each other.
    enum ExpandImplementation {
        /// The Metal kernel, falling back to `concurrent` when the compiled library is missing.
        case metal
        /// One `CGContext` layer per direction, composited under a barrier. Order-dependent, so its result is not
        /// reproducible for a multi-colored source.
        case concurrent
        /// All the directions drawn into the single output context, in order. The reference implementation.
        case basic
    }

    /// Which implementation `_expandedImpl` runs. Not thread-safe to change while an expansion is in flight.
    static var _expandImplementation = ExpandImplementation.metal
}
