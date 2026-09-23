//
//  UIImageExtension+AlphaExclusion.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 22/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreImage

internal extension UIImage {

    /// Excludes the two buffers without materializing either input.
    ///
    /// The Core Graphics path this replaces centers the two images by drawing each into a full size context and
    /// reading it back, which is two bitmaps and two draws before the GPU sees anything. A `CIImage` carries its own
    /// extent, so the same centering is a translation on the recipe and costs nothing.
    ///
    /// - returns: The excluded buffer, or `nil` when the two images cannot be centered on a pixel boundary, which
    ///            sends the caller back to the Core Graphics path rather than resampling one of them here.
    static func _alphaExcluded(first: UIImage, second: UIImage, filter: ExcludeFilter) -> CGImage? {
        guard let firstImage = first.cgImage, let secondImage = second.cgImage else {
            return nil
        }
        // The Core Graphics path positions the two in points and rasterizes at the receiver's scale, which resamples
        // the other image when the scales differ. Nothing is gained by reproducing that here.
        guard first.scale == second.scale else {
            return nil
        }

        let width = max(firstImage.width, secondImage.width)
        let height = max(firstImage.height, secondImage.height)

        // Centering an odd difference would land the image on a half pixel, where a translation resamples instead of
        // moving. That is a difference from the Core Graphics path, so it is declined rather than approximated.
        guard (width - firstImage.width) % 2 == 0, (height - firstImage.height) % 2 == 0,
              (width - secondImage.width) % 2 == 0, (height - secondImage.height) % 2 == 0 else {
            return nil
        }

        let centered: (CGImage) -> CIImage = { image in
            CIImage(cgImage: image).transformed(by: CGAffineTransform(
                translationX: CGFloat((width - image.width) / 2),
                y: CGFloat((height - image.height) / 2)))
        }
        filter.inputFirstImage = centered(firstImage)
        filter.inputSecondImage = centered(secondImage)

        guard let ciOutput = filter.outputImage else {
            return nil
        }
        return CIContext.rgbWorkingSpace.createCGImage(ciOutput, from: ciOutput.extent)
    }
}
