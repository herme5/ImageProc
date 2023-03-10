//
//  CGPointExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreGraphics

// MARK: - CGPoint operator overloading

// internal func + (left: CGPoint, right: CGPoint) -> CGPoint {
//     return CGPoint(x: left.x + right.x, y: left.y + right.y)
// }

// internal func - (left: CGPoint, right: CGPoint) -> CGPoint {
//     return CGPoint(x: left.x - right.x, y: left.y - right.y)
// }

internal func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

// internal func * (left: CGFloat, right: CGPoint) -> CGPoint {
//     return right * left
// }

// internal func / (left: CGPoint, right: CGFloat) -> CGPoint {
//     return CGPoint(x: left.x / right, y: left.y / right)
// }

// internal func += (left: inout CGPoint, right: CGPoint) {
//     left.x += right.x
//     left.y += right.y
// }

// internal func -= (left: inout CGPoint, right: CGPoint) {
//     left.x -= right.x
//     left.y -= right.y
// }

// internal func *= (left: inout CGPoint, right: CGFloat) {
//     left.x *= right
//     left.y *= right
// }

// internal func /= (left: inout CGPoint, right: CGFloat) {
//     left.x /= right
//     left.y /= right
// }

// internal prefix func - (point: CGPoint) -> CGPoint {
//     return CGPoint(x: -point.x, y: -point.y)
// }
