//
//  UIImageExtension+Processed.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 22/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import CoreImage

public extension UIImage {

    /// Runs several operations as one Core Image graph, reading the result back once instead of once per step.
    ///
    /// Every operation on `UIImage` has to hand back a `UIImage`, which means rendering the graph and pulling the
    /// pixels off the GPU. Chaining four of them pays that four times, and once per color trait variant on top. The
    /// closure here works on a recipe instead: the kernels are concatenated and only the result is read back.
    ///
    ///     let badge = icon.processed { $0.colorized(with: .systemPink).expanded(bySize: 4).smoothened(by: 1) }
    ///
    /// The operations mirror the ones on `UIImage` and mean the same thing. Those that Core Image cannot express the
    /// same way — the geometric ones, the composites, and the expansion when a CPU implementation is selected —
    /// render what has accumulated so far and go through the regular `UIImage` method, so the output matches what
    /// the same sequence of calls produces today. Grouping the Core Image ones together is what pays.
    ///
    /// The color trait fan-out happens once around the whole closure rather than once per operation, so a dynamic
    /// color costs four runs of the chain rather than four runs of every step.
    ///
    /// - parameters:
    ///   - body: Describes the sequence to apply to this image.
    /// - returns: The processed `UIImage`.
    func processed(_ body: (Processor) -> Processor) -> UIImage {
        // The operations that fall back to a `UIImage` method must not each fan out on their own, and neither must
        // this one when it is already running inside a fan-out.
        let wasFanningOut = Self._isFanningOutOverColorTraits
        Self._isFanningOutOverColorTraits = true
        defer { Self._isFanningOutOverColorTraits = wasFanningOut }

        // The first run builds the recipe and collects what the participants vary with. For a chain made only of
        // Core Image steps nothing has been rendered yet at this point, so learning that a fan-out is needed costs
        // nothing; a step that had to fall back has already done its work, and that one run is spent.
        let first = body(Processor(source: self, traits: nil))
        let variance = wasFanningOut ? ColorTraitVariance() : (_colorTraitVariance | first.variance)
        guard variance.varies else {
            return first.resolved()
        }

        let asset = UIImageAsset()
        for traits in variance.traitCollections {
            let variant = body(Processor(source: _flattened(for: traits), traits: traits)).resolved()

            // As everywhere else, the options have to be carried by the variants: applying them to the resolved
            // image would detach it from the asset.
            asset.register(variant, with: UITraitCollection(traitsFrom: [
                traits, UITraitCollection(displayScale: variant.scale)
            ]))
        }
        return asset.image(with: UITraitCollection(traitsFrom: [
            UITraitCollection.current, UITraitCollection(displayScale: scale)
        ]))
    }

    /// A sequence of operations being accumulated by `processed(_:)`, as a Core Image recipe rather than as pixels.
    ///
    /// This is the one public type in the library that is not an extension on a UIKit type, and it is public on
    /// purpose — it is declared in a `public extension`, which publishes it without a modifier of its own, so the
    /// `public` is deliberate here rather than the accident that rule usually guards against. It is nested in
    /// `UIImage` so the name stays where callers look for it.
    ///
    /// It is a value: every operation returns a new processor and nothing is shared, so a chain can be built on any
    /// thread, and holding on to an intermediate step to branch from it is safe.
    struct Processor {

        /// The working color space the accumulated recipe is being built for. The operations keep the one their
        /// `UIImage` counterpart uses, so a chain that mixes the two renders at the boundary rather than moving an
        /// operation into a space it did not use before.
        private enum WorkingSpace {
            case rgb
            case unspecified

            var context: CIContext {
                switch self {
                case .rgb:
                    return .rgbWorkingSpace
                case .unspecified:
                    return .defaultWorkingSpace
                }
            }
        }

        /// The last rendered state. It carries the scale, the orientation and the options the result adopts.
        private let base: UIImage

        /// What has accumulated on top of `base`, or `nil` when `base` is already the current state.
        private let pending: CIImage?

        /// The space `pending` is being built in.
        private let space: WorkingSpace

        /// The traits the participants are resolved for, or `nil` outside of a fan-out.
        private let traits: UITraitCollection?

        /// What the participants seen so far resolve differently for.
        internal private(set) var variance: UIImage.ColorTraitVariance

        internal init(source: UIImage, traits: UITraitCollection?) {
            self.base = source
            self.pending = nil
            self.space = .rgb
            self.traits = traits
            self.variance = UIImage.ColorTraitVariance()
        }

        private init(base: UIImage, pending: CIImage?, space: WorkingSpace,
                     traits: UITraitCollection?, variance: UIImage.ColorTraitVariance) {
            self.base = base
            self.pending = pending
            self.space = space
            self.traits = traits
            self.variance = variance
        }

        // MARK: - State

        /// The current state as a `CIImage`, or `nil` when the source cannot provide a buffer.
        private var current: CIImage? {
            if let pending {
                return pending
            }
            guard let cgImage = base.cgImage else {
                return nil
            }
            return CIImage(cgImage: cgImage)
        }

