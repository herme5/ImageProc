//
//  UIImageExtension+Traits.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 09/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreGraphics

/// An image or a color can resolve to different content depending on the *color traits* of the environment: the
/// interface style and the accessibility contrast. Processing such an input by only looking at what it resolves to
/// right now would freeze it, so every operation runs once per variant and registers the results into a new
/// `UIImageAsset`, which is what makes the output follow the environment in turn.
///
/// Nothing of this happens when no participant varies, which is the overwhelmingly common case: the operation then
/// runs exactly once, on a plain image, as it always did.
internal extension UIImage {

    /// Which of the two color dimensions a participant resolves differently for.
    struct ColorTraitVariance {
        var style = false
        var contrast = false

        var varies: Bool { return style || contrast }

        static func | (lhs: ColorTraitVariance, rhs: ColorTraitVariance) -> ColorTraitVariance {
            return ColorTraitVariance(style: lhs.style || rhs.style, contrast: lhs.contrast || rhs.contrast)
        }

        /// The trait collections to render, which is the product of the dimensions that actually vary. A participant
        /// that only varies with the interface style is rendered twice, not four times.
        var traitCollections: [UITraitCollection] {
            let styles: [UIUserInterfaceStyle] = style ? [.light, .dark] : [.unspecified]
            let contrasts: [UIAccessibilityContrast] = contrast ? [.normal, .high] : [.unspecified]
            return styles.flatMap { style in
                contrasts.map { contrast in
                    UIImage._colorTraitCollection(style: style, contrast: contrast)
                }
            }
        }
    }

    /// Whether a fan-out is already under way on this thread. The operations re-enter themselves per variant, so
    /// this is what keeps that one level deep.
    static var _isFanningOutOverColorTraits: Bool {
        get { return Thread.current.threadDictionary[_fanOutKey] as? Bool ?? false }
        set { Thread.current.threadDictionary[_fanOutKey] = newValue }
    }

    private static let _fanOutKey = "fr.andrearuffino.ImageProc.fanningOutOverColorTraits"

    static func _colorTraitCollection(style: UIUserInterfaceStyle,
                                      contrast: UIAccessibilityContrast,
                                      scale: CGFloat? = nil) -> UITraitCollection {
        var traits = [UITraitCollection(userInterfaceStyle: style), UITraitCollection(accessibilityContrast: contrast)]
        if let scale {
            // Resolving without a display scale can hand back a variant rescaled to 1x.
            traits.append(UITraitCollection(displayScale: scale))
        }
        return UITraitCollection(traitsFrom: traits)
    }

    /// The dimensions this image resolves differently for.
    var _colorTraitVariance: ColorTraitVariance {
        guard let asset = imageAsset else {
            return ColorTraitVariance()
        }
        func content(_ style: UIUserInterfaceStyle, _ contrast: UIAccessibilityContrast) -> CGImage? {
            let variant = asset.image(with: Self._colorTraitCollection(style: style,
                                                                       contrast: contrast,
                                                                       scale: scale))
            // A derived asset — the one `withRenderingMode(_:)` and friends leave behind — only holds the variant it
            // was derived from, and answers an empty placeholder for the others. That is an absence of information,
            // not a difference; UIKit itself stops following the environment for such an image.
            return variant.size == .zero ? nil : variant.cgImage
        }
        func differs(_ candidate: CGImage?, from reference: CGImage?) -> Bool {
            guard let candidate, let reference else {
                return false
            }
            return candidate !== reference
        }

        let reference = content(.light, .normal)
        return ColorTraitVariance(style: differs(content(.dark, .normal), from: reference),
                                  contrast: differs(content(.light, .high), from: reference))
    }

    /// Resolves this image for the given traits and detaches it from its asset, so that the result is a plain image
    /// the operations can work on — and so that the fan-out cannot recurse.
    func _flattened(for traits: UITraitCollection) -> UIImage {
        let resolved = imageAsset?.image(with: traits) ?? self

        // A derived asset — what `withRenderingMode(_:)` and friends leave behind — hands back an empty placeholder
        // for the variants it does not hold. Fall back to this image rather than processing nothing.
        let usable = (resolved.size == .zero || resolved.cgImage == nil) ? self : resolved
        guard let cgImage = usable.cgImage else {
            return usable
        }
        return UIImage(cgImage: cgImage, scale: usable.scale, orientation: usable.imageOrientation)
            .withOptions(from: usable)
    }

    /// Runs `body` once per color trait variant and returns an image that follows the environment, or `nil` when
    /// nothing varies and the caller should just take its regular path.
    ///
    /// - parameters:
    ///   - other: The variance of the other participants, a color or a second image.
    ///   - body: Applies the operation to a flattened variant of this image, for the given traits.
    /// - returns: A dynamic `UIImage`, or `nil` when no participant varies with the color traits.
    func _perColorTrait(alsoVarying other: ColorTraitVariance = ColorTraitVariance(),
                        _ body: (UIImage, UITraitCollection) -> UIImage) -> UIImage? {
        // The body re-enters the very operation that is fanning out, on inputs that are supposed to be resolved and
        // therefore invariant. Should a participant misreport its variance, that would recurse forever, so the
        // recursion is cut here rather than trusted not to happen.
        guard !Self._isFanningOutOverColorTraits else {
            return nil
        }
        let variance = _colorTraitVariance | other
        guard variance.varies else {
            return nil
        }

        Self._isFanningOutOverColorTraits = true
        defer { Self._isFanningOutOverColorTraits = false }

        let asset = UIImageAsset()
        for traits in variance.traitCollections {
            let variant = body(_flattened(for: traits), traits)

            // The options have to be carried by the variants: applying them to the resolved image would detach it
            // from the asset. The baseline offset does not survive registration at all, so a dynamic output loses it.
            asset.register(variant, with: UITraitCollection(traitsFrom: [
                traits, UITraitCollection(displayScale: variant.scale)
            ]))
        }
        // Pin the display scale to this image's own, otherwise the environment's scale would resolve a variant, and
        // its configuration, for the wrong one.
        return asset.image(with: UITraitCollection(traitsFrom: [
            UITraitCollection.current, UITraitCollection(displayScale: scale)
        ]))
    }
}

internal extension UIColor {

    /// The dimensions this color resolves differently for. System colors vary with both.
    var _colorTraitVariance: UIImage.ColorTraitVariance {
        // Comparing the resolved colors with `==` is not dependable: a `UIColor` wrapping a `CIColor` compares by
        // identity, which reports a difference that is not there. The components are the actual answer.
        func components(_ style: UIUserInterfaceStyle, _ contrast: UIAccessibilityContrast) -> [CGFloat] {
            let resolved = resolvedColor(with: UIImage._colorTraitCollection(style: style, contrast: contrast))
            return resolved.cgColor.components ?? []
        }
        let reference = components(.light, .normal)
        return UIImage.ColorTraitVariance(style: components(.dark, .normal) != reference,
                                          contrast: components(.light, .high) != reference)
    }
}
