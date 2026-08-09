//
//  OrientationTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 08/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

/// Camera and photo library images carry their rotation as an `imageOrientation` instead of rotating their pixels, so
/// their `cgImage` buffer is not what gets displayed. Every operation fills a context with that raw buffer and tags
/// the result with the orientation again, which used to apply it twice.
final class OrientationTests: XCTestCase {

    /// The eight orientations, including the four quarter-turn ones that exchange the axes.
    static let orientations: [(String, UIImage.Orientation)] = [
        ("up", .up), ("down", .down), ("left", .left), ("right", .right),
        ("upMirrored", .upMirrored), ("downMirrored", .downMirrored),
        ("leftMirrored", .leftMirrored), ("rightMirrored", .rightMirrored)
    ]

    /// Comparing a resampled render against another cannot be exact: rounding lands one unit off on the smooth
    /// output of a blur. A misplacement is orders of magnitude above this.
    static let tolerance = CGFloat(2)

    func render(size: CGSize, scale: CGFloat, _ body: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { body($0.cgContext) }
    }

    /// A non-square image of 4x2 blocks of distinct solid colors, so that a transposition, a rotation, a mirroring or
    /// any permutation of the content changes which color lands where.
    func fixture(orientation: UIImage.Orientation, scale: CGFloat = 2) -> UIImage {
        let block = CGFloat(16) / scale
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .white, .darkGray]
        let raw = render(size: CGSize(width: block * 4, height: block * 2), scale: scale) { context in
            for row in 0..<2 {
                for col in 0..<4 {
                    context.setFillColor(colors[row * 4 + col].cgColor)
                    context.fill(CGRect(x: CGFloat(col) * block, y: CGFloat(row) * block,
                                        width: block, height: block))
                }
            }
        }
        return UIImage(cgImage: raw.cgImage!, scale: scale, orientation: orientation)
    }

    /// Asymmetric too, but every opaque pixel shares one color, which keeps `expanded` deterministic: it composites
    /// its layers concurrently, so overlapping pixels of different colors would land in an arbitrary order.
    func shapeFixture(orientation: UIImage.Orientation, scale: CGFloat = 2) -> UIImage {
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
    func secondFixture(orientation: UIImage.Orientation, scale: CGFloat = 2) -> UIImage {
        let width = CGFloat(12) / scale
        let height = CGFloat(8) / scale
        let colors: [UIColor] = [.orange, .brown, .purple, .systemTeal]
        let raw = render(size: CGSize(width: width * 2, height: height * 2), scale: scale) { context in
            for row in 0..<2 {
                for col in 0..<2 {
                    context.setFillColor(colors[row * 2 + col].cgColor)
                    context.fill(CGRect(x: CGFloat(col) * width, y: CGFloat(row) * height,
                                        width: width, height: height))
                }
            }
        }
        return UIImage(cgImage: raw.cgImage!, scale: scale, orientation: orientation)
    }

    /// Invariant under all eight orientations, so it can be the second image of a two-image operation without its own
    /// orientation muddling what is measured.
    func neutralFixture(scale: CGFloat = 2) -> UIImage {
        let side = CGFloat(24) / scale
        return render(size: CGSize(width: side, height: side), scale: scale) { context in
            context.setFillColor(UIColor.orange.cgColor)
            context.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    /// Renders the image the way it is displayed, into an `.up` buffer.
    func baked(_ image: UIImage) -> UIImage {
        return render(size: image.size, scale: image.scale) { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Compares two displayed appearances on a grid of sample points, and describes the first difference.
    func mismatch(_ lhs: UIImage, _ rhs: UIImage) -> String? {
        guard lhs.size.width == rhs.size.width, lhs.size.height == rhs.size.height else {
            return "size \(lhs.size) vs \(rhs.size)"
        }
        let left = baked(lhs).cgImage!
        let right = baked(rhs).cgImage!
        guard left.width == right.width, left.height == right.height else {
            return "buffer \(left.width)x\(left.height) vs \(right.width)x\(right.height)"
        }

        let steps = 7
        for row in 1..<steps {
            for col in 1..<steps {
                let coord = CGImage.PixelCoordinate(column: left.width * col / steps,
                                                    row: left.height * row / steps)
                guard let lhsColor = left.color(at: coord), let rhsColor = right.color(at: coord),
                      let lhsRGBA = lhsColor.components, let rhsRGBA = rhsColor.components,
                      lhsRGBA.count == rhsRGBA.count else {
                    continue
                }
                let delta = zip(lhsRGBA, rhsRGBA).map { abs($0 - $1) }.max()! * 255
                if delta > Self.tolerance {
                    return "pixel (\(coord.column),\(coord.row)) \(lhsColor.hexCode) vs \(rhsColor.hexCode)"
                }
            }
        }
        return nil
    }

    /// An operation is orientation-correct when applying it to an oriented image displays the same result as applying
    /// it to the very same image with its orientation already baked into the buffer.
    func testOrientationHandling() throws {
        let ops: [(String, (UIImage) -> UIImage, Bool)] = [
            ("colorized", { $0.colorized(with: .systemPink) }, false),
            ("colorInverted", { $0.colorInverted() }, false),
            ("withAlphaComponent", { $0.withAlphaComponent(0.5) }, false),
            ("smoothened(sizeKept:)", { $0.smoothened(by: 2, sizeKept: true) }, false),
            ("smoothened", { $0.smoothened(by: 2, sizeKept: false) }, false),
            ("expanded", { $0.expanded(bySize: 2, each: 90) }, true),
            ("stroked", { $0.stroked(with: .systemPink, size: 2, each: 90) }, true),
            ("scaled(to:)", { $0.scaled(to: CGSize(width: 10, height: 20)) }, false),
            ("scaled(uniform:)", { $0.scaled(uniform: 0.5) }, false),
            ("cropped", { $0.cropped(to: CGRect(x: 2, y: 1, width: 8, height: 4)) }, false),
            ("rotated(90)", { $0.rotated(by: 90) }, false),
            ("rotated(30)", { $0.rotated(by: 30) }, false),
            ("flippedHorizontally", { $0.flippedHorizontally() }, false),
            ("flippedVertically", { $0.flippedVertically() }, false),
            ("drawnUnder", { $0.drawnUnder(image: self.neutralFixture()) }, false),
            ("drawnAbove", { $0.drawnAbove(image: self.neutralFixture()) }, false),
            ("alphaExclusion", { $0.alphaExclusion(with: self.neutralFixture()) }, false)
        ]

        for (opName, op, usesShape) in ops {
            for (orientationName, orientation) in Self.orientations {
                let oriented = usesShape
                    ? shapeFixture(orientation: orientation)
                    : fixture(orientation: orientation)
                XCTAssertNil(mismatch(op(oriented), op(baked(oriented))), "\(opName) of \(orientationName)")
            }
        }
    }

    /// A two-image operation draws both buffers raw into one context, so the second image has to be re-expressed in
    /// the receiver's space when the two orientations differ — which is the norm as soon as a camera image meets a
    /// bundled one.
    func testMixedOrientationComposites() throws {
        let ops: [(String, (UIImage, UIImage) -> UIImage)] = [
            ("drawnUnder", { $0.drawnUnder(image: $1) }),
            ("drawnAbove", { $0.drawnAbove(image: $1) }),
            ("alphaExclusion", { $0.alphaExclusion(with: $1) })
        ]

        for (opName, op) in ops {
            for (receiverName, receiverOrientation) in Self.orientations {
                for (otherName, otherOrientation) in Self.orientations {
                    let receiver = fixture(orientation: receiverOrientation)
                    let other = secondFixture(orientation: otherOrientation)
                    XCTAssertNil(mismatch(op(receiver, other), op(baked(receiver), baked(other))),
                                 "\(opName) of \(receiverName) with \(otherName)")
                }
            }
        }
    }

    /// The displayed size is what the caller asks for and works with, whatever the orientation is.
    func testScaledSizeIsTheRequestedOne() throws {
        for (name, orientation) in Self.orientations {
            let source = fixture(orientation: orientation)
            let target = CGSize(width: 10, height: 20)
            let scaled = source.scaled(to: target, interpolationQuality: .none)

            XCTAssertEqual(scaled.size, target, name)
            XCTAssertEqual(scaled.imageOrientation, orientation, name)

            // The orientation is carried over rather than baked, so the buffer stays in its own space.
            let expected = source._orientationSwapsAxes
                ? CGSize(width: target.height, height: target.width)
                : target
            XCTAssertEqual(CGFloat(scaled.cgImage!.width), expected.width * scaled.scale, name)
            XCTAssertEqual(CGFloat(scaled.cgImage!.height), expected.height * scaled.scale, name)
        }
    }

    /// The rect passed to `cropped(to:)` is expressed in the displayed space, so the crop comes back at exactly the
    /// requested size. Which region it selects is covered by `testOrientationHandling`.
    func testCroppedSizeIsTheRequestedOne() throws {
        let rect = CGRect(x: 2, y: 1, width: 8, height: 4)
        for (name, orientation) in Self.orientations {
            XCTAssertEqual(fixture(orientation: orientation).cropped(to: rect).size, rect.size, name)
        }
    }
}
