//
//  CGImageExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

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
        return withBitmapAsCGColorArray { cgColors in
            coordinates.map { c in
                guard c.isValid(in: self) else { return nil }
                return cgColors[c.bitmapIndex(in: self)]
            }
        }
    }

    /// Invokes the given closure with the array of colors of this image.
    /// This function returns, if any, the result of the closure.
    func withBitmapAsCGColorArray<T>(_ handler: ([CGColor]) -> T) -> T {
        // guard width != 0 && height != 0 else {
        //     return nil
        // }
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

        let total = width * height
        let pixels = UnsafeMutableBufferPointer<UInt32>(start: pointer, count: Int(total))
        let colors = pixels.map { pixel in
            let r = CGFloat(UInt8((pixel >> 24) & 255)) / 255
            let g = CGFloat(UInt8((pixel >> 16) & 255)) / 255
            let b = CGFloat(UInt8((pixel >> 8) & 255)) / 255
            let a = CGFloat(UInt8((pixel >> 0) & 255)) / 255
            return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
        }

        return handler(colors)
    }
}
