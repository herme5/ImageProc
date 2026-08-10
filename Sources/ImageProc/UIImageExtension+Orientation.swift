//
//  UIImageExtension+Orientation.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 08/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

/// Every context in this library is filled with the raw `cgImage` buffer and the result is tagged with the receiver's
/// `imageOrientation` again, so the geometry has to be expressed in that buffer's space rather than in the displayed
/// one. The two only differ when the orientation is not `.up`, which is the common case for camera and photo library
/// images: they carry their rotation as an orientation instead of rotating their pixels.
internal extension UIImage {

    /// Whether the orientation exchanges the width and the height between the `cgImage` buffer and the displayed
    /// image, which is the case for the four quarter-turn orientations.
    var _orientationSwapsAxes: Bool {
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return true
        default:
            return false
        }
    }

    /// Whether the orientation mirrors the image, which reverses the direction a rotation appears to turn in.
    var _orientationIsMirrored: Bool {
        switch imageOrientation {
        case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored:
            return true
        default:
            return false
        }
    }

    /// The size of the `cgImage` buffer in points, which is `size` transposed for a quarter-turn orientation.
    var _bufferSize: CGSize {
        guard let cgImage else {
            return size
        }
        return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)) / scale
    }

    /// The orientation that undoes the given one. Every orientation is its own inverse but the two quarter-turns,
    /// which undo each other: the mirrored ones are a reflection, and `.down` is a half-turn.
    static func _inverseOrientation(_ orientation: UIImage.Orientation) -> UIImage.Orientation {
        switch orientation {
        case .left:
            return .right
        case .right:
            return .left
        default:
            return orientation
        }
    }

    /// Renders what this image displays into an `.up` buffer, so that its buffer and its displayed content match.
    func _orientationBaked() -> UIImage {
        guard imageOrientation != .up, cgImage != nil else {
            return self
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        // Drawing a template image paints a silhouette in the tint color, so the original has to be drawn instead.
        // The rendering mode is carried over by `withOptions(from:)` at the end of every operation anyway.
        let original = withRenderingMode(.alwaysOriginal)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            original.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Re-expresses this image's buffer in the coordinate space of the given orientation, leaving what it displays
    /// untouched. Two buffers can only be drawn raw into the same context when they share an orientation.
    ///
    /// - parameters:
    ///   - orientation: The orientation the returned image carries.
    /// - returns: An `UIImage` displaying the same thing, tagged with the given orientation.
    func _reoriented(to orientation: UIImage.Orientation) -> UIImage {
        guard imageOrientation != orientation, cgImage != nil else {
            return self
        }

        // Bake what is displayed, then un-apply the target orientation, so that tagging the result with it displays
        // that very same thing again.
        let displayed = _orientationBaked()
        guard orientation != .up, let displayedImage = displayed.cgImage else {
            return displayed
        }

        let undone = UIImage(cgImage: displayedImage,
                             scale: scale,
                             orientation: Self._inverseOrientation(orientation))
        guard let buffer = undone._orientationBaked().cgImage else {
            return displayed
        }
        return UIImage(cgImage: buffer, scale: scale, orientation: orientation)
    }

    /// Converts a rect expressed in the displayed coordinate space into the `cgImage` buffer one.
    ///
    /// - parameters:
    ///   - rect: A rect in the displayed coordinate space, in points.
    /// - returns: The same region, in the buffer coordinate space, in points.
    func _bufferRect(from rect: CGRect) -> CGRect {
        let buffer = _bufferSize
        let minX = rect.origin.x
        let minY = rect.origin.y
        let width = rect.size.width
        let height = rect.size.height

        switch imageOrientation {
        case .up:
            return rect
        case .upMirrored:
            return CGRect(x: buffer.width - minX - width, y: minY, width: width, height: height)
        case .down:
            return CGRect(x: buffer.width - minX - width, y: buffer.height - minY - height,
                          width: width, height: height)
        case .downMirrored:
            return CGRect(x: minX, y: buffer.height - minY - height, width: width, height: height)
        case .left:
            return CGRect(x: buffer.width - minY - height, y: minX, width: height, height: width)
        case .leftMirrored:
            return CGRect(x: minY, y: minX, width: height, height: width)
        case .right:
            return CGRect(x: minY, y: buffer.height - minX - width, width: height, height: width)
        case .rightMirrored:
            return CGRect(x: buffer.width - minY - height, y: buffer.height - minX - width,
                          width: height, height: width)
        @unknown default:
            return rect
        }
    }
}
