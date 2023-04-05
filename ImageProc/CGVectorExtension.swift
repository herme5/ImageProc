//
//  CGVectorExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import CoreGraphics

// MARK: - CGVector extension

internal extension CGVector {

    func rotated(around origin: CGPoint, byDegrees: CGFloat) -> CGVector {
        // swiftlint:disable identifier_name
        let tx = dx - origin.x
        let ty = dy - origin.y

        let radius = sqrt(tx * tx + ty * ty)
        let azimuth = atan2(ty, tx)
        let newAzimuth = azimuth + (byDegrees * CGFloat.pi / 180.0)

        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)

        return CGVector(dx: x, dy: y)
    }
}
