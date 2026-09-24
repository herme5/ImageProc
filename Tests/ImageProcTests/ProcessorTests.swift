//
//  ProcessorTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 22/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

/// `processed(_:)` runs the same operations as the `UIImage` methods, only as one Core Image graph. What it has to
/// prove is that the result is the one the equivalent sequence of calls produces.
final class ProcessorTests: XCTestCase {

    /// The chain reads back once where the sequence reads back at every step, so the two round to 8 bits a
    /// different number of times. One unit of that is unavoidable; more than two means something else moved.
    static let tolerance = 2

    /// The allowance for the two cases that have a measured reason to exceed it, quantified where they are used:
    /// a step that converts through Core Image's linear working space, and the order-dependent CPU expansion.
    static let looseTolerance = 5

    var fixtureBundle: Bundle!
    var shape: UIImage!
    var other: UIImage!
    var color: UIColor!

    override func setUpWithError() throws {
        fixtureBundle = Bundle.module
        shape = UIImage(named: "splash-rounded-100", in: fixtureBundle, with: nil)
        other = UIImage(named: "splash-square-100", in: fixtureBundle, with: nil)
        color = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
    }

    /// The premultiplied RGBA bytes of an image, row major.
    func rgba(_ image: UIImage) -> [UInt8] {
        guard let cgImage = image.cgImage else {
            return []
        }
        let width = cgImage.width, height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColor.defaultRGBColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }

    /// Asserts that a chain and the equivalent sequence of `UIImage` calls produce the same image.
    func assertSame(_ chained: UIImage, _ sequential: UIImage, _ label: String,
                    tolerance: Int = ProcessorTests.tolerance,
                    file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(chained.size, sequential.size, "\(label): size", file: file, line: line)
        XCTAssertEqual(chained.scale, sequential.scale, "\(label): scale", file: file, line: line)
        XCTAssertEqual(chained.imageOrientation, sequential.imageOrientation, "\(label): orientation",
                       file: file, line: line)

        let left = rgba(chained), right = rgba(sequential)
        XCTAssertEqual(left.count, right.count, "\(label): buffer", file: file, line: line)
        guard left.count == right.count, !left.isEmpty else {
            return
        }

        let worst = zip(left, right).map { abs(Int($0) - Int($1)) }.max() ?? 0
        XCTAssertLessThanOrEqual(worst, tolerance, "\(label): components differ by \(worst)",
                                 file: file, line: line)
    }

    /// Every operation, one at a time, against its `UIImage` counterpart.
    func testEachOperationMatchesItsCounterpart() throws {
        let source = shape!
        let second = other!
        let steps: [(String, (UIImage.Processor) -> UIImage.Processor, (UIImage) -> UIImage)] = [
            ("colorized", { $0.colorized(with: self.color) }, { $0.colorized(with: self.color) }),
            ("expanded", { $0.expanded(bySize: 3, each: 30) }, { $0.expanded(bySize: 3, each: 30) }),
            ("stroked", { $0.stroked(with: self.color, size: 3, each: 30) },
             { $0.stroked(with: self.color, size: 3, each: 30) }),
            ("stroked alpha", { $0.stroked(with: self.color, size: 3, each: 30, alpha: 0.5) },
             { $0.stroked(with: self.color, size: 3, each: 30, alpha: 0.5) }),
            ("smoothened", { $0.smoothened(by: 2) }, { $0.smoothened(by: 2) }),
            ("smoothened sizeKept", { $0.smoothened(by: 2, sizeKept: true) },
             { $0.smoothened(by: 2, sizeKept: true) }),
            ("colorInverted", { $0.colorInverted() }, { $0.colorInverted() }),
            ("withAlphaComponent", { $0.withAlphaComponent(0.5) }, { $0.withAlphaComponent(0.5) }),
            ("scaled(to:)", { $0.scaled(to: CGSize(width: 40, height: 60)) },
             { $0.scaled(to: CGSize(width: 40, height: 60)) }),
            ("scaled(uniform:)", { $0.scaled(uniform: 0.5) }, { $0.scaled(uniform: 0.5) }),
            ("scaledWidth", { $0.scaledWidth(to: 40) }, { $0.scaledWidth(to: 40) }),
            ("scaledHeight", { $0.scaledHeight(to: 40) }, { $0.scaledHeight(to: 40) }),
            ("cropped", { $0.cropped(to: CGRect(x: 10, y: 10, width: 30, height: 20)) },
             { $0.cropped(to: CGRect(x: 10, y: 10, width: 30, height: 20)) }),
            ("rotated", { $0.rotated(by: 30) }, { $0.rotated(by: 30) }),
            ("flippedHorizontally", { $0.flippedHorizontally() }, { $0.flippedHorizontally() }),
            ("flippedVertically", { $0.flippedVertically() }, { $0.flippedVertically() }),
            ("drawnUnder", { $0.drawnUnder(image: second) }, { $0.drawnUnder(image: second) }),
            ("drawnAbove", { $0.drawnAbove(image: second) }, { $0.drawnAbove(image: second) }),
            ("alphaExclusion", { $0.alphaExclusion(with: second) }, { $0.alphaExclusion(with: second) })
        ]

        for (name, chained, sequential) in steps {
            assertSame(source.processed(chained), sequential(source), name)
        }
    }

