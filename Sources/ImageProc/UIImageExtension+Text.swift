//
//  UIImageExtension+Text.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 08/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit

public extension UIImage {

    /// Renders the given attributed text into an image.
    ///
    /// - parameters:
    ///   - text: The text to draw, carrying its own attributes.
    ///   - size: The size of the image to return. Defaults to the size the text needs.
    /// - returns: An `UIImage` of the drawn text, or `nil` if the resulting size is empty.
    convenience init?(text: NSAttributedString, size: CGSize? = nil) {
        let size = size ?? text.size()
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let rendered = UIGraphicsImageRenderer(size: size).image { _ in
            text.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cgImage = rendered.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage, scale: rendered.scale, orientation: rendered.imageOrientation)
    }

    /// Renders the given text into an image using the specified attributes.
    ///
    /// - parameters:
    ///   - text: The text to draw.
    ///   - attributes: The attributes to draw the text with. Default is `nil`.
    ///   - size: The size of the image to return. Defaults to the size the text needs.
    /// - returns: An `UIImage` of the drawn text, or `nil` if the resulting size is empty.
    convenience init?(text: String,
                      attributes: [NSAttributedString.Key: Any]? = nil,
                      size: CGSize? = nil) {
        self.init(text: NSAttributedString(string: text, attributes: attributes), size: size)
    }
}
