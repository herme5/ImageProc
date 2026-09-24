//
//  Pixels.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
@testable import ImageProc

/// How far apart two renders may be, in units of 255, before they count as different.
enum Tolerance {

    /// Two renders of the same content that took different paths round to 8 bits a different number of times, or
    /// resample differently. One unit of that is unavoidable; more than two means something else moved.
    static let rounding = 2

    /// A step converting through Core Image's linear working space magnifies the 8-bit rounding of the steps before
    /// it: measured at 4 units, everywhere on the image and also once composited over an opaque background.
    static let linearSpace = 5

    /// `.concurrent` composites its layers in whatever order they finish, so it does not reproduce itself either: two
    /// direct calls measured 3 units apart.
    static let concurrentExpansion = 5
}

/// One pixel, as premultiplied 8-bit sRGB components.
struct Pixel: Equatable, CustomStringConvertible {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8

    static let clear = Pixel(red: 0, green: 0, blue: 0, alpha: 0)

    /// The pixel an opaque color renders to.
    init(_ color: UIColor) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.resolvedColor(with: TraitEnvironment.traits(.light)).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let byte: (CGFloat) -> UInt8 = { UInt8((min(max($0 * alpha, 0), 1) * 255).rounded()) }
        self.init(red: byte(red), green: byte(green), blue: byte(blue), alpha: UInt8((alpha * 255).rounded()))
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// The largest difference between two components.
    func distance(to other: Pixel) -> Int {
        return [Int(red) - Int(other.red), Int(green) - Int(other.green),
                Int(blue) - Int(other.blue), Int(alpha) - Int(other.alpha)].map(abs).max()!
    }

    var description: String {
        return String(format: "#%02X%02X%02X/%02X", red, green, blue, alpha)
    }
}

/// The pixels of an image's `cgImage` buffer, redrawn into premultiplied 8-bit sRGB whatever its own format is, so
/// that any two images can be compared byte for byte.
///
/// This is the buffer, not what is displayed: for an image with a non-`.up` orientation, bake it first.
struct Bitmap {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init?(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            return nil
        }
        width = cgImage.width
        height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: cgImage.width, height: cgImage.height,
                                          bitsPerComponent: 8, bytesPerRow: cgImage.width * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            return true
        }
        guard drawn else {
            return nil
        }
        bytes = buffer
    }

    /// The pixel at a column and a row, from the top left.
    subscript(column: Int, row: Int) -> Pixel {
        let index = (row * width + column) * 4
        return Pixel(red: bytes[index], green: bytes[index + 1], blue: bytes[index + 2], alpha: bytes[index + 3])
    }

    /// The pixel at a position given as a fraction of the width and the height, so that the point stays meaningful
    /// whatever an operation did to the size.
    subscript(relative point: CGPoint) -> Pixel {
        let column = min(Int(CGFloat(width) * point.x), width - 1)
        let row = min(Int(CGFloat(height) * point.y), height - 1)
        return self[column, row]
    }

    static let center = CGPoint(x: 0.5, y: 0.5)

    /// The alpha of every pixel, row major.
    var alphas: [UInt8] {
        return stride(from: 3, to: bytes.count, by: 4).map { bytes[$0] }
    }

    /// The largest difference between two components of two same-sized bitmaps, or nil when the sizes differ.
    func distance(to other: Bitmap) -> Int? {
        guard width == other.width, height == other.height else {
            return nil
        }
        return zip(bytes, other.bytes).map { abs(Int($0) - Int($1)) }.max() ?? 0
    }
}

extension UIImage {

    /// The image as it is displayed, rendered into an `.up` buffer.
    var baked: UIImage {
        return Fixture.render(size: size, scale: scale) { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// The pixels of the image as it is displayed.
    var displayedBitmap: Bitmap? {
        return Bitmap(baked)
    }
}

/// Describes the first difference between how two images display, or returns nil when they display the same.
///
/// Sizes are compared exactly. Pixels are sampled on a grid rather than exhaustively: a misplacement moves whole
/// regions, and sampling keeps the orientation matrix, which compares hundreds of pairs, fast.
func displayMismatch(_ lhs: UIImage, _ rhs: UIImage, tolerance: Int = Tolerance.rounding) -> String? {
    guard lhs.size == rhs.size else {
        return "size \(lhs.size) vs \(rhs.size)"
    }
    guard let left = lhs.displayedBitmap, let right = rhs.displayedBitmap else {
        return "no bitmap"
    }
    guard left.width == right.width, left.height == right.height else {
        return "buffer \(left.width)x\(left.height) vs \(right.width)x\(right.height)"
    }

    let steps = 7
    for row in 1..<steps {
        for col in 1..<steps {
            let column = left.width * col / steps, line = left.height * row / steps
            let lhsPixel = left[column, line], rhsPixel = right[column, line]
            if lhsPixel.distance(to: rhsPixel) > tolerance {
                return "pixel (\(column),\(line)) \(lhsPixel) vs \(rhsPixel)"
            }
        }
    }
    return nil
}

/// Describes how two images differ pixel for pixel, including their geometry, or returns nil when they match.
func mismatch(_ lhs: UIImage, _ rhs: UIImage, tolerance: Int = Tolerance.rounding) -> String? {
    if lhs.size != rhs.size {
        return "size \(lhs.size) vs \(rhs.size)"
    }
    if lhs.scale != rhs.scale {
        return "scale \(lhs.scale) vs \(rhs.scale)"
    }
    if lhs.imageOrientation != rhs.imageOrientation {
        return "orientation \(lhs.imageOrientation.rawValue) vs \(rhs.imageOrientation.rawValue)"
    }
    guard let left = Bitmap(lhs), let right = Bitmap(rhs) else {
        return "no bitmap"
    }
    guard let distance = left.distance(to: right) else {
        return "buffer \(left.width)x\(left.height) vs \(right.width)x\(right.height)"
    }
    return distance > tolerance ? "components differ by \(distance)" : nil
}
