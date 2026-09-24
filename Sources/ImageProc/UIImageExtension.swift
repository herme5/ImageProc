//
//  UIImageExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 28/02/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

// swiftlint:disable file_length

public extension UIImage {

    /// The default message when cgImage property is not available.
    private static let _ciImageErrorMessage =
        "Core Graphics image property `cgImage` is required to use this method. " +
        "Avoid using init(ciImage:) initializer."

    /// The size in pixel.
    var sizeInPixel: CGSize { return size * scale }

    /// The percentage of opaque pixels in the image.
    var opaquePixelDensity: Double? {
        guard let cgImage else {
            print(UIImage._ciImageErrorMessage)
            return nil
        }

        let total = cgImage.width * cgImage.height
        guard total > 0 else {
            return nil
        }

        // Only the alpha channel is needed, so it is the only one rendered, and it is summed in place rather than
        // turned into color objects.
        guard let sum = cgImage.withAlphaBuffer({ alphas in
            alphas.reduce(into: 0) { partial, alpha in partial += Int(alpha) }
        }) else {
            return nil
        }
        return Double(sum) / 255 / Double(total)
    }

    // MARK: - Processing methods

    /// Renders a copy of this image where all opaque pixels have their color replaced by pixels of the given color.
    ///
    /// - parameters:
    ///   - color: The color to apply as a mask.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func colorized(with color: UIColor) -> UIImage {
        if let dynamic = _perColorTrait(alsoVarying: color._colorTraitVariance, {
            $0.colorized(with: color.resolvedColor(with: $1))
        }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        let filter = Self._colorizedFilter(color: color, cgImage: cgImage!)

        let context = CIContext.rgbWorkingSpace
        guard let ciOutput = filter.outputImage,
              let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            return self
        }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
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
        if let dynamic = _perColorTrait({ image, _ in image.expanded(bySize: delta, each: degree) }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // The expansion is rendered from the raw `cgImage` buffer, so the geometry is expressed in that buffer's
        // space. Expanding is isotropic, so growing it by the same delta on both axes holds whatever the orientation
        // is.
        let sourceSize = _bufferSize
        let newSize = CGSize(width: sourceSize.width + (2 * delta), height: sourceSize.height + (2 * delta))

        guard let expandedImage = Self._expandedImpl(
            args: ExpandedArguments(
                translatedRect: CGRect(origin: CGPoint(x: delta, y: delta), size: sourceSize).integral,
                translationVector: CGVector(dx: delta, dy: 0),
                size: newSize,
                scale: scale,
                angles: Self._expansionAngles(each: degree),
                degreeStep: degree),
            cgImage: cgImage!) else {
            return self
        }
        return UIImage(cgImage: expandedImage, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a copy of this image with a border along the opaque region of this image.
    ///
    /// - parameters:
    ///   - color: The border color.
    ///   - size: The border size.
    ///   - alpha: The border transparency.
    /// - returns: An `UIImage` where the opaque region is surrounded by a border.
    func stroked(with color: UIColor, size delta: CGFloat, each degree: CGFloat = 3, alpha: CGFloat = 1) -> UIImage {
        if let dynamic = _perColorTrait(alsoVarying: color._colorTraitVariance, {
            $0.stroked(with: color.resolvedColor(with: $1), size: delta, each: degree, alpha: alpha)
        }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // The stroke is rendered from the raw `cgImage` buffer, so the geometry is expressed in that buffer's space.
        guard let strokedImage = Self._strokedImpl(
            args: StrokedArguments(color: color,
                                   sourceSize: _bufferSize,
                                   delta: delta,
                                   degree: degree,
                                   alpha: alpha,
                                   scale: scale),
            source: cgImage!) else {
            return self
        }
        return UIImage(cgImage: strokedImage, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a smoothened copy of this image with a gaussian blur given a radius measured in point. Most the of the
    /// time the output image will be larger than the source image.
    ///
    /// - parameters:
    ///   - radius: The blur radius in point.
    ///   - sizeKept: Whether the output image should keep the same size as before, or its size is increased by radius
    ///               so that we are sure the blur effect can exceed the initial size.
    /// - returns: A smoothened `UIImage`.
    func smoothened(by radius: CGFloat, sizeKept: Bool = false) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image.smoothened(by: radius, sizeKept: sizeKept) }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // smoothen the image with a gaussian blur
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")!

        gaussianFilter.setValue(radius, forKey: kCIInputRadiusKey)
        gaussianFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)

        // Keeping the size means cropping back to the input extent, which is the `cgImage` buffer rather than
        // `sizeInPixel`: the two differ under a quarter-turn orientation.
        let bufferExtent = CGSize(width: cgImage!.width, height: cgImage!.height)
        let context = CIContext.defaultWorkingSpace
        guard let ciOutput = gaussianFilter.outputImage else {
            return self
        }
        let rect = sizeKept ? CGRect(origin: .zero, size: bufferExtent) : ciOutput.extent
        guard let cgOutput = context.createCGImage(ciOutput, from: rect) else {
            return self
        }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a more transparent copy of this image.
    ///
    /// - parameters:
    ///   - value: The maximum alpha component value of the rendered image.
    /// - returns: A more transparent `UIImage`.
    func withAlphaComponent(_ value: CGFloat) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image.withAlphaComponent(value) }) {
            return dynamic
        }
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
    /// - returns: A scaled `UIImage`.
    func scaled(to newSize: CGSize, interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in
            image.scaled(to: newSize, interpolationQuality: interpolationQuality)
        }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // The context is filled with the raw `cgImage` buffer and the result carries the receiver's orientation
        // again, so it has to be sized in that buffer's space rather than in the displayed one. A quarter-turn
        // orientation exchanges the two, and sizing the context in the displayed space transposes the result.
        let contextSize = _orientationSwapsAxes
            ? CGSize(width: newSize.height, height: newSize.width)
            : newSize
        let newRect = CGRect(origin: .zero, size: contextSize).integral
        UIGraphicsBeginImageContextWithOptions(contextSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        defer { UIGraphicsEndImageContext() }

        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: contextSize.height)
        context.interpolationQuality = interpolationQuality
        context.concatenate(verticalFlip)
        context.draw(cgImage!, in: newRect)

        guard let scaledImage = context.makeImage() else {
            return self
        }
        return UIImage(cgImage: scaledImage, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a scaled copy of this image given a scale factor. The scale value must not be negative. A 1.0 scale value preserves the size and 2.0 doubles it.
    ///
    /// - parameters:
    ///   - newSize: The new size of the output image.
    /// - returns: A scaled `UIImage`.
    func scaled(uniform scalar: CGFloat, interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        return scaled(to: size * scalar, interpolationQuality: interpolationQuality)
    }

    /// Renders a scaled copy of this image given a new width in points, the height is computed so that aspect ratio is
    /// kept to 1:1.
    ///
    /// - parameters:
    ///   - newWidth: The new width of the output image.
    /// - returns: A scaled `UIImage`.
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
    /// - returns: A scaled `UIImage`.
    func scaledHeight(to newHeight: CGFloat, keepAspectRatio: Bool = true,
                      interpolationQuality: CGInterpolationQuality = .default) -> UIImage {
        let newWidth = keepAspectRatio ? size.width * (newHeight / size.height) : size.width
        return scaled(to: CGSize(width: newWidth, height: newHeight), interpolationQuality: interpolationQuality)
    }

    /// Renders a cropped copy of this image given a new rect.
    ///
    /// - parameters:
    ///   - rect: The new rect to which the image will be cropped.
    /// - returns: A cropped `UIImage`.
    func cropped(to rect: CGRect) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image.cropped(to: rect) }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        // The caller expresses the rect in the displayed space, `cropping(to:)` works on the buffer: a non-`.up`
        // orientation moves the region, and a quarter-turn one also transposes it.
        let bufferRect = _bufferRect(from: rect)
        let contextRect = CGRect(origin: bufferRect.origin * scale, size: bufferRect.size * scale)
        guard let cropped = cgImage!.cropping(to: contextRect) else {
            return self
        }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a rotated copy of this image given an angle in degrees.
    ///
    /// - parameters:
    ///   - degrees: the clockwise angle to which the image has to be rotated.
    ///   - flip: boolean that indicate if the image should be flipped in the zero degree direction axis after the
    ///           rotation.
    /// - returns: A rotated `UIImage`.
    func rotated(by degrees: CGFloat) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image.rotated(by: degrees) }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        let degreesToRadians: (CGFloat) -> CGFloat = { return $0 / 180.0 * CGFloat.pi }