    /// Several Core Image steps in a row, which is the case the whole thing exists for.
    func testChainMatchesTheSequence() throws {
        let source = shape!
        assertSame(source.processed { $0.colorized(with: self.color).expanded(bySize: 4, each: 30) },
                   source.colorized(with: color).expanded(bySize: 4, each: 30),
                   "colorized + expanded")

        assertSame(source.processed { $0.colorized(with: self.color).smoothened(by: 2) },
                   source.colorized(with: color).smoothened(by: 2),
                   "colorized + smoothened, across working spaces")

        assertSame(source.processed { $0.smoothened(by: 2).colorized(with: self.color) },
                   source.smoothened(by: 2).colorized(with: color),
                   "smoothened + colorized, across working spaces")

        // Inverting converts through Core Image's linear working space, which magnifies the intermediate 8-bit
        // rounding the sequence does and the chain does not: measured at 4 units of 255, everywhere on the image
        // and also once composited over an opaque background. The chain is the side doing one rounding less.
        assertSame(source.processed {
                       $0.colorized(with: self.color).expanded(bySize: 3, each: 30).colorInverted()
                   },
                   source.colorized(with: color).expanded(bySize: 3, each: 30).colorInverted(),
                   "three steps", tolerance: Self.looseTolerance)
    }

    /// A step Core Image cannot express the same way renders what came before and continues from it, so mixing the
    /// two kinds has to keep working.
    func testChainMixingRenderedSteps() throws {
        let source = shape!
        assertSame(source.processed { $0.colorized(with: self.color).scaled(uniform: 0.5).expanded(bySize: 2) },
                   source.colorized(with: color).scaled(uniform: 0.5).expanded(bySize: 2),
                   "colorized + scaled + expanded")

        assertSame(source.processed { $0.rotated(by: 20).stroked(with: self.color, size: 2, each: 45) },
                   source.rotated(by: 20).stroked(with: self.color, size: 2, each: 45),
                   "rotated + stroked")
    }

    /// The expansion has no recipe form when a CPU implementation is selected, so the chain has to fall back to it.
    func testChainHonorsTheExpandImplementation() throws {
        let source = shape!
        let color = color!
        for implementation in [UIImage.ExpandImplementation.basic, .concurrent] {
            UIImage.$_expandImplementation.withValue(implementation) {
                // `.concurrent` composites its layers in whatever order they finish, so it does not reproduce itself
                // either: two direct calls measured 3 units apart. Holding the chain to the strict tolerance would be
                // measuring that, so it gets the loose one, and the noise floor is asserted right below.
                let tolerance = implementation == .concurrent ? Self.looseTolerance : Self.tolerance

                assertSame(source.processed { $0.expanded(bySize: 3, each: 45) },
                           source.expanded(bySize: 3, each: 45),
                           "expanded \(implementation)", tolerance: tolerance)
                assertSame(source.processed { $0.stroked(with: color, size: 3, each: 45) },
                           source.stroked(with: color, size: 3, each: 45),
                           "stroked \(implementation)", tolerance: tolerance)

                if implementation == .concurrent {
                    assertSame(source.stroked(with: color, size: 3, each: 45),
                               source.stroked(with: color, size: 3, each: 45),
                               "stroked concurrent against itself", tolerance: Self.looseTolerance)
                }
            }
        }
    }

