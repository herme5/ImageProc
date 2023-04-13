//
//  StringExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import Foundation

// MARK: - String extension

internal extension String {

    subscript (index: Int) -> Character {
        return self[self.index(startIndex, offsetBy: index)]
    }

    subscript (range: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: range.lowerBound)
        return self[start ..< endIndex]
    }

    subscript (range: Range<Int>) -> String {
        return String(self[range] as Substring)
    }
}

public extension String {
    
    /// Generates a `UIImage` instance from this string using a specified
    /// attributes and size.
    ///
    /// - Parameters:
    ///     - attributes: to draw this string with. Default is `nil`.
    ///     - size: of the image to return.
    /// - Returns: a `UIImage` instance from this string using a specified
    /// attributes and size, or `nil` if the operation fails.
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(in: CGRect(origin: .zero, size: size), withAttributes: attributes)
        }
    }
}
