//
//  TraitEnvironment.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
@testable import ImageProc

/// Resolving images and colors the way a view hierarchy would.
enum TraitEnvironment {

    static func traits(_ style: UIUserInterfaceStyle, _ contrast: UIAccessibilityContrast = .normal,
                       scale: CGFloat = 2) -> UITraitCollection {
        return UIImage._colorTraitCollection(style: style, contrast: contrast, scale: scale)
    }

    /// The variant an image resolves to for the given traits.
    static func resolved(_ image: UIImage, _ traits: UITraitCollection) -> UIImage {
        return image.imageAsset?.image(with: traits) ?? image
    }

    /// The pixel a resolved variant shows at a relative position.
    static func pixel(_ image: UIImage, _ traits: UITraitCollection, at point: CGPoint = Bitmap.center) -> Pixel? {
        return Bitmap(resolved(image, traits))?[relative: point]
    }

    /// The pixel a real view hierarchy displays in the middle of the image, for the given interface style.
    @MainActor
    static func displayed(_ image: UIImage, style: UIUserInterfaceStyle) -> Pixel? {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        window.overrideUserInterfaceStyle = style
        let view = UIImageView(image: image)
        view.frame = window.bounds
        window.addSubview(view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let shot = Fixture.render(size: window.bounds.size) { context in
            window.layer.render(in: context)
        }
        return Bitmap(shot)?[relative: Bitmap.center]
    }
}