        /// Continues the chain with a new recipe.
        private func adding(_ image: CIImage, in space: WorkingSpace) -> Processor {
            return Processor(base: base, pending: image, space: space, traits: traits, variance: variance)
        }

        /// Returns a processor whose recipe can be continued in the given working space, rendering what has
        /// accumulated when it was built for the other one. Nothing is rendered when there is no recipe yet, nor
        /// when the space already matches.
        private func preparing(for space: WorkingSpace) -> Processor {
            guard pending != nil, self.space != space else {
                return self
            }
            return restarting(from: materialized())
        }

        /// Continues the chain from an image that has already been rendered.
        private func restarting(from image: UIImage) -> Processor {
            return Processor(base: image, pending: nil, space: .rgb, traits: traits, variance: variance)
        }

        /// Records that a participant varies with the color traits, so that `processed(_:)` knows to fan out.
        private func noting(_ other: UIImage.ColorTraitVariance) -> Processor {
            return Processor(base: base, pending: pending, space: space, traits: traits,
                             variance: variance | other)
        }

        /// Renders what has accumulated and returns the chain to a plain image, which is what the operations Core
        /// Image cannot express the same way work from.
        private func materialized() -> UIImage {
            guard let pending else {
                return base
            }
            guard let cgOutput = space.context.createCGImage(pending, from: pending.extent) else {
                return base
            }
            return UIImage(cgImage: cgOutput, scale: base.scale, orientation: base.imageOrientation)
                .withOptions(from: base)
        }

        /// Applies an operation that has no Core Image equivalent here: renders the recipe, hands the result to the
        /// regular `UIImage` method, and continues from there.
        private func falling(back operation: (UIImage) -> UIImage) -> Processor {
            return restarting(from: operation(materialized()))
        }

        /// The processed image. Renders the accumulated recipe, if any is left.
        internal func resolved() -> UIImage {
            return materialized()
        }

        /// Resolves a color for the traits being rendered, outside of a fan-out the color itself.
        private func resolve(_ color: UIColor) -> UIColor {
            guard let traits else {
                return color
            }
            return color.resolvedColor(with: traits)
        }

        /// Resolves a second image for the traits being rendered.
        private func resolve(_ image: UIImage) -> UIImage {
            guard let traits else {
                return image
            }
            return image._flattened(for: traits)
        }

        // MARK: - Core Image operations

        /// Replaces the color of every opaque pixel, as `UIImage.colorized(with:)` does.
        public func colorized(with color: UIColor) -> Processor {
            let step = noting(color._colorTraitVariance).preparing(for: .rgb)
            guard let input = step.current,
                  let output = UIImage._colorized(input, with: step.resolve(color)) else {
                return step
            }
            return step.adding(output, in: .rgb)
        }

        /// Replicates the opaque pixels all around the origin, as `UIImage.expanded(bySize:each:)` does.
        public func expanded(bySize delta: CGFloat, each degree: CGFloat = 3) -> Processor {
            let step = preparing(for: .rgb)
            guard case .metal = UIImage._expandImplementation, ExpandFilter.isAvailable,
                  let input = step.current else {
                // A CPU implementation scatters into a `CGContext`, which cannot be expressed as a recipe.
                return step.falling(back: { $0.expanded(bySize: delta, each: degree) })
            }
            guard let output = step.expanding(input, bySize: delta, each: degree) else {
                return step
            }
            return step.adding(output, in: .rgb)
        }

        /// Surrounds the opaque region with a border, as `UIImage.stroked(with:size:each:alpha:)` does.
        public func stroked(with color: UIColor, size delta: CGFloat, each degree: CGFloat = 3,
                            alpha: CGFloat = 1) -> Processor {
            let step = noting(color._colorTraitVariance).preparing(for: .rgb)
            guard case .metal = UIImage._expandImplementation, ExpandFilter.isAvailable,
                  let source = step.current else {
                return step.falling(back: {
                    $0.stroked(with: step.resolve(color), size: delta, each: degree, alpha: alpha)
                })
            }

            // The halo is the current state colorized and expanded, and the current state goes back over it. The
            // fade is folded into the color, as `_stroked_metal` does and for the same reason.
            let rgbColor = UIImage._rgbCompliant(step.resolve(color))
            let haloColor = alpha < 1 ? rgbColor.withAlphaComponent(rgbColor.rgba.alpha * alpha) : rgbColor
            guard let colorized = UIImage._colorized(source, with: haloColor),
                  let halo = step.expanding(colorized, bySize: delta, each: degree) else {
                return step
            }
            return step.adding(source.composited(over: halo), in: .rgb)
        }

        /// The expansion kernel applied to a recipe, in the pixel space of the buffer the chain started from.
        private func expanding(_ input: CIImage, bySize delta: CGFloat, each degree: CGFloat) -> CIImage? {
            let filter = ExpandFilter()
            filter.inputImage = input
            filter.inputRadius = delta * base.scale
            filter.inputDegreeStep = degree
            return filter.outputImage
        }