    /// An oriented source is handled the way every other operation handles it.
    func testChainKeepsOrientation() throws {
        for orientation in [UIImage.Orientation.up, .down, .left, .rightMirrored] {
            let source = UIImage(cgImage: shape.cgImage!, scale: shape.scale, orientation: orientation)
            assertSame(source.processed { $0.colorized(with: self.color).expanded(bySize: 3, each: 30) },
                       source.colorized(with: color).expanded(bySize: 3, each: 30),
                       "colorized + expanded \(orientation)")
            assertSame(source.processed { $0.stroked(with: self.color, size: 3, each: 30) },
                       source.stroked(with: self.color, size: 3, each: 30),
                       "stroked \(orientation)")
        }
    }

    /// The options follow the receiver, as they do through every other operation.
    func testChainPreservesOptions() throws {
        let source = shape
            .withRenderingMode(.alwaysOriginal)
            .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        let output = source.processed { $0.colorized(with: self.color).expanded(bySize: 2, each: 90) }

        XCTAssertEqual(output.renderingMode, source.renderingMode)
        XCTAssertEqual(output.alignmentRectInsets, source.alignmentRectInsets)
        XCTAssertEqual(output.scale, source.scale)
    }

    /// A dynamic participant makes the whole chain fan out once, not every step of it, and the result still follows
    /// the environment.
    func testChainFansOutOnceOverColorTraits() throws {
        let dynamicColor = UIColor.systemPink
        let output = shape.processed { $0.colorized(with: dynamicColor).expanded(bySize: 2, each: 90) }
        XCTAssertTrue(output._colorTraitVariance.varies, "a dynamic color has to produce a dynamic image")

        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UIImage._colorTraitCollection(style: style, contrast: .unspecified, scale: shape.scale)
            let resolved = output.imageAsset!.image(with: traits)
            let expected = shape
                .colorized(with: dynamicColor.resolvedColor(with: traits))
                .expanded(bySize: 2, each: 90)
            assertSame(resolved, expected, "variant \(style.rawValue)")
        }

        // The two variants have to actually differ, otherwise the comparison above proves nothing.
        let light = output.imageAsset!.image(with: UIImage._colorTraitCollection(style: .light,
                                                                                 contrast: .unspecified,
                                                                                 scale: shape.scale))
        let dark = output.imageAsset!.image(with: UIImage._colorTraitCollection(style: .dark,
                                                                                contrast: .unspecified,
                                                                                scale: shape.scale))
        XCTAssertNotEqual(rgba(light), rgba(dark), "the variants must not be identical")
    }

    /// An invariant chain stays a plain image, the fan-out is not paid for nothing.
    func testChainWithoutVarianceStaysStatic() throws {
        let plain = UIImage(cgImage: shape.cgImage!, scale: shape.scale, orientation: .up)
        let output = plain.processed { $0.colorized(with: self.color).expanded(bySize: 2, each: 90) }

        // Not `imageAsset == nil`: `withOptions(from:)` leaves a derived asset behind on every output. What has to
        // be true is that the result does not resolve differently for the traits.
        XCTAssertFalse(output._colorTraitVariance.varies,
                       "nothing varies, so the output must not follow the environment")
    }

    /// A chain nested inside an operation that is already fanning out must not fan out again.
    func testChainDoesNotRecurse() throws {
        UIImage._isFanningOutOverColorTraits = true
        defer { UIImage._isFanningOutOverColorTraits = false }

        let output = shape.processed { $0.colorized(with: .systemPink) }
        XCTAssertFalse(output._colorTraitVariance.varies, "a nested chain has to decline the fan-out")
        XCTAssertTrue(UIImage._isFanningOutOverColorTraits, "the flag has to be left as it was found")
    }

    /// Like every other operation, the chain degrades instead of trapping.
    func testChainDegradesWithoutABuffer() throws {
        let ciBacked = UIImage(ciImage: CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4)))
        XCTAssertNil(ciBacked.cgImage)

        let output = ciBacked.processed {
            $0.colorized(with: self.color).expanded(bySize: 2).smoothened(by: 1).colorInverted()
        }
        XCTAssertNotNil(output)
        XCTAssertEqual(output.size, ciBacked.size)
    }

    /// An empty chain is the image itself.
    func testEmptyChain() throws {
        assertSame(shape.processed { $0 }, shape, "empty")
    }

}
