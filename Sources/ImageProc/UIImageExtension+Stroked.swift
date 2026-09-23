//
//  UIImageExtension+Stroked.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/04/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

internal extension UIImage {

    /// The parameters of one stroke. The sizes are in points, in the coordinate space of the `cgImage` buffer the
    /// stroke is rendered from.
    struct StrokedArguments {
        var color: UIColor
        var sourceSize: CGSize
        var delta: CGFloat
        var degree: CGFloat
        var alpha: CGFloat
        var scale: CGFloat

        /// The size of the result, the source grown by the stroke on every side.
        var outputSize: CGSize {
            return CGSize(width: sourceSize.width + (2 * delta), height: sourceSize.height + (2 * delta))
        }
    }

    /// Renders the stroke: the source colorized, that copy expanded into a halo, and the source drawn back over it.
    ///
    /// - returns: The stroked buffer, or `nil` when no implementation could produce one.
    static func _strokedImpl(args: StrokedArguments, source: CGImage) -> CGImage? {
        if case .metal = _expandImplementation, let output = _stroked_metal(args: args, source: source) {
            return output
        }
        return _stroked_coreGraphics(args: args, source: source)
    }

    /// The whole stroke as one Core Image graph, so that the colorized copy and the halo never leave the GPU and
    /// only the result is read back.
    ///
    /// The Core Graphics implementation below renders the same three steps with two readbacks and four full size
    /// buffers; this one has a single `createCGImage` and no intermediate buffer at all.
    ///
    /// - returns: The stroked buffer, or `nil` when the kernel is unavailable, which sends the caller to the Core
    ///            Graphics implementation.
    private static func _stroked_metal(args: StrokedArguments, source: CGImage) -> CGImage? {
        guard ExpandFilter.isAvailable else {
            return nil
        }

        // Fading the halo is folded into the color it is painted with, rather than done in a pass of its own: the
        // colorize kernel already honors the input alpha, and the expansion keeps the most opaque sample of the
        // ring, so scaling every sample scales the one that wins by the same factor.
        let base = _rgbCompliant(args.color)
        let haloColor = args.alpha < 1 ? base.withAlphaComponent(base.rgba.alpha * args.alpha) : base

        let expandFilter = ExpandFilter()
        expandFilter.inputImage = _colorizedFilter(color: haloColor, cgImage: source).outputImage
        // The kernel works in the pixel space of the buffer it samples.
        expandFilter.inputRadius = args.delta * args.scale
        expandFilter.inputDegreeStep = args.degree

        guard let halo = expandFilter.outputImage else {
            return nil
        }
        // The halo's extent already starts at `-radius`, so the source sits centered in it untranslated.
        let output = CIImage(cgImage: source).composited(over: halo)
        return CIContext.rgbWorkingSpace.createCGImage(output, from: halo.extent)
    }

    /// The stroke rendered through Core Graphics, for when the expansion is not running on the GPU — either because
    /// a CPU implementation was selected, or because the compiled kernel is missing.
    private static func _stroked_coreGraphics(args: StrokedArguments, source: CGImage) -> CGImage? {
        // Colorize.
        let colorFilter = _colorizedFilter(color: args.color, cgImage: source)
        guard let ciOutput = colorFilter.outputImage,
              let colorized = CIContext.rgbWorkingSpace.createCGImage(ciOutput, from: ciOutput.extent) else {
            return nil
        }

        // Expand the colorized copy into a halo.
        let newSize = args.outputSize
        guard let halo = _expandedImpl(
            args: ExpandedArguments(
                translatedRect: CGRect(origin: CGPoint(x: args.delta, y: args.delta),
                                       size: args.sourceSize).integral,
                translationVector: CGVector(dx: args.delta, dy: 0),
                size: newSize,
                scale: args.scale,
                angles: _expansionAngles(each: args.degree),
                degreeStep: args.degree),
            cgImage: colorized) else {
            return nil
        }

        // Draw the source over the halo.
        UIGraphicsBeginImageContextWithOptions(newSize, false, args.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        defer { UIGraphicsEndImageContext() }

        let newRect = CGRect(origin: .zero, size: newSize)
        context.interpolationQuality = .default
        context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height))

        let haloRect = CGRect(center: newRect.center,
                              size: CGSize(width: halo.width, height: halo.height) / args.scale)
        context.saveGState()
        context.setBlendMode(.normal)
        context.setAlpha(args.alpha)
        context.draw(halo, in: haloRect)
        context.restoreGState()

        context.draw(source, in: CGRect(center: newRect.center, size: args.sourceSize))
        return context.makeImage()
    }
}
