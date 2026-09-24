//
//  ProcessorTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 22/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// `processed(_:)` runs the same operations as the `UIImage` methods, only as one Core Image graph. What it has to
/// prove is that the result is the one the equivalent sequence of calls produces.
@Suite("Chained processing")
struct ProcessorTests {

    static let color = Operation.color
    let shape = Fixture.catalog(.splashRounded)
    let other = Fixture.catalog(.splashSquare)

    @Test("each operation matches its counterpart", arguments: Operation.all)
    func eachOperationMatchesItsCounterpart(_ operation: Operation) {
        let other = self.other
        #expect(mismatch(shape.processed { operation.chained($0, other) }, operation(shape, with: other)) == nil)
    }

    /// Several Core Image steps in a row, which is the case the whole thing exists for.
    @Test("a chain matches the sequence of calls")
    func aChainMatchesTheSequenceOfCalls() {
        let color = Self.color
        #expect(mismatch(shape.processed { $0.colorized(with: color).expanded(bySize: 4, each: 30) },
                         shape.colorized(with: color).expanded(bySize: 4, each: 30)) == nil)
        #expect(mismatch(shape.processed { $0.colorized(with: color).smoothened(by: 2) },
                         shape.colorized(with: color).smoothened(by: 2)) == nil, "across working spaces")
        #expect(mismatch(shape.processed { $0.smoothened(by: 2).colorized(with: color) },
                         shape.smoothened(by: 2).colorized(with: color)) == nil, "across working spaces")

        // The sequence rounds to 8 bits after every step and the chain does not; inverting then magnifies that.
        #expect(mismatch(shape.processed { $0.colorized(with: color).expanded(bySize: 3, each: 30).colorInverted() },
                         shape.colorized(with: color).expanded(bySize: 3, each: 30).colorInverted(),
                         tolerance: Tolerance.linearSpace) == nil)
    }

    /// A step Core Image cannot express the same way renders what came before and continues from it, so mixing the
    /// two kinds has to keep working.
    @Test("a chain can mix fused and rendered steps")
    func aChainCanMixFusedAndRenderedSteps() {
        let color = Self.color
        #expect(mismatch(shape.processed { $0.colorized(with: color).scaled(uniform: 0.5).expanded(bySize: 2) },
                         shape.colorized(with: color).scaled(uniform: 0.5).expanded(bySize: 2)) == nil)
        #expect(mismatch(shape.processed { $0.rotated(by: 20).stroked(with: color, size: 2, each: 45) },
                         shape.rotated(by: 20).stroked(with: color, size: 2, each: 45)) == nil)
    }

    @Test("an empty chain is the image itself")
    func anEmptyChainIsTheImageItself() {
        #expect(mismatch(shape.processed { $0 }, shape) == nil)
    }

    @Test("a chain keeps the orientation", arguments: [UIImage.Orientation.up, .down, .left, .rightMirrored])
    func aChainKeepsTheOrientation(_ orientation: UIImage.Orientation) {
        let color = Self.color
        let source = UIImage(cgImage: shape.cgImage!, scale: shape.scale, orientation: orientation)
        #expect(mismatch(source.processed { $0.colorized(with: color).expanded(bySize: 3, each: 30) },
                         source.colorized(with: color).expanded(bySize: 3, each: 30)) == nil)
        #expect(mismatch(source.processed { $0.stroked(with: color, size: 3, each: 30) },
                         source.stroked(with: color, size: 3, each: 30)) == nil)
    }

    @Test("a chain keeps the options")
    func aChainKeepsTheOptions() {
        let color = Self.color
        let source = shape
            .withRenderingMode(.alwaysOriginal)
            .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        let output = source.processed { $0.colorized(with: color).expanded(bySize: 2, each: 90) }

        #expect(output.renderingMode == source.renderingMode)
        #expect(output.alignmentRectInsets == source.alignmentRectInsets)
        #expect(output.scale == source.scale)
    }

    // MARK: Dynamic colors

    /// A dynamic participant makes the whole chain fan out once, not every step of it, and the result still follows
    /// the environment.
    @Test("a chain fans out once over the color traits", .tags(.traits))
    func aChainFansOutOnceOverTheColorTraits() throws {
        let dynamicColor = UIColor.systemPink
        let output = shape.processed { $0.colorized(with: dynamicColor).expanded(bySize: 2, each: 90) }
        #expect(output._colorTraitVariance.varies, "a dynamic color has to produce a dynamic image")

        var variants: [Bitmap] = []
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UIImage._colorTraitCollection(style: style, contrast: .unspecified, scale: shape.scale)
            let resolved = TraitEnvironment.resolved(output, traits)
            let expected = shape.colorized(with: dynamicColor.resolvedColor(with: traits)).expanded(bySize: 2, each: 90)
            #expect(mismatch(resolved, expected) == nil, "variant \(style.rawValue)")
            variants.append(try #require(Bitmap(resolved)))
        }

        // The two variants have to actually differ, otherwise the comparison above proves nothing.
        #expect(variants[0].bytes != variants[1].bytes, "the variants must not be identical")
    }

    /// Not `imageAsset == nil`: `withOptions(from:)` leaves a derived asset behind on every output. What has to be true
    /// is that the result does not resolve differently for the traits.
    @Test("an invariant chain stays static", .tags(.traits))
    func anInvariantChainStaysStatic() {
        let color = Self.color
        let plain = UIImage(cgImage: shape.cgImage!, scale: shape.scale, orientation: .up)
        #expect(!plain.processed { $0.colorized(with: color).expanded(bySize: 2, each: 90) }._colorTraitVariance.varies)
    }

    @Test("a chain nested in a fan-out does not fan out again", .tags(.traits))
    func aChainNestedInAFanOutDoesNotFanOutAgain() {
        UIImage._isFanningOutOverColorTraits = true
        defer { UIImage._isFanningOutOverColorTraits = false }

        let output = shape.processed { $0.colorized(with: .systemPink) }
        #expect(!output._colorTraitVariance.varies, "a nested chain has to decline the fan-out")
        #expect(UIImage._isFanningOutOverColorTraits, "the flag has to be left as it was found")
    }
}
