//
//  CGRectExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 11/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import CoreGraphics

// MARK: - CGRect extension

internal extension CGRect {

    var center: CGPoint {
        get {
            return CGPoint(x: midX, y: midY)
        }
        set {
            origin.x = newValue.x - (width / 2)
            origin.y = newValue.y - (height / 2)
        }
    }

    init(center: CGPoint, size: CGSize) {
        self.init(origin: .zero, size: size)
        self.center = center
    }
}