        // The rotation is applied to the `cgImage` buffer, and a mirrored orientation reverses the direction it
        // appears to turn in once displayed, so the angle has to be reversed with it.
        let radians = (_orientationIsMirrored ? 1 : -1) * degreesToRadians(degrees)
        let sourceSize = _bufferSize

        // The box containing the rotated image, rounded up to whole points. It used to be the `integral` frame of a
        // rotated `UIView`, which was not safe off the main thread, and which gave a right angle an extra transparent
        // point per rotated side: `cos(90°)` is not exactly zero, so the side comes out a hair over a whole number.
        // That noise is dropped before rounding up.
        let rotatedBox = CGRect(origin: .zero, size: sourceSize).applying(CGAffineTransform(rotationAngle: radians))
        let noise = CGFloat(1e-6)
        let newSize = CGSize(width: (rotatedBox.width - noise).rounded(.up),
                             height: (rotatedBox.height - noise).rounded(.up))

        // Create the bitmap context
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        defer { UIGraphicsEndImageContext() }

        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context.concatenate(verticalFlip)

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)

        // Now, draw the rotated/scaled image into the context
        // Remember to replace the center
        context.translateBy(x: -sourceSize.width / 2, y: -sourceSize.height / 2)
        context.draw(cgImage!, in: CGRect(origin: .zero, size: sourceSize))

        guard let rotatedImage = context.makeImage() else {
            return self
        }
        return UIImage(cgImage: rotatedImage, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders a copy of this image which is flipped along the X-axis.
    ///
    /// - returns: A horizontally flipped `UIImage`.
    func flippedHorizontally() -> UIImage {
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        // A quarter-turn orientation exchanges the axes, so flipping the displayed image along X means flipping its
        // buffer along Y. Whether the orientation also mirrors does not matter: flips along one axis commute.
        return _flipped(bufferAlongX: !_orientationSwapsAxes)
    }

    /// Renders a copy of this image which is flipped along the Y-axis.
    ///
    /// - returns: A horizontally flipped `UIImage`.
    func flippedVertically() -> UIImage {
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        return _flipped(bufferAlongX: _orientationSwapsAxes)
    }

    /// Renders a copy of this image whose `cgImage` buffer is flipped along one axis.
    ///
    /// - parameters:
    ///   - bufferAlongX: Whether to flip the buffer along its X-axis rather than its Y-axis.
    /// - returns: A flipped `UIImage`.
    private func _flipped(bufferAlongX: Bool) -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image._flipped(bufferAlongX: bufferAlongX) }) {
            return dynamic
        }
        let sourceSize = _bufferSize
        UIGraphicsBeginImageContextWithOptions(sourceSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        defer { UIGraphicsEndImageContext() }

        // Nothing to concatenate to flip along y, because CGContexts are y inverted by default. Flipping along x
        // means flipping both, so that the default inversion is compensated.
        if bufferAlongX {
            let bothFlip = CGAffineTransform(a: -1, b: 0, c: 0, d: -1,
                                             tx: sourceSize.width, ty: sourceSize.height)
            context.concatenate(bothFlip)
        }
        context.draw(cgImage!, in: CGRect(origin: .zero, size: sourceSize))

        guard let flippedImage = context.makeImage() else {
            return self
        }
        return UIImage(cgImage: flippedImage, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders all opaque pixels under an other image.
    ///
    /// - returns: A `UIImage` where this image is under the other.
    func drawnUnder(image: UIImage) -> UIImage {
        if let dynamic = _perColorTrait(alsoVarying: image._colorTraitVariance, {
            $0.drawnUnder(image: image._flattened(for: $1))
        }) {
            return dynamic
        }
        guard self.cgImage != nil && image.cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        return Self._composited(under: self, over: image._reoriented(to: imageOrientation), like: self)
    }

    /// Renders all opaque pixels above an other image.
    ///
    /// - returns: A `UIImage` where this image is above the other.
    func drawnAbove(image: UIImage) -> UIImage {
        if let dynamic = _perColorTrait(alsoVarying: image._colorTraitVariance, {
            $0.drawnAbove(image: image._flattened(for: $1))
        }) {
            return dynamic
        }
        guard self.cgImage != nil && image.cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }
        // Not `image.drawnUnder(image: self)`: that would render in the other image's coordinate space and carry over
        // its options, whereas the receiver is the one the result has to look like.
        return Self._composited(under: image._reoriented(to: imageOrientation), over: self, like: self)
    }

    /// Draws one image on top of an other, both centered in the rect that encompasses the two.
    ///
    /// - parameters:
    ///   - lower: The image drawn first.
    ///   - upper: The image drawn over the first one.
    ///   - receiver: The image whose scale, orientation and options the result adopts.
    /// - returns: The composited `UIImage`.
    private static func _composited(under lower: UIImage, over upper: UIImage, like receiver: UIImage) -> UIImage {
        // Both buffers are drawn raw, so the rect that encompasses the two is measured in buffer space.
        let lowerSize = lower._bufferSize
        let upperSize = upper._bufferSize
        let maxWidth = max(lowerSize.width, upperSize.width)
        let maxHeight = max(lowerSize.height, upperSize.height)
        let maxSize = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: maxHeight))

        UIGraphicsBeginImageContextWithOptions(maxSize.size, false, receiver.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return receiver
        }
        defer { UIGraphicsEndImageContext() }

        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: maxSize.height)
        context.concatenate(verticalFlip)

        let lowerImageRect = CGRect(center: maxSize.center, size: lowerSize)
        context.draw(lower.cgImage!, in: lowerImageRect)

        let upperImageRect = CGRect(center: maxSize.center, size: upperSize)
        context.draw(upper.cgImage!, in: upperImageRect)

        guard let compositedImage = context.makeImage() else {
            return receiver
        }
        let newImage = UIImage(cgImage: compositedImage,
                               scale: receiver.scale,
                               orientation: receiver.imageOrientation)

        return newImage.withOptions(from: receiver)
    }

    /// Renders a copy of this image where all colors are inverted (typically white become black, blue becomes red and so on...).
    ///
    /// - returns: A `UIImage` where the colors are inverted.
    func colorInverted() -> UIImage {
        if let dynamic = _perColorTrait({ image, _ in image.colorInverted() }) {
            return dynamic
        }
        guard cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        let filter = CIFilter(name: "CIColorInvert")!
        filter.setDefaults()
        filter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)

        let context = CIContext.defaultWorkingSpace
        guard let ciOutput = filter.outputImage,
              let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            return self
        }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Renders an image where the alpha channel is the absolute differences between this image and an other (`abs(im0.a-im1.a)`).
    ///
    /// For two pixels located at the same coordinate:
    ///   - If both pixels are transparent, the result will be transparent.
    ///   - If a pixel is opaque in an image and transparent in the other, the result will be the opaque pixel.
    ///   - If both pixels are opaque, the result will be transparent.
    ///
    /// Size is important when doing the process, the default behaviour is to take the rect that emcompasses the two images (the smaller one will be then centered). In order to control the positioning of the images, do the scaling, cropping by yourself into one single coordinate space and size.
    ///
    /// - parameters:
    ///   - image: An other `UIImage`.
    /// - returns: The result of the alpha exclusion.
    func alphaExclusion(with image: UIImage) -> UIImage {
        if let dynamic = _perColorTrait(alsoVarying: image._colorTraitVariance, {
            $0.alphaExclusion(with: image._flattened(for: $1))
        }) {
            return dynamic
        }
        let filter = ExcludeFilter()
        guard self.cgImage != nil && image.cgImage != nil else {
            print(UIImage._ciImageErrorMessage)
            return self
        }

        // Both buffers are drawn raw, so they have to share an orientation, and the encompassing rect is measured in
        // that buffer space.
        let other = image._reoriented(to: imageOrientation)
        let thisSize = self._bufferSize
        let otherSize = other._bufferSize
        let maxSize = CGSize(
            width: max(thisSize.width, otherSize.width),
            height: max(thisSize.height, otherSize.height))
        let maxCenter = CGPoint(
            x: maxSize.width/2,
            y: maxSize.height/2)

        if let cgOutput = Self._alphaExcluded(first: self, second: other, filter: filter) {
            return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
        }

        UIGraphicsBeginImageContextWithOptions(maxSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        defer { UIGraphicsEndImageContext() }

        let verticalFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: maxSize.height)
        let inputFirstImageRect = CGRect(center: maxCenter, size: thisSize)
        let inputSecondImageRect = CGRect(center: maxCenter, size: otherSize)

        context.concatenate(verticalFlip)
        context.draw(self.cgImage!, in: inputFirstImageRect)
        guard let inputFirstImage = context.makeImage() else {
            return self
        }

        context.clear(CGRect(origin: .zero, size: maxSize))
        context.draw(other.cgImage!, in: inputSecondImageRect)
        guard let inputSecondImage = context.makeImage() else {
            return self
        }

        filter.inputFirstImage = CIImage(cgImage: inputFirstImage)
        filter.inputSecondImage = CIImage(cgImage: inputSecondImage)
        let ciContext = CIContext.rgbWorkingSpace

        guard let ciOutput = filter.outputImage,
              let cgOutput = ciContext.createCGImage(ciOutput, from: ciOutput.extent) else {
            return self
        }
        return UIImage(cgImage: cgOutput, scale: scale, orientation: imageOrientation).withOptions(from: self)
    }

    /// Invokes the given closure with the array of colors of this image.
    /// This function returns, if any, the result of the closure.
    func withBitmapAsUIColorArray<T>(_ handler: ([UIColor]) -> T?) -> T? {
        guard let cgImage else {
            print(UIImage._ciImageErrorMessage)
            return nil
        }
        return cgImage.withBitmapAsCGColorArray { cgColors in
            handler(cgColors.map { UIColor(cgColor: $0) })
        }
    }

    /// Returns an image which have all options (when application) of an other image.
    internal func withOptions(from other: UIImage) -> UIImage {
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

    /// Renders one expansion, whichever implementation is selected.
    ///
    /// The Metal kernel produces a buffer of exactly the requested size on its own, so it is handed back as it
    /// comes; only the two CPU implementations need a context to scatter their copies into, and it is created here
    /// rather than by the callers so that the GPU path does not pay for one it never draws into.
    ///
    /// - returns: The expanded buffer, or `nil` when no implementation could produce one.
    internal static func _expandedImpl(args: ExpandedArguments, cgImage: CGImage) -> CGImage? {
        if case .metal = _expandImplementation, let output = _expanded_metal(args: args, cgImage: cgImage) {
            return output
        }

        // Either a CPU implementation was asked for, or the compiled kernel is missing and falling back is better
        // than producing nothing.
        UIGraphicsBeginImageContextWithOptions(args.size, false, args.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        defer { UIGraphicsEndImageContext() }

        context.interpolationQuality = .default
        context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: args.size.height))

        if case .basic = _expandImplementation {
            _expanded_basic(args: args, context: context, cgImage: cgImage)
        } else {
            _expanded_concurrent(args: args, context: context, cgImage: cgImage)
        }
        return context.makeImage()
    }

}