        /// Blurs the image, as `UIImage.smoothened(by:sizeKept:)` does.
        public func smoothened(by radius: CGFloat, sizeKept: Bool = false) -> Processor {
            // The blur runs in Core Image's own working space, so a recipe built for the RGB one is rendered first
            // rather than moved into a space it was not written for.
            let step = preparing(for: .unspecified)
            guard let input = step.current, let filter = CIFilter(name: "CIGaussianBlur") else {
                return step
            }
            filter.setValue(radius, forKey: kCIInputRadiusKey)
            filter.setValue(input, forKey: kCIInputImageKey)
            guard let output = filter.outputImage else {
                return step
            }
            return step.adding(sizeKept ? output.cropped(to: input.extent) : output, in: .unspecified)
        }

        /// Inverts the colors, as `UIImage.colorInverted()` does.
        public func colorInverted() -> Processor {
            let step = preparing(for: .unspecified)
            guard let input = step.current, let filter = CIFilter(name: "CIColorInvert") else {
                return step
            }
            filter.setDefaults()
            filter.setValue(input, forKey: kCIInputImageKey)
            guard let output = filter.outputImage else {
                return step
            }
            return step.adding(output, in: .unspecified)
        }

        // MARK: - Operations that render first

        /// Makes the image more transparent, as `UIImage.withAlphaComponent(_:)` does.
        public func withAlphaComponent(_ value: CGFloat) -> Processor {
            return falling(back: { $0.withAlphaComponent(value) })
        }

        /// Scales the image, as `UIImage.scaled(to:interpolationQuality:)` does.
        public func scaled(to newSize: CGSize,
                           interpolationQuality: CGInterpolationQuality = .default) -> Processor {
            return falling(back: { $0.scaled(to: newSize, interpolationQuality: interpolationQuality) })
        }

        /// Scales the image, as `UIImage.scaled(uniform:interpolationQuality:)` does.
        public func scaled(uniform scalar: CGFloat,
                           interpolationQuality: CGInterpolationQuality = .default) -> Processor {
            return falling(back: { $0.scaled(uniform: scalar, interpolationQuality: interpolationQuality) })
        }

        /// Scales the image, as `UIImage.scaledWidth(to:keepAspectRatio:interpolationQuality:)` does.
        public func scaledWidth(to newWidth: CGFloat, keepAspectRatio: Bool = true,
                                interpolationQuality: CGInterpolationQuality = .default) -> Processor {
            return falling(back: {
                $0.scaledWidth(to: newWidth, keepAspectRatio: keepAspectRatio,
                               interpolationQuality: interpolationQuality)
            })
        }

        /// Scales the image, as `UIImage.scaledHeight(to:keepAspectRatio:interpolationQuality:)` does.
        public func scaledHeight(to newHeight: CGFloat, keepAspectRatio: Bool = true,
                                 interpolationQuality: CGInterpolationQuality = .default) -> Processor {
            return falling(back: {
                $0.scaledHeight(to: newHeight, keepAspectRatio: keepAspectRatio,
                                interpolationQuality: interpolationQuality)
            })
        }

        /// Crops the image, as `UIImage.cropped(to:)` does. The rect is in the displayed coordinate space.
        public func cropped(to rect: CGRect) -> Processor {
            return falling(back: { $0.cropped(to: rect) })
        }

        /// Rotates the image, as `UIImage.rotated(by:)` does.
        public func rotated(by degrees: CGFloat) -> Processor {
            return falling(back: { $0.rotated(by: degrees) })
        }

        /// Flips the image, as `UIImage.flippedHorizontally()` does.
        public func flippedHorizontally() -> Processor {
            return falling(back: { $0.flippedHorizontally() })
        }

        /// Flips the image, as `UIImage.flippedVertically()` does.
        public func flippedVertically() -> Processor {
            return falling(back: { $0.flippedVertically() })
        }

        /// Draws the image under an other one, as `UIImage.drawnUnder(image:)` does.
        public func drawnUnder(image: UIImage) -> Processor {
            let step = noting(image._colorTraitVariance)
            return step.falling(back: { $0.drawnUnder(image: step.resolve(image)) })
        }

        /// Draws the image above an other one, as `UIImage.drawnAbove(image:)` does.
        public func drawnAbove(image: UIImage) -> Processor {
            let step = noting(image._colorTraitVariance)
            return step.falling(back: { $0.drawnAbove(image: step.resolve(image)) })
        }

        /// Excludes the alpha of an other image, as `UIImage.alphaExclusion(with:)` does.
        public func alphaExclusion(with image: UIImage) -> Processor {
            let step = noting(image._colorTraitVariance)
            return step.falling(back: { $0.alphaExclusion(with: step.resolve(image)) })
        }
    }
}
