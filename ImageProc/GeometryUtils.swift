//
//  GeometryUtils.swift
//  Anagram
//
//  Created by Andrea Ruffino on 11/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit

extension CGRect {
    
    var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
        set {
            self.origin.x = newValue.x - (width / 2)
            self.origin.y = newValue.y - (height / 2)
        }
    }
    
    init(center: CGPoint, size: CGSize) {
        self.init(origin: .zero, size: size)
        self.center = center
    }
}

internal extension CGVector {
    
    func rotated(around origin: CGPoint, byDegrees: CGFloat) -> CGVector {
        let tx = self.dx - origin.x
        let ty = self.dy - origin.y
        let radius = sqrt(tx * tx + ty * ty)
        let azimuth = atan2(ty, tx) // in radians
        let newAzimuth = azimuth + (byDegrees * CGFloat.pi / 180.0) // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGVector(dx: x, dy: y)
    }
}

// MARK: - CGPoint operator overloading

internal func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

internal func * (left: CGFloat, right: CGPoint) -> CGPoint {
    return right * left
}

internal func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

internal func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

internal func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

internal func += (left: inout CGPoint, right: CGPoint) {
    left.x = left.x + right.x
    left.y = left.y + right.y
}

internal func -= (left: inout CGPoint, right: CGPoint) {
    left.x = left.x - right.x
    left.y = left.y - right.y
}

internal func *= (left: inout CGPoint, right: CGFloat) {
    left = left * right
}

internal func /= (left: inout CGPoint, right: CGFloat) {
    left = left / right
}

internal prefix func - (point: CGPoint) -> CGPoint {
    return CGPoint(x: -point.x, y: -point.y)
}

// MARK: - CGSize operator overloading

internal func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

internal func * (left: CGFloat, right: CGSize) -> CGSize {
    return right * left
}

internal func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}

internal func *= (left: inout CGSize, right: CGFloat) {
    left = left * right
}

internal func /= (left: inout CGSize, right: CGFloat) {
    left = left / right
}
