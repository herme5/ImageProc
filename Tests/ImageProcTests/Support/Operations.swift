//
//  Operations.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Every public image operation, with arguments that suit any fixture of a few dozen points.
///
/// The guarantees every operation owes — degrading instead of trapping, carrying the receiver's options, honouring
/// orientation, matching its chained form — are tested once, over this list. A new public operation is added here and
/// is held to all of them.
struct Operation: Sendable, CustomTestStringConvertible {

    let name: String

    /// Applies the operation. The second image is only used by the composites.
    let apply: @Sendable (UIImage, UIImage) -> UIImage

    /// The same operation as a step of `processed(_:)`.
    let chained: @Sendable (UIImage.Processor, UIImage) -> UIImage.Processor

    /// Whether the operation takes a second image.
    let isComposite: Bool

    /// Whether it has to run on a single-colored source to be compared across orientations. See `Fixture.shape`.
    let needsSingleColorSource: Bool

    var testDescription: String { name }

    func callAsFunction(_ image: UIImage, with other: UIImage = Fixture.disc()) -> UIImage {
        return apply(image, other)
    }

    /// An invariant color: a system color would make every output dynamic, which `TraitTests` covers on its own.
    static let color = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)

    private init(_ name: String, isComposite: Bool = false, needsSingleColorSource: Bool = false,
                 apply: @escaping @Sendable (UIImage, UIImage) -> UIImage,
                 chained: @escaping @Sendable (UIImage.Processor, UIImage) -> UIImage.Processor) {
        self.name = name
        self.apply = apply
        self.chained = chained
        self.isComposite = isComposite
        self.needsSingleColorSource = needsSingleColorSource
    }

    static let all: [Operation] = [
        Operation("colorized",
                  apply: { image, _ in image.colorized(with: color) },
                  chained: { chain, _ in chain.colorized(with: color) }),
        Operation("expanded", needsSingleColorSource: true,
                  apply: { image, _ in image.expanded(bySize: 2, each: 30) },
                  chained: { chain, _ in chain.expanded(bySize: 2, each: 30) }),
        Operation("stroked", needsSingleColorSource: true,
                  apply: { image, _ in image.stroked(with: color, size: 2, each: 30) },
                  chained: { chain, _ in chain.stroked(with: color, size: 2, each: 30) }),
        Operation("stroked(alpha:)", needsSingleColorSource: true,
                  apply: { image, _ in image.stroked(with: color, size: 2, each: 30, alpha: 0.5) },
                  chained: { chain, _ in chain.stroked(with: color, size: 2, each: 30, alpha: 0.5) }),
        Operation("smoothened",
                  apply: { image, _ in image.smoothened(by: 2) },
                  chained: { chain, _ in chain.smoothened(by: 2) }),
        Operation("smoothened(sizeKept:)",
                  apply: { image, _ in image.smoothened(by: 2, sizeKept: true) },
                  chained: { chain, _ in chain.smoothened(by: 2, sizeKept: true) }),
        Operation("colorInverted",
                  apply: { image, _ in image.colorInverted() },
                  chained: { chain, _ in chain.colorInverted() }),
        Operation("withAlphaComponent",
                  apply: { image, _ in image.withAlphaComponent(0.5) },
                  chained: { chain, _ in chain.withAlphaComponent(0.5) }),
        Operation("scaled(to:)",
                  apply: { image, _ in image.scaled(to: CGSize(width: 10, height: 20)) },
                  chained: { chain, _ in chain.scaled(to: CGSize(width: 10, height: 20)) }),
        Operation("scaled(uniform:)",
                  apply: { image, _ in image.scaled(uniform: 0.5) },
                  chained: { chain, _ in chain.scaled(uniform: 0.5) }),
        Operation("scaledWidth(to:)",
                  apply: { image, _ in image.scaledWidth(to: 12) },
                  chained: { chain, _ in chain.scaledWidth(to: 12) }),
        Operation("scaledHeight(to:)",
                  apply: { image, _ in image.scaledHeight(to: 12) },
                  chained: { chain, _ in chain.scaledHeight(to: 12) }),
        Operation("cropped",
                  apply: { image, _ in image.cropped(to: CGRect(x: 2, y: 1, width: 8, height: 4)) },
                  chained: { chain, _ in chain.cropped(to: CGRect(x: 2, y: 1, width: 8, height: 4)) }),
        Operation("rotated(by: 90)",
                  apply: { image, _ in image.rotated(by: 90) },
                  chained: { chain, _ in chain.rotated(by: 90) }),
        Operation("rotated(by: 30)",
                  apply: { image, _ in image.rotated(by: 30) },
                  chained: { chain, _ in chain.rotated(by: 30) }),
        Operation("flippedHorizontally",
                  apply: { image, _ in image.flippedHorizontally() },
                  chained: { chain, _ in chain.flippedHorizontally() }),
        Operation("flippedVertically",
                  apply: { image, _ in image.flippedVertically() },
                  chained: { chain, _ in chain.flippedVertically() }),
        Operation("drawnUnder", isComposite: true,
                  apply: { image, other in image.drawnUnder(image: other) },
                  chained: { chain, other in chain.drawnUnder(image: other) }),
        Operation("drawnAbove", isComposite: true,
                  apply: { image, other in image.drawnAbove(image: other) },
                  chained: { chain, other in chain.drawnAbove(image: other) }),
        Operation("alphaExclusion", isComposite: true,
                  apply: { image, other in image.alphaExclusion(with: other) },
                  chained: { chain, other in chain.alphaExclusion(with: other) })
    ]

    static var composites: [Operation] {
        return all.filter(\.isComposite)
    }

    static var unary: [Operation] {
        return all.filter { !$0.isComposite }
    }
}

/// The eight image orientations, named for the test output.
struct Orientation: Sendable, CustomTestStringConvertible {
    let value: UIImage.Orientation
    let testDescription: String

    static let all: [Orientation] = [
        Orientation(value: .up, testDescription: "up"),
        Orientation(value: .down, testDescription: "down"),
        Orientation(value: .left, testDescription: "left"),
        Orientation(value: .right, testDescription: "right"),
        Orientation(value: .upMirrored, testDescription: "upMirrored"),
        Orientation(value: .downMirrored, testDescription: "downMirrored"),
        Orientation(value: .leftMirrored, testDescription: "leftMirrored"),
        Orientation(value: .rightMirrored, testDescription: "rightMirrored")
    ]
}
