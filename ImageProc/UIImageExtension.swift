//
//  UIImageExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 28/02/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

// MARK: - UIImage extension

public extension UIImage {

    /// Optimization methods used in the extension util functions when available.
    enum OptimizationMethod {
        /// `basic` optimization usually stands for sequential algorithms or native API based.
        case basic
        /// `concurrent` optimization usually stands for GPU parallel algorithms or concurrent dispatch queues.
        case concurrent
    }

    var sizeInPixel: CGSize { return size * scale }

    private static var _cachedRangeDegree = CGFloat(2)

    private static var _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)

    private static var _cachedRange = _cachedRangeStride.map { $0 }

    private static func _setupCachedRange(_ degree: CGFloat) {
        if degree != _cachedRangeDegree {
            _cachedRangeDegree = degree
            _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
            _cachedRange = _cachedRangeStride.map { $0 }
        }
    }

    private static let concurrentExpandMethodQueue = DispatchQueue(
        label: "fr.andrearuffino.ImageProc.expandMethodQueue",
        attributes: .concurrent)
    
    /// Renders a copy of this image where all opaque pixels have their color replaced by pixels of the given color.
    ///
    /// - parameters:
    ///   - color: The color to apply as a mask.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func colorized(with color: UIColor, method: OptimizationMethod = .basic) -> UIImage {
        var filter: CIFilter!
        guard cgImage != nil else { return self }

        switch method {
        case .basic:
            filter = _colorizedBasic(color: color)
        case .concurrent:
            filter = _colorizedConcurrent(color: color)
        }

        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        guard let ciOutput = filter.outputImage else { return self }
        guard let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent) else { return self }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }
    
    private func _colorizedBasic(color: UIColor) -> CIFilter {
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

        // Down casting ColorFilter to CIFilter to finalize drawing
        return colorMatrixFilter
    }
    
    private func _colorizedConcurrent(color: UIColor) -> CIFilter {
        // Throw away existing color, and fill the non transparent pixels with the input color
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage!)
        colorFilter.inputColor = CIColor(color: color)

        // Down casting ColorFilter to CIFilter to finalize drawing
        return colorFilter
    }
    
    /// Renders copy of this image where all opaque pixels are replicated all around the origin. This make an opaque
    /// shape bigger in more or less all direction. The degree parameters must be a step iteration between 0 and 360.
    ///
    /// E.g.: Given a degree equals to 90, the method will iterate each 90 degree from 0 to 360 (exluding 360),
    /// resulting in 4 iterations: 0, 90, 180 and 270, resulting in an image where replications is drawn at the top,
    /// bottom, left and right directions.
    ///
    /// Otherwise given a degree parameter equels to 1, the method will iterate each 1 degree from 0 to 360, resulting
    /// in 360 iterations and making the interpolation much better.
    ///
    /// - parameters:
    ///   - size: The distance in point.
    ///   - degree: Defines the direction iteration step to where the image have to be replicated.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func expand(bySize delta: CGFloat, each degree: CGFloat = 2, method: OptimizationMethod = .concurrent) -> UIImage {
        let newSize = CGSize(width: size.width + (2 * delta), height: size.height + (2 * delta))
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let translationRect = CGRect(x: delta, y: delta, width: size.width, height: size.height).integral
        let translationVector = CGVector(dx: delta, dy: 0)
        let interpQuality = CGInterpolationQuality.default
        UIImage._setupCachedRange(degree)
        
        guard cgImage != nil else { return self }

        // Create the final output context (only one will be used if basic optimisation)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = interpQuality
        context.concatenate(verticalFlip)

        switch method {
        case .basic:
            _expandBasic(
                context: context,
                tRect: translationRect,
                tVector: translationVector)
        case .concurrent:
            _expandConcurrent(
                context: context,
                tRect: translationRect,
                tVector: translationVector,
                newSize: newSize)
        }

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    private func _expandBasic(context: CGContext, tRect: CGRect, tVector: CGVector) {
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

    private func _expandConcurrent(context: CGContext, tRect: CGRect, tVector: CGVector, newSize: CGSize) {
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
            UIImage.concurrentExpandMethodQueue.sync(flags: .barrier) {
                context.draw(layerContext.makeImage()!, in: CGRect(origin: .zero, size: newSize))
            }
            UIGraphicsEndImageContext()
        }
    }

    /// Renders a copy of this image with a border along the opaque region of this image.
    ///
    /// - parameters:
    ///   - color: The border color.
    ///   - size: The border size.
    ///   - alpha: The border transparency.
    /// - returns: An `UIImage` where the opaque region is surrounded by a border.
    func stroked(with color: UIColor, size: CGFloat, each degree: CGFloat = 2, alpha: CGFloat = 1) -> UIImage {
        return colorized(with: color)
            .expand(bySize: size, each: degree)
            .withAlphaComponent(alpha)
            .drawnUnder(image: self)
    }

    /// Renders a a smoothened copy of this image with a gaussian blur given a radius measured in point. Most the of the
    /// time the output image will be larger than the source image.
    ///
    /// - parameters:
    ///   - radius: The blur radius in point.
    ///   - sizeKept: Whether the output image should keep the same size as before, or its size is increased by radius
    ///               so that we are sure the blur effect can exceed the initial size.
    /// - returns: A smoothened `UIImage`.
    func smoothened(by radius: CGFloat, sizeKept: Bool = false) -> UIImage {
        // smoothen the image with a gaussian blur
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")!
        guard cgImage != nil else { return self }
        
        gaussianFilter.setValue(radius, forKey: kCIInputRadiusKey)
        gaussianFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)

        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        guard let ciOutput = gaussianFilter.outputImage else { return self }
        let rect = sizeKept ? CGRect(origin: .zero, size: sizeInPixel) : ciOutput.extent
        guard let cgOutput = context.createCGImage(ciOutput, from: rect) else { return self }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a more transparent copy of this image.
    ///
    /// - parameters:
    ///   - value: The maximum alpha component value of the rendered image.
    /// - returns: A more transparent `UIImage`.
    func withAlphaComponent(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    /// Renders a scaled copy of this image given a new size in points.
    ///
    /// - parameters:
    ///   - newSize: The new size of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaled(to newSize: CGSize, interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        guard cgImage != nil else { return self }
        
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context.interpolationQuality = interpolationQuality
        context.concatenate(verticalFlip)
        context.draw(cgImage!, in: newRect)

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()

        return newImage.withOptions(from: self)
    }

    /// Renders a scaled copy of this image given a new width in points, the height is computed so that aspect ratio is
    /// kept to 1:1.
    ///
    /// - parameters:
    ///   - newWidth: The new width of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledWidth(to newWidth: CGFloat, keepAspectRatio: Bool = true,
                     interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        let newHeight = keepAspectRatio ? size.height * (newWidth / size.width) : size.height
        return scaled(to: CGSize(width: newWidth, height: newHeight), interpolationQuality: interpolationQuality)
    }

    /// Renders a scaled copy of this image given a new height in points, the width is computed so that aspect ratio is
    /// kept to 1:1.
    ///
    /// - parameters:
    ///   - newHeight: The new height of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledHeight(to newHeight: CGFloat, keepAspectRatio: Bool = true,
                      interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        let newWidth = keepAspectRatio ? size.width * (newHeight / size.height) : size.width
        return scaled(to: CGSize(width: newWidth, height: newHeight), interpolationQuality: interpolationQuality)
    }

    /// Crops and returns a copy of this image given a new rect.
    ///
    /// - parameters:
    ///   - rect: The new rect to which the image will be cropped.
    /// - returns: A cropped `UIImage`.
    func cropped(to rect: CGRect) -> UIImage {
        let contextRect = CGRect(origin: rect.origin * scale, size: rect.size * scale)
        guard let cgImage = cgImage, let cropped = cgImage.cropping(to: contextRect) else {
            return self
        }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Rotates and returns a copy of this image given an angle in degrees.
    ///
    /// - parameters:
    ///   - degrees: the clockwise angle to which the image has to be rotated.
    ///   - flip: boolean that indicate if the image should be flipped in the zero degree direction axis after the
    ///           rotation.
    /// - returns: A rotated `UIImage`.
    func rotated(by degrees: CGFloat) -> UIImage {
        guard cgImage != nil else { return self }
        
        let degreesToRadians: (CGFloat) -> CGFloat = { return $0 / 180.0 * CGFloat.pi }
        let radians = -degreesToRadians(degrees)

        // Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        rotatedViewBox.transform = rotatedViewBox.transform.rotated(by: radians)
        let newSize = rotatedViewBox.frame.integral.size

        // Create the bitmap context
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context.concatenate(verticalFlip)

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)

        // Now, draw the rotated/scaled image into the context
        // Remember to replace the center
        context.translateBy(x: -size.width / 2, y: -size.height / 2)
        context.draw(cgImage!, in: CGRect(origin: .zero, size: size))

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    /// Flips along X and returns a copy of this image.
    ///
    /// - returns: A horizontally flipped `UIImage`.
    func flippedHorizontally() -> UIImage {
        guard cgImage != nil else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!

        // Transform that flips x (and also y, because CGContexts are y inverted by default)
        let bothFlip = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: size.width, ty: size.height)
        context.concatenate(bothFlip)
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    /// Flips along Y and returns a copy of this image.
    ///
    /// - returns: A vertically flipped `UIImage`.
    func flippedVertically() -> UIImage {
        guard cgImage != nil else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!

        // No transform because CGContexts are y inverted by default
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    /// Overlays this image under another image and returns a copy of the two images combined.
    ///
    /// - returns: A `UIImage` where this image is under the other.
    func drawnUnder(image: UIImage) -> UIImage {
        // We explicitly use `self` to keep the comparison between the under and the above image.
        let maxWidth = max(self.size.width, image.size.width)
        let maxHeight = max(self.size.height, image.size.height)
        let maxSize = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: maxHeight))
        
        guard cgImage != nil else { return self }

        UIGraphicsBeginImageContextWithOptions(maxSize.size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
    
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: maxSize.height)
        context.concatenate(verticalFlip)

        let thisImageRect = CGRect(center: maxSize.center, size: self.size)
        context.draw(self.cgImage!, in: thisImageRect)

        let otherImageRect = CGRect(center: maxSize.center, size: image.size)
        context.draw(image.cgImage!, in: otherImageRect)

        let newImage = UIImage(cgImage: context.makeImage()!,
                               scale: self.scale,
                               orientation: self.imageOrientation)
        UIGraphicsEndImageContext()

        return newImage.withOptions(from: self)
    }

    /// Overlays this image above another image and returns a copy of the two images combined.
    ///
    /// - returns: A `UIImage` where this image is above the other.
    func drawnAbove(image: UIImage) -> UIImage {
        return image.drawnUnder(image: self)
    }

    private func withOptions(from other: UIImage) -> UIImage {
        var result = withRenderingMode(other.renderingMode)
            .withAlignmentRectInsets(other.alignmentRectInsets)

        if let configuration = other.configuration {
            result = result.withConfiguration(configuration)
        }
        if let baselineOffsetFromBottom = other.baselineOffsetFromBottom {
            result = result.withBaselineOffset(fromBottom: baselineOffsetFromBottom)
        }

        return result
    }

    // func pixelData() -> [UInt8]? {
    //     let size = self.size
    //     let dataSize = size.width * size.height * 4
    //     var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
    //     let colorSpace = CGColorSpaceCreateDeviceRGB()
    //     let context = CGContext(data: &pixelData,
    //                             width: Int(size.width),
    //                             height: Int(size.height),
    //                             bitsPerComponent: 8,
    //                             bytesPerRow: 4 * Int(size.width),
    //                             space: colorSpace,
    //                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    //     guard let cgImage = self.cgImage else { return nil }
    //     context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    //
    //     print("size", size)
    //     return pixelData
    // }
}
