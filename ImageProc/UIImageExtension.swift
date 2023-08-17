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
// swiftlint:disable file_length

public extension UIImage {

    var sizeInPixel: CGSize { return size * scale }

    private static let _ciImageErrorMessage =
        "Core Graphics image property `cgImage` is required to use this method. " +
        "Avoid using init(ciImage:) initializer."

    /// Renders a copy of this image where all opaque pixels have their color replaced by pixels of the given color.
    ///
    /// - parameters:
    ///   - color: The color to apply as a mask.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func colorized(with color: UIColor) -> UIImage {
        var filter: CIFilter!
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        var color = color
        if color.cgColor.colorSpace == nil || color.cgColor.colorSpace!.model != .rgb {
            let conv = color.cgColor.converted(to: CGColor.defaultRGB, intent: .defaultIntent, options: nil)!
            color = UIColor(cgColor: conv)
        }

        filter = Self._colorizedImpl(args: ColorizedArguments(color: color), cgImage: cgImage!)

        let context = CIContext(options: [.workingColorSpace: color.cgColor.colorSpace!])
        let ciOutput = filter.outputImage!
        let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent)!
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renamed to `expanded(bySize:each:)`
    @available(*, deprecated, renamed: "expanded(bySize:each:)")
    func expand(bySize delta: CGFloat, each degree: CGFloat = 3) -> UIImage {
        return expanded(bySize: delta, each: degree)
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
    func expanded(bySize delta: CGFloat, each degree: CGFloat = 3) -> UIImage {
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        let newSize = CGSize(width: size.width + (2 * delta), height: size.height + (2 * delta))
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let translatedRect = CGRect(x: delta, y: delta, width: size.width, height: size.height).integral
        let translationVector = CGVector(dx: delta, dy: 0)
        let interpQuality = CGInterpolationQuality.default
        UIImage._setupCachedRange(degree)

        // Create the final output context (only one will be used if basic optimisation)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = interpQuality
        context.concatenate(verticalFlip)

        Self._expandedImpl(
            args: ExpandedArguments(
                context: context,
                translatedRect: translatedRect,
                translationVector: translationVector,
                size: newSize,
                scale: scale),
            cgImage: cgImage!)

        let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
        UIGraphicsEndImageContext()
        return newImage.withOptions(from: self)
    }

    /// Renders a copy of this image with a border along the opaque region of this image.
    ///
    /// - parameters:
    ///   - color: The border color.
    ///   - size: The border size.
    ///   - alpha: The border transparency.
    /// - returns: An `UIImage` where the opaque region is surrounded by a border.
    func stroked(with color: UIColor, size delta: CGFloat, each degree: CGFloat = 3, alpha: CGFloat = 1) -> UIImage {
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // Colorize
        let colorFilter = Self._colorizedImpl(args: ColorizedArguments(color: color), cgImage: cgImage!)
        let ciContext = CIContext(options: [.workingColorSpace: CGColor.defaultRGB])
        let ciOutput = colorFilter.outputImage!
        var cgOutput = ciContext.createCGImage(ciOutput, from: ciOutput.extent)!

        // Expand
        let newSize = CGSize(width: size.width + (2 * delta), height: size.height + (2 * delta))
        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let translatedRect = CGRect(x: delta, y: delta, width: size.width, height: size.height).integral
        let translationVector = CGVector(dx: delta, dy: 0)
        let interpQuality = CGInterpolationQuality.default
        UIImage._setupCachedRange(degree)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let cgContext = UIGraphicsGetCurrentContext()!

        cgContext.interpolationQuality = interpQuality
        cgContext.concatenate(verticalFlip)

        UIImage._expandedImpl(
            args: ExpandedArguments(
                context: cgContext,
                translatedRect: translatedRect,
                translationVector: translationVector,
                size: newSize,
                scale: scale),
            cgImage: cgOutput)

        // Draw expanded under colorized
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

        return newImage.withOptions(from: self)
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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // smoothen the image with a gaussian blur
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")!

        gaussianFilter.setValue(radius, forKey: kCIInputRadiusKey)
        gaussianFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)

        let context = CIContext()
        let ciOutput = gaussianFilter.outputImage!
        let rect = sizeKept ? CGRect(origin: .zero, size: sizeInPixel) : ciOutput.extent
        let cgOutput = context.createCGImage(ciOutput, from: rect)!
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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        let contextRect = CGRect(origin: rect.origin * scale, size: rect.size * scale)
        guard let cropped = cgImage!.cropping(to: contextRect) else {
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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

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
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        
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
        guard self.cgImage != nil && image.cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // We explicitly use `self` to keep the comparison between the under and the above image.
        let maxWidth = max(self.size.width, image.size.width)
        let maxHeight = max(self.size.height, image.size.height)
        let maxSize = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: maxHeight))

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

    /// TODO
    /// - parameters:
    ///   - image: TODO
    /// - returns: TODO
    func alphaMasked(with image: UIImage) -> UIImage {
        let filter = CompareFilter()
        guard self.cgImage != nil && image.cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        let maxSize = CGSize(
            width: max(self.size.width, image.size.width),
            height: max(self.size.height, image.size.height))
        let maxCenter = CGPoint(
            x: maxSize.width/2,
            y: maxSize.height/2)

        UIGraphicsBeginImageContextWithOptions(maxSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!

        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: maxSize.height)
        let inputFirstImageRect = CGRect(center: maxCenter, size: self.size)
        let inputSecondImageRect = CGRect(center: maxCenter, size: image.size)

        context.concatenate(verticalFlip)
        context.draw(self.cgImage!, in: inputFirstImageRect)
        let inputFirstImage = context.makeImage()!

        context.clear(CGRect(origin: .zero, size: maxSize))
        context.draw(image.cgImage!, in: inputSecondImageRect)
        let inputSecondImage = context.makeImage()!

        UIGraphicsEndImageContext()

        let colorSpace = CGColor.defaultRGB
        filter.inputFirstImage = CIImage(cgImage: inputFirstImage)
        filter.inputSecondImage = CIImage(cgImage: inputSecondImage)
        let ciContext = CIContext(options: [.workingColorSpace: colorSpace])

        guard let ciOutput = filter.outputImage else {
            return self
        }
        let cgOutput = ciContext.createCGImage(ciOutput, from: ciOutput.extent)!
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Extracts the bitmap data with the form of an array of UIColor.
    /// This function returns the result of the handler.
    func withBitmapData<T>(_ handler: ([UIColor]) -> T?) -> T? {
        guard let cgImage else {
            print(UIImage._ciImageErrorMessage)
            return nil
        }
        return cgImage.withBitmapData { cgColors in
            handler(cgColors.map { cgColor in
                UIColor(cgColor: cgColor)
            })
        }
    }

    /// The percentage of opaque pixels in the image
    var opaquePixelDensity: Double? {
        guard let alphaLayer = withBitmapData({ colors in colors.map { $0.rgba.alpha } }) else {
            return nil
        }

        let total = sizeInPixel.width * sizeInPixel.height
        return alphaLayer.reduce(0, +) / CGFloat(total)
    }

    // MARK: - Swizzling methods

    @objc dynamic
    internal static func _colorizedImpl(args: ColorizedArguments, cgImage: CGImage) -> CIFilter {
        return _colorized_ciColorMatrix(args: args, cgImage: cgImage)
    }

    @objc dynamic
    internal static func _expandedImpl(args: ExpandedArguments, cgImage: CGImage) {
        _expanded_concurrent(args: args, cgImage: cgImage)
    }

    static func useMetalColorizationMethod() {
        let originalMethod = class_getClassMethod(Self.self, #selector(_colorizedImpl))
        let swizzledMethod = class_getClassMethod(Self.self, #selector(_colorized_mtlColorFilter))
        guard let originalMethod, let swizzledMethod else {
            fatalError("Could not swizzle implementation")
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

}
