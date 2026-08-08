//
//  CGImageExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreGraphics
import Foundation

extension CGImage {

    /// A two dimensional unit to represent coordinates in an image.
    ///
    /// The x-axis is the `column` attribute and the y-axis the `row` attribute.
    /// Note that row 0 is the top as in a UIKit screen coordinate space.
    struct PixelCoordinate: Hashable {

        /// The X coordinate value
        var column: Int

        /// The Y coordinate value
        var row: Int

        /// Returns whether the coordinates is valid inside the given image.
        func isValid(in image: CGImage) -> Bool {
            let assertPositive = column >= 0 && row >= 0
            let assertInBounds = column < image.width && row < image.height
            return assertPositive && assertInBounds
        }

        /// Returns the index in the image bitmap array.
        func bitmapIndex(in image: CGImage) -> Int {
            return bitmapIndex(width: image.width)
        }

        /// Returns the index in an image bitmap array which have a given width.
        func bitmapIndex(width: Int) -> Int {
            return row * width + column
        }

        /// Returns the top left coordinate in the image which is always (0,0).
        static func topLeft(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: 0, row: 0)
        }

        /// Returns the top right coordinate in the image.
        static func topRight(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: image.width - 1, row: 0)
        }

        /// Returns the bottom left coordinate in the image.
        static func bottomLeft(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: 0, row: image.height - 1)
        }

        /// Returns the bottom right coordinate in the image.
        static func bottomRight(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: image.width - 1, row: image.height - 1)
        }
    }

    /// Returns the color at the specified coordinate.
    func color(at coordinate: PixelCoordinate) -> CGColor? {
        return colors(at: [coordinate])[0]
    }

    /// Returns an array of colors for the specified array of coordinates.
    /// Any input coordinate which is invalid will result in a nil element inserted at the same index.
    func colors(at coordinates: [PixelCoordinate]) -> [CGColor?] {
        guard !coordinates.isEmpty else {
            return []
        }
        let valid = coordinates.filter { $0.isValid(in: self) }
        guard let minColumn = valid.map({ $0.column }).min(),
              let maxColumn = valid.map({ $0.column }).max(),
              let minRow = valid.map({ $0.row }).min(),
              let maxRow = valid.map({ $0.row }).max() else {
            return coordinates.map { _ in nil }
        }

        // Only the region enclosing the requested coordinates has to be rendered, which keeps reading a single pixel
        // out of a large image cheap.
        let region = CGRect(x: minColumn, y: minRow, width: maxColumn - minColumn + 1, height: maxRow - minRow + 1)
        let cropped = cropping(to: region)
        let source = cropped ?? self
        let origin = cropped == nil
            ? PixelCoordinate(column: 0, row: 0)
            : PixelCoordinate(column: minColumn, row: minRow)

        return source.withBitmapBuffer { pixels in
            coordinates.map { coordinate in
                guard coordinate.isValid(in: self) else { return nil }
                let local = PixelCoordinate(column: coordinate.column - origin.column,
                                            row: coordinate.row - origin.row)
                return CGImage.color(fromPremultiplied: pixels[local.bitmapIndex(width: source.width)])
            }
        }
    }

    /// Invokes the given closure with the array of colors of this image.
    /// This function returns, if any, the result of the closure.
    func withBitmapAsCGColorArray<T>(_ handler: ([CGColor]) -> T) -> T {
        return withBitmapBuffer { pixels in
            handler(pixels.map { CGImage.color(fromPremultiplied: $0) })
        }
    }

    /// Invokes the given closure with the raw bitmap of this image, as one packed premultiplied RGBA value per pixel.
    /// This function returns the result of the closure.
    ///
    /// The buffer is only valid for the duration of the call, it must not escape the closure.
    internal func withBitmapBuffer<T>(_ handler: (UnsafeMutableBufferPointer<UInt32>) -> T) -> T {
        let colorSpace = CGColor.defaultRGBColorSpace
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let pointer = context.data?.assumingMemoryBound(to: UInt32.self) else {
            fatalError("Could not create CGContext to extract bitmap data")
        }
        context.draw(self, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        let pixels = UnsafeMutableBufferPointer<UInt32>(start: pointer, count: width * height)
        return handler(pixels)
    }

    /// Converts one packed premultiplied RGBA value into a straight alpha color.
    ///
    /// The bitmap stores color components already multiplied by their alpha, so they have to be divided back by it,
    /// otherwise a semi transparent pixel reports a color darker than the one it actually holds.
    internal static func color(fromPremultiplied pixel: UInt32) -> CGColor {
        let alpha = CGFloat(UInt8((pixel >> 0) & 255)) / 255
        guard alpha > 0 else {
            return CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        }
        let component: (UInt32) -> CGFloat = { shifted in
            min(CGFloat(UInt8(shifted & 255)) / 255 / alpha, 1.0)
        }
        return CGColor(srgbRed: component(pixel >> 24),
                       green: component(pixel >> 16),
                       blue: component(pixel >> 8),
                       alpha: alpha)
    }
}
