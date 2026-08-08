//
//  CGSizeExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreGraphics

internal func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

// internal func * (left: CGFloat, right: CGSize) -> CGSize {
//     return right * left
// }

internal func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}

// internal func *= (left: inout CGSize, right: CGFloat) {
//     left.width *= right
//     left.height *= right
// }

// internal func /= (left: inout CGSize, right: CGFloat) {
//     left.width /= right
//     left.height /= right
// }
