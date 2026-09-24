//
//  Fixtures.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
@testable import ImageProc

/// The images the tests run on. They are drawn in code, where what a test asserts can be read off the drawing, except
/// for the catalog ones, which exist to exercise real bundled assets.
///
/// Sizes are in points at scale 2 unless stated, and drawing uses UIKit coordinates: the origin is the top left.
enum Fixture {

    /// The images of `Resources/TestAssets.xcassets`.
    enum Catalog: String {
        /// An opaque rounded splash on a transparent background, 100 points square.
        case splashRounded = "splash-rounded-100"
        /// An opaque square splash on a transparent background, 100 points square.
        case splashSquare = "splash-square-100"
        /// An opaque square covering a quarter of a transparent 100 point canvas.
        case gradientQuarter = "gradient-quarter-100"
        /// A fully opaque 100 point square.
        case notSoBlue = "not-so-blue-square-100"
        /// A 4 pixel square whose corners are red, yellow, magenta and white.
        case smallGradient = "small-gradient-4"
    }

    static func catalog(_ name: Catalog) -> UIImage {
        guard let image = UIImage(named: name.rawValue, in: Bundle.module, with: nil) else {
            preconditionFailure("\(name.rawValue) is missing from the test asset catalog")
        }
        return image
    }

    /// Renders an image by drawing into a context, top left origin.
    static func render(size: CGSize, scale: CGFloat = 2, _ body: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { body($0.cgContext) }
    }

    /// A single opaque color over the whole canvas.
    static func solid(_ color: UIColor, size: CGSize = CGSize(width: 8, height: 8), scale: CGFloat = 2) -> UIImage {
        return render(size: size, scale: scale) { context in
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// An opaque square centered on a transparent canvas, the plainest silhouette to outline, recolor or composite.
    static func centeredSquare(_ color: UIColor = .red, canvas: CGFloat = 16, side: CGFloat = 8,
                               scale: CGFloat = 2) -> UIImage {
        return render(size: CGSize(width: canvas, height: canvas), scale: scale) { context in
            context.setFillColor(color.cgColor)
            let inset = (canvas - side) / 2
            context.fill(CGRect(x: inset, y: inset, width: side, height: side))
        }
    }

    /// The colors of `blocks`, row by row.
    static let blockColors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .white, .darkGray]

    /// A non-square image of 4x2 blocks of distinct solid colors, so that a transposition, a rotation, a mirroring or
    /// any permutation of the content changes which color lands where.
    static func blocks(orientation: UIImage.Orientation = .up, scale: CGFloat = 2) -> UIImage {
        let block = CGFloat(16) / scale
        let raw = render(size: CGSize(width: block * 4, height: block * 2), scale: scale) { context in
            for row in 0..<2 {
                for col in 0..<4 {
                    context.setFillColor(blockColors[row * 4 + col].cgColor)
                    context.fill(CGRect(x: CGFloat(col) * block, y: CGFloat(row) * block, width: block, height: block))
                }
            }
        }
        return UIImage(cgImage: raw.cgImage!, scale: scale, orientation: orientation)
    }

    /// Asymmetric like `blocks`, but every opaque pixel shares one color.
    ///
    /// The Metal expansion keeps the most opaque sample of a ring, and between equally opaque samples of different
    /// colors the one it keeps depends on the order it visits them in. That order is fixed in buffer space, so on a
    /// multi-colored source an oriented image and its baked equivalent legitimately disagree along color boundaries.
    static func shape(orientation: UIImage.Orientation = .up, scale: CGFloat = 2) -> UIImage {
        let block = CGFloat(16) / scale
        let raw = render(size: CGSize(width: block * 4, height: block * 2), scale: scale) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: block, height: block))
            context.fill(CGRect(x: 0, y: block, width: block * 3, height: block))
        }
        return UIImage(cgImage: raw.cgImage!, scale: scale, orientation: orientation)
    }

    /// A smaller asymmetric image, to be the second one of a two-image operation: its four quadrants differ and its
    /// footprint is not square, so mishandling *its* orientation shows up too.
    static func quadrants(orientation: UIImage.Orientation = .up, scale: CGFloat = 2) -> UIImage {
        let width = CGFloat(12) / scale
        let height = CGFloat(8) / scale
        let colors: [UIColor] = [.orange, .brown, .purple, .systemTeal]
        let raw = render(size: CGSize(width: width * 2, height: height * 2), scale: scale) { context in
            for row in 0..<2 {
                for col in 0..<2 {
                    context.setFillColor(colors[row * 2 + col].cgColor)
                    context.fill(CGRect(x: CGFloat(col) * width, y: CGFloat(row) * height, width: width, height: height))
                }
            }
        }
        return UIImage(cgImage: raw.cgImage!, scale: scale, orientation: orientation)
    }

    /// Invariant under all eight orientations, so it can be the second image of a two-image operation without its own
    /// orientation muddling what is measured.
    static func disc(scale: CGFloat = 2) -> UIImage {
        let side = CGFloat(24) / scale
        return render(size: CGSize(width: side, height: side), scale: scale) { context in
            context.setFillColor(UIColor.orange.cgColor)
            context.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    /// A solid ellipse, where a ring dilation and a disc dilation agree.
    static func ellipse(scale: CGFloat = 2) -> UIImage {
        return render(size: CGSize(width: 40, height: 24), scale: scale) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fillEllipse(in: CGRect(x: 6, y: 4, width: 28, height: 16))
        }
    }

    /// A thin cross, where they do not: a ring smears a hairline into a band, a disc fills it solid.
    static func thinCross(scale: CGFloat = 2) -> UIImage {
        return render(size: CGSize(width: 40, height: 24), scale: scale) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 19, y: 2, width: 1, height: 20))
            context.fill(CGRect(x: 4, y: 11, width: 32, height: 1))
        }
    }

    /// Vertical stripes of distinct colors, which a multi-colored expansion would composite in an arbitrary order if
    /// it were order-dependent.
    static func stripes() -> UIImage {
        return render(size: CGSize(width: 24, height: 16)) { context in
            for (index, color) in [UIColor.red, .green, .blue, .yellow].enumerated() {
                context.setFillColor(color.cgColor)
                context.fill(CGRect(x: CGFloat(index) * 6, y: 0, width: 6, height: 16))
            }
        }
    }

    /// An image resolving to a different solid color per interface style.
    static func dynamic(light: UIColor = .red, dark: UIColor = .blue, side: CGFloat = 8) -> UIImage {
        let size = CGSize(width: side, height: side)
        let asset = UIImageAsset()
        asset.register(solid(light, size: size), with: TraitEnvironment.traits(.light))
        asset.register(solid(dark, size: size), with: TraitEnvironment.traits(.dark))
        return asset.image(with: TraitEnvironment.traits(.light))
    }

    /// An image backed by a `CIImage` only, which has no `cgImage` for the operations to work on.
    static func ciBacked() -> UIImage {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 8, height: 8))
        return UIImage(ciImage: image)
    }
}
