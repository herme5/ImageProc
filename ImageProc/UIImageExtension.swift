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
    
    /// Renders a copy of this image where all opaque pixels have their color replaced by pixels of the given color.
    ///
    /// - parameters:
    ///   - color: The color to apply as a mask.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func colorized(with color: UIColor, method: OptimizationMethod = .concurrent) -> UIImage {
        var filter: CIFilter!
        
        switch method {
        case .basic:
            let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
            let inputColor = CIColor(cgColor: color.cgColor)
            
            // Throw away existing colors, and fill the non transparent pixels with the input color
            // s.r = dot(s, redVector), s.g = dot(s, greenVector), s.b = dot(s, blueVector), s.a = dot(s, alphaVector)
            // s = s + bias
            colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
            colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
            colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
            colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
            colorMatrixFilter.setValue(CIVector(x: inputColor.red, y: inputColor.green, z: inputColor.blue, w: 0), forKey: "inputBiasVector")
            colorMatrixFilter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)
            
            // Down casting ColorFilter to CIFilter to finalize drawing
            filter = colorMatrixFilter
            
        case .concurrent:
            // Throw away existing color, and fill the non transparent pixels with the input color
            let colorFilter = ColorFilter()
            colorFilter.inputImage = CIImage(cgImage: self.cgImage!)
            colorFilter.inputColor = CIColor(color: color)
            
            // Down casting ColorFilter to CIFilter to finalize drawing
            filter = colorFilter
        }
        
        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
        guard let ciOutput = filter.outputImage, let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            return self
        }
        return UIImage(cgImage: cgOutput, scale: self.scale, orientation: self.imageOrientation).withAlphaComponent(color.rgba.alpha).withRenderingMode(self.renderingMode)
    }
    
    private static var _cachedRangeDegree = CGFloat(2)
    private static var _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
    private static var _cachedRange = _cachedRangeStride.map { $0 }
    private static func _setupCachedRange(_ degree : CGFloat) {
        if degree != _cachedRangeDegree {
            _cachedRangeDegree = degree
            _cachedRangeStride = stride(from: CGFloat(0.0), to: CGFloat(360), by: _cachedRangeDegree)
            _cachedRange = _cachedRangeStride.map { $0 }
        }
    }
    
    /// Renders copy of this image where all opaque pixels are replicated all around the origin. This make an opaque shape bigger in more or less all direction. The degree parameters must be a step iteration between 0 and 360.
    ///
    /// E.g.: Given a degree equals to 90, the method will iterate each 90 degree from 0 to 360 (exluding 360), resulting in 4 iterations: 0, 90, 180 and 270, resulting in an image where replications is drawn at the top, bottom, left and right directions.
    ///
    /// Otherwise given a degree parameter equels to 1, the method will iterate each 1 degree from 0 to 360, resulting in 360 iterations and making the interpolation much better.
    ///
    /// - parameters:
    ///   - size: The distance in pixel.
    ///   - degree: Defines the direction iteration step to where the image have to be replicated.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func expand(bySize s: CGFloat, each degree: CGFloat = 2, method: OptimizationMethod = .concurrent) -> UIImage {
        let oldRect = CGRect(x: s, y: s, width: size.width, height: size.height).integral
        let newSize = CGSize(width: size.width + (2 * s), height: size.height + (2 * s))
        let translationVector = CGVector(dx: s, dy: 0)
        let verticalFlipTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        let interpQuality = CGInterpolationQuality.default
        UIImage._setupCachedRange(degree)
        
        guard let original = cgImage else {
            return self
        }
        
        // Create the final output context (only one will be used if basic optimisation)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = interpQuality
            context.concatenate(verticalFlipTransform)
            let range = UIImage._cachedRangeStride
            
            switch method {
            case .basic:
                // Perform a translatation transform in each direction so that the context draw the shape shifted all around the original position. Remember to perform the inverse translation for next iteration.
                for angle in range {
                    let vector = translationVector.rotated(around: .zero, byDegrees: angle)
                    context.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
                    context.draw(original, in: oldRect)
                    context.concatenate(CGAffineTransform(translationX: -vector.dx, y: -vector.dy))
                }
                
            case .concurrent:
                // Prepare a barrier queue to fetch back thread-unsafe properties.
                let concurrentExpandMethodQueue = DispatchQueue(
                    label: "fr.andrearuffino.ImageProc.expandMethodQueue",
                    attributes: .concurrent)
                let angles = UIImage._cachedRange
                
                // Think about the iterations as layers (or images) that will be drawn at the end.
                var unsafeLayers = [CGImage]()
                unsafeLayers.reserveCapacity(angles.count)
                
                // Use concurrentPerform method to let the native API manage the parallelism.
                DispatchQueue.concurrentPerform(iterations: angles.count) { i in
                    let vector = translationVector.rotated(around: .zero, byDegrees: angles[i])
                    
                    // Create new context just for the layer.
                    UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
                    if let layerContext = UIGraphicsGetCurrentContext() {
                        
                        // Apply the same property as output context
                        layerContext.interpolationQuality = interpQuality
                        layerContext.concatenate(verticalFlipTransform)
                        
                        // Perform a translatation transform in the right direction and save it for drawing later. Here we don't need to perform inverse translation as we are not working on the final output context.
                        layerContext.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
                        layerContext.draw(original, in: oldRect)
                        concurrentExpandMethodQueue.sync(flags: .barrier) {
                            unsafeLayers.append(layerContext.makeImage()!)
                        }
                    }
                    UIGraphicsEndImageContext()
                }
                // Perform the drawing of all the layer we have concurently processed
                for layer in unsafeLayers {
                    context.draw(layer, in: CGRect(origin: .zero, size: newSize))
                }
            }
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Renders a copy of this image with a border along the opaque region of this image.
    ///
    /// - parameters:
    ///   - color: The border color.
    ///   - size: The border size.
    ///   - alpha: The border transparency.
    /// - returns: An `UIImage` where the opaque region is surrounded by a border.
    func stroked(with color: UIColor, size s: CGFloat, each degree: CGFloat = 2, alpha: CGFloat = 1) -> UIImage {
        let strokeImage = self.colorized(with: color).expand(bySize: s, each: degree).withAlphaComponent(alpha)
        return self.drawnAbove(image: strokeImage)
    }
    
    /// Renders a a smoothened copy of this image with a gaussian blur given a radius measured in point. Most the of the time the output image will be larger than the source image.
    ///
    /// - parameters:
    ///   - radius: The blur radius in point.
    ///   - sizeKept: Whether the output image should keep the same size as before, or its size is increased by radius so that we are sure the blur effect can exceed the initial size.
    /// - returns: A smoothened `UIImage`.
    func smoothened(by radius: CGFloat, sizeKept: Bool = false) -> UIImage {
        guard let cgInput = self.cgImage else {
            return self
        }
        
        // smoothen the image with a gaussian blur
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")!
        gaussianFilter.setValue(radius, forKey: kCIInputRadiusKey)
        gaussianFilter.setValue(CIImage(cgImage: cgInput), forKey: kCIInputImageKey)
        
        if let ciOutputImage = gaussianFilter.outputImage {
            // gaussian filter can increase the image, thus we resize it to initial
            let rect = sizeKept ? CGRect(origin: .zero, size: sizeInPixel) : ciOutputImage.extent
            let context = CIContext(options: nil)
            
            if let cgImg = context.createCGImage(ciOutputImage, from: rect) {
                let newImage = UIImage(cgImage: cgImg, scale: scale, orientation: imageOrientation)
                return newImage.withRenderingMode(renderingMode)
            }
            else {
                return self
            }
        }
        return self
    }
    
    /// Renders a more transparent copy of this image.
    ///
    /// - parameters:
    ///   - value: The maximum alpha component value of the rendered image.
    /// - returns: A more transparent `UIImage`.
    func withAlphaComponent(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: value)
        
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return self
        }
        UIGraphicsEndImageContext()
        return newImage.withRenderingMode(renderingMode)
    }
    
    /// Renders a scaled copy of this image given a new size in points.
    ///
    /// - parameters:
    ///   - newSize: The new size of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaled(to newSize: CGSize) -> UIImage {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.interpolationQuality = .high
            context.concatenate(flipVertical)
            context.draw(cgImage!, in: newRect)
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
            UIGraphicsEndImageContext()
            
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Renders a scaled copy of this image given a new width in points, the height is computed so that aspect ratio is
    /// kept to 1:1.
    ///
    /// - parameters:
    ///   - newWidth: The new width of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledWidth(to newWidth: CGFloat, keepAspectRatio: Bool = true) -> UIImage {
        let newHeight = keepAspectRatio ? size.height * (newWidth / size.width) : size.height
        return scaled(to: CGSize(width: newWidth, height: newHeight))
    }
    
    /// Renders a scaled copy of this image given a new height in points, the width is computed so that aspect ratio is
    /// kept to 1:1.
    ///
    /// - parameters:
    ///   - newHeight: The new height of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledHeight(to newHeight: CGFloat, keepAspectRatio: Bool = true) -> UIImage {
        let newWidth = keepAspectRatio ? size.width * (newHeight / size.height) : size.width
        return scaled(to: CGSize(width: newWidth, height: newHeight))
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
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation).withRenderingMode(renderingMode)
    }
    
    /// Rotates and returns a copy of this image given an angle in degrees.
    ///
    /// - parameters:
    ///   - degrees: the clockwise angle to which the image has to be rotated.
    ///   - flip: boolean that indicate if the image should be flipped in the zero degree direction axis after the rotation.
    /// - returns: A rotated `UIImage`.
    func rotated(by degrees: CGFloat) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = { return $0 / 180.0 * CGFloat.pi }
        
        // Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size * scale
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            
            // Move the origin to the middle of the image so we will rotate and scale around the center.
            context.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
            context.rotate(by: degreesToRadians(degrees))
            
            // Now, draw the rotated/scaled image into the context
            // Remember to replace the center
            context.scaleBy(x: 1.0, y: -1.0)
            context.draw(cgImage!, in: CGRect(x: -sizeInPixel.width  / 2, y: -sizeInPixel.height / 2, width: sizeInPixel.width, height: sizeInPixel.height))
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Flips along X and returns a copy of this image.
    ///
    /// - returns: A horizontally flipped `UIImage`.
    func flippedHorizontally() -> UIImage {
        UIGraphicsBeginImageContext(sizeInPixel)
        if let context = UIGraphicsGetCurrentContext() {
            
            // Transform that flips x (and also y, because CGContexts are y inverted by default)
            let t = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: sizeInPixel.width, ty: sizeInPixel.height)
            context.concatenate(t)
            context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: sizeInPixel.width, height: sizeInPixel.height))
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Flips along Y and returns a copy of this image.
    ///
    /// - returns: A vertically flipped `UIImage`.
    func flippedVertically() -> UIImage {
        UIGraphicsBeginImageContext(sizeInPixel)
        if let context = UIGraphicsGetCurrentContext() {
            
            // No transform because CGContexts are y inverted by default
            context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: sizeInPixel.width, height: sizeInPixel.height))
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: scale, orientation: imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Overlays this image under another image and returns a copy of the two images combined.
    ///
    /// - returns: A `UIImage` where this image is under the other.
    func drawnUnder(image: UIImage) -> UIImage {
        let maxWidth = max(self.size.width, image.size.width)
        let maxHeight = max(self.size.height, image.size.height)
        let maxSize = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: maxHeight))
        
        UIGraphicsBeginImageContextWithOptions(maxSize.size, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            let t = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: maxSize.height)
            context.concatenate(t)
            context.interpolationQuality = .high
            
            let imRect_0 = CGRect(center: maxSize.center, size: self.size)
            context.draw(self.cgImage!, in: imRect_0)
            
            let imRect_1 = CGRect(center: maxSize.center, size: image.size)
            context.draw(image.cgImage!, in: imRect_1)
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: self.scale, orientation: self.imageOrientation)
            UIGraphicsEndImageContext()
            
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Overlays this image above another image and returns a copy of the two images combined.
    ///
    /// - returns: A `UIImage` where this image is above the other.
    func drawnAbove(image: UIImage) -> UIImage {
        return image.drawnUnder(image: self)
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
