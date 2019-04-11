//
//  ImageUtils.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 28/02/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

#if arch(i386) || arch(x86_64)
// No ColorFilter for ios simulator

#else
/// An image processor that produces an monochromatic image.
///
/// The ColorFilter class produces a CIImage object as output. The filter takes an image and a color as input.
///
/// Unless you are sure to reject all the original colors, it is recommended to use a monochromatic shape image as input to modify that one color footprint, (for example, giving a full opaque image will just result in a square colorized with the color input).
///
/// Note that the input color alpha component is taken into account to produce a more transparent (and always more transparent) image.
///
/// To use MSL as the shader language for a CIKernel, you must specify some options in Xcode under the Build Settings tab of your project's target. The first option you need to specify is an -fcikernel flag in the Other Metal Compiler Flags option. The second is to add a user-defined setting with a key called MTLLINKER_FLAGS with a value of -cikernel.
fileprivate class ColorFilter: CIFilter {
    
    /// The original input image as a `CIImage`.
    var inputImage: CIImage?
    
    /// The input color as a `CIColor`.
    var inputColor: CIColor?
    
    /// The GPU-based routine that performs the colorizing algorithm.
    private let kernel: CIColorKernel!
    
    /// Initializes a color filter object.
    /// - parameters:
    ///   - string: The color code must be prefixed by "#" and followed by 6 hexadecimal digits.
    ///   - alpha: The value of the alpha component specified between `0.0` and `1.0`.
    override init() {
        let url = Bundle(for: ColorFilter.self).url(forResource: "ColorFilter", withExtension: "metallib")!
        let data = try! Data(contentsOf: url)

        do {
            kernel = try CIColorKernel(functionName: "colorize", fromMetalLibraryData: data)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The output image produced by the original image colorized with the input color.
    override var outputImage: CIImage? {
        guard let inputImage = self.inputImage, let inputColor = self.inputColor else { return nil }
        
        let inputs = [inputImage, inputColor] as [Any]
        return kernel.apply(extent: inputImage.extent, arguments: inputs)
    }
}
#endif

public extension UIImage {
    
    var sizeInPixel: CGSize { return size * scale }
    
#if arch(i386) || arch(x86_64)
    func colorized(with color: UIColor) -> UIImage {
        return self
    }
#else
    /// Renders a copy of this image where all opaque pixel have their color replaced by the given one.
    /// - parameters:
    ///   - color: The color to apply as a mask.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    func colorized(with color: UIColor) -> UIImage {
        guard let cgInput = self.cgImage else { return self }
        
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgInput)
        colorFilter.inputColor = CIColor(color: color)
        
        if let ciOutput = colorFilter.outputImage {
            let context = CIContext(options: nil)
            let cgOutput = context.createCGImage(ciOutput, from: ciOutput.extent)
            return UIImage(cgImage: cgOutput!, scale: self.scale, orientation: self.imageOrientation).withAlphaComponent(color.rgba.alpha).withRenderingMode(self.renderingMode)
        }
        return self
    }
#endif
    
    /// Renders copy of this image where all opaque boundaries pixels are replicated all around the origin.
    /// - parameters:
    ///   - size: The distance in pixel.
    ///   - degree: Defines all the directions to where one pixel have to be replicated.
    /// - returns: An `UIImage` where all opaque pixels are colored.
    fileprivate func expand(size: CGFloat, each degree: CGFloat = 10) -> UIImage {
        let oldRect = CGRect(x: size, y: size, width: self.size.width, height: self.size.height).integral
        let newSize = CGSize(width: self.size.width + (2*size), height: self.size.height + (2*size))
        let translationVector = CGVector(dx: size, dy: 0)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            for angle in stride(from: CGFloat(0), to: CGFloat(360), by: degree) {
                let vector = translationVector.rotated(around: .zero, byDegrees: angle)
                context.concatenate(CGAffineTransform(translationX: vector.dx, y: vector.dy))
                context.draw(self.cgImage!, in: oldRect)
                context.concatenate(CGAffineTransform(translationX: -vector.dx, y: -vector.dy))
            }
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: self.scale, orientation: self.imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Renders a copy of this image with a border along the opaque region of this image. It is recommended to use it with images that have a transparent background.
    /// - parameters:
    ///   - color: The border color.
    ///   - size: The border size.
    ///   - alpha: The border transparency.
    /// - returns: An `UIImage` where the opaque region is surrounded by a border.
    func stroked(with color: UIColor, size: CGFloat, alpha: CGFloat = 1) -> UIImage {
        let expandedImage = self.colorized(with: color).expand(size: size).withAlphaComponent(alpha)
        let oldSize = CGSize(width: self.size.width, height: self.size.height)
        let newSize = CGSize(width: self.size.width + (2*size), height: self.size.height + (2*size))
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            
            let strokeRect = CGRect(origin: CGPoint(x: 0, y: 0), size: newSize)
            context.draw(expandedImage.cgImage!, in: strokeRect)
            
            context.scaleBy(x: 1.0, y: -1.0)
            let originRect = CGRect(origin: CGPoint(x: size, y: -size - oldSize.height), size: oldSize)
            context.draw(self.cgImage!, in: originRect)
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: self.scale, orientation: self.imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Renders a a smoothened copy of this image with a gaussian blur given a radius measured in point. The output image can be larger by the radius to prevent cropping.
    /// - parameters:
    ///   - radius: The blur radius in point.
    ///   - sizeKept: Whether the output image should keep the same size as before, or its size is increased by radius so that we are sure the blur effect can exceed the initial size.
    /// - returns: A smoothened `UIImage`.
    func smoothened(by radius: CGFloat, sizeKept: Bool = false) -> UIImage {
        guard let cgInput = self.cgImage else {
            print("[IOS] UIImage.smoothened(by:,sizeKept:): \(self) has no cgImage attribute.")
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
            let cgImg = context.createCGImage(ciOutputImage, from: rect)
            
            return UIImage(cgImage: cgImg!, scale: self.scale, orientation: self.imageOrientation).withRenderingMode(self.renderingMode)
        } else {
            print("[IOS] UIImage.smoothened(by:,sizeKept:): failed to apply gaussian blur to \(self)")
            return self
        }
    }
    
    /// Renders a more transparent copy of this image.
    /// - parameters:
    ///   - value: The maximum alpha component value of the rendered image.
    /// - returns: A more transparent `UIImage`.
    func withAlphaComponent(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("[IOS] alpha: failed to apply alpha filter for \(self)")
            UIGraphicsEndImageContext()
            return self
        }
        UIGraphicsEndImageContext()
        return newImage.withRenderingMode(self.renderingMode)
    }
    
    /// Renders a scaled copy of this image given a new size in points.
    /// - parameters:
    ///   - newSize: The new size of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaled(to newSize: CGSize) -> UIImage {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.interpolationQuality = .high
            context.concatenate(flipVertical)
            context.draw(self.cgImage!, in: newRect)
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: self.scale, orientation: self.imageOrientation)
            UIGraphicsEndImageContext()
            
            //let horizontalRatio = newSize.width / self.size.width
            //let verticalRatio = newSize.height / self.size.height
            //let newCapInsets = UIEdgeInsetsMake(verticalRatio * self.capInsets.top,
            //                                    horizontalRatio * self.capInsets.left,
            //                                    verticalRatio * self.capInsets.bottom,
            //                                    horizontalRatio * self.capInsets.right)
            
            return newImage.withRenderingMode(self.renderingMode)/*.resizableImage(withCapInsets: newCapInsets, resizingMode: self.resizingMode)*/
        }
        UIGraphicsEndImageContext()
        return self
    }
    
    /// Renders a scaled copy of this image given a new width in points, the height is computed so that aspect ratio is kept to 1:1.
    /// - parameters:
    ///   - newWidth: The new width of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledWidth(to newWidth: CGFloat, keepAspectRatio: Bool = true) -> UIImage {
        let oldHeight = self.size.height
        if keepAspectRatio {
            let oldWidth = self.size.width
            let factor = newWidth / oldWidth
            let newHeight = oldHeight * factor
            return scaled(to: CGSize(width: newWidth, height: newHeight))
        }
        else {
            return scaled(to: CGSize(width: newWidth, height: oldHeight))
        }
    }
    
    /// Renders a scaled copy of this image given a new height in points, the width is computed so that aspect ratio is kept to 1:1.
    /// - parameters:
    ///   - newHeight: The new height of the output image.
    /// - returns: A sclaed `UIImage`.
    func scaledHeight(to newHeight: CGFloat, keepAspectRatio: Bool = true) -> UIImage {
        let oldWidth = self.size.width
        if keepAspectRatio {
            let oldHeight = self.size.height
            let factor = newHeight / oldHeight
            let newWidth = oldWidth * factor
            return scaled(to: CGSize(width: newWidth, height: newHeight))
        }
        else {
            return scaled(to: CGSize(width: oldWidth, height: newHeight))
        }
    }
    
    /// Crops and return a copy of this image given a new rect, note that if the original image is resizable, the capInsets are lost.
    /// - parameters:
    ///   - rect: The new rect to which the image will be cropped.
    /// - returns: A cropped `UIImage`.
    func cropped(to rect: CGRect) -> UIImage {
        let contextRect = CGRect(origin: rect.origin * self.scale, size: rect.size * self.scale)
        guard let cgImage = self.cgImage, let cropped = cgImage.cropping(to: contextRect) else { return self }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: self.imageOrientation).withRenderingMode(self.renderingMode)/*.resizableImage(withCapInsets: .zero, resizingMode: self.resizingMode)*/
    }
    
    /// Crops and return a copy of this image, note that if the original image is resizable, the capInsets are lost.
    /// - parameters:
    ///   - rect: The new rect to which the image will be cropped.
    /// - returns: A cropped `UIImage`.
    func rotated(by degrees: CGFloat, flip: Bool = false) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = { return $0 / 180.0 * CGFloat.pi }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            
            // Move the origin to the middle of the image so we will rotate and scale around the center.
            context.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
            context.rotate(by: degreesToRadians(degrees))
            
            // Now, draw the rotated/scaled image into the context
            context.scaleBy(x: (flip ? -1.0 : 1.0), y: -1.0)
            context.draw(self.cgImage!, in: CGRect(x: -size.width  / 2, y: -size.height / 2, width: size.width, height: size.height))
            
            let newImage = UIImage(cgImage: context.makeImage()!, scale: self.scale, orientation: self.imageOrientation)
            UIGraphicsEndImageContext()
            return newImage.withRenderingMode(self.renderingMode)
        }
        UIGraphicsEndImageContext()
        return self
    }
}
