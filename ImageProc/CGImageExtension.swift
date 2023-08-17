//
//  CGImageExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 14/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import Foundation

extension CGImage {

    struct PixelCoordinate: Hashable {
        var column: Int
        var row: Int

        func isValid(in image: CGImage) -> Bool {
            let assertPositive = column >= 0 && row >= 0
            let assertInBounds = column < image.width && row < image.height
            return assertPositive && assertInBounds
        }

        func bitmapIndex(in image: CGImage) -> Int {
            return bitmapIndex(width: image.width)
        }

        func bitmapIndex(width: Int) -> Int {
            return width * row + column
        }

        static func topLeft(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: 0, row: 0)
        }

        static func topRight(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: image.width - 1, row: 0)
        }

        static func bottomLeft(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: 0, row: image.height - 1)
        }

        static func bottomRight(in image: CGImage) -> PixelCoordinate {
            return PixelCoordinate(column: image.width - 1, row: image.height - 1)
        }
    }

    func color(at pixelCoordinate: PixelCoordinate) -> CGColor? {
        if let result = colors(at: [pixelCoordinate]) {
            return result[0]
        }
        return nil
    }

    func colors(at pixelCoordinates: [PixelCoordinate]) -> [CGColor]? {
        let coords = pixelCoordinates.filter { $0.isValid(in: self) }
        guard !coords.isEmpty else {
            return nil
        }
        return withBitmapData { colors in
            return coords.map { coord in
                colors[coord.bitmapIndex(in: self)]
            }
        }
    }

    func withBitmapData<T>(_ handler: ([CGColor]) -> T?) -> T? {
        guard width != 0 && height != 0 else {
            return nil
        }
        let colorSpace = CGColor.defaultRGB
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
