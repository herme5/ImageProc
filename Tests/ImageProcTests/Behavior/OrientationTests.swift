//
//  OrientationTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 08/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Camera and photo library images carry their rotation as an `imageOrientation` instead of rotating their pixels, so
/// their `cgImage` buffer is not what gets displayed. Every operation fills a context with that raw buffer and tags the
/// result with the orientation again, which used to apply it twice.
///
/// The fixtures are deliberately non-square: a square one hides a transposition.
@Suite("Orientation", .tags(.orientation))
struct OrientationTests {

    /// An operation is orientation-correct when applying it to an oriented image displays the same result as applying
    /// it to the very same image with its orientation already baked into the buffer.
    @Test("an oriented image gives what its baked equivalent gives", arguments: Operation.all, Orientation.all)
    func anOrientedImageGivesWhatItsBakedEquivalentGives(_ operation: Operation, orientation: Orientation) {
        let oriented = operation.needsSingleColorSource
            ? Fixture.shape(orientation: orientation.value)
            : Fixture.blocks(orientation: orientation.value)
        let neutral = Fixture.disc()
        #expect(displayMismatch(operation(oriented, with: neutral), operation(oriented.baked, with: neutral)) == nil)
    }

    /// Both orientations of a two-image operation.
    struct Pair: Sendable, CustomTestStringConvertible {
        let receiver: Orientation
        let other: Orientation
        var testDescription: String { "\(receiver.testDescription) with \(other.testDescription)" }

        static let all = Orientation.all.flatMap { receiver in
            Orientation.all.map { Pair(receiver: receiver, other: $0) }
        }
    }

    /// A two-image operation draws both buffers raw into one context, so the second image has to be re-expressed in the
    /// receiver's space when the two orientations differ — which is the norm as soon as a camera image meets a bundled
    /// one.
    @Test("two differently oriented images combine as displayed", arguments: Operation.composites, Pair.all)
    func twoDifferentlyOrientedImagesCombineAsDisplayed(_ operation: Operation, pair: Pair) {
        let receiver = Fixture.blocks(orientation: pair.receiver.value)
        let other = Fixture.quadrants(orientation: pair.other.value)
        #expect(displayMismatch(operation(receiver, with: other), operation(receiver.baked, with: other.baked)) == nil)
    }

    /// The displayed size is what the caller asks for and works with, whatever the orientation is.
    @Test("scaling gives the requested displayed size", arguments: Orientation.all)
    func scalingGivesTheRequestedDisplayedSize(_ orientation: Orientation) throws {
        let source = Fixture.blocks(orientation: orientation.value)
        let target = CGSize(width: 10, height: 20)
        let scaled = source.scaled(to: target, interpolationQuality: .none)

        #expect(scaled.size == target)
        #expect(scaled.imageOrientation == orientation.value)

        // The orientation is carried over rather than baked, so the buffer stays in its own space.
        let buffer = try #require(scaled.cgImage)
        let expected = source._orientationSwapsAxes ? CGSize(width: target.height, height: target.width) : target
        #expect(CGFloat(buffer.width) == expected.width * scaled.scale)
        #expect(CGFloat(buffer.height) == expected.height * scaled.scale)
    }

    /// Which region the crop selects is covered by the first test; this one pins its size.
    @Test("cropping gives the requested displayed size", arguments: Orientation.all)
    func croppingGivesTheRequestedDisplayedSize(_ orientation: Orientation) {
        let rect = CGRect(x: 2, y: 1, width: 8, height: 4)
        #expect(Fixture.blocks(orientation: orientation.value).cropped(to: rect).size == rect.size)
    }
}
