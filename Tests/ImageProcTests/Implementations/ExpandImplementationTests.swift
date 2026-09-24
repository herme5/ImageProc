//
//  ExpandImplementationTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 10/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// The expansion has three implementations: a Metal kernel that gathers, which is the one package users get, and two
/// CPU ones that scatter, kept to be measured against it. They have to agree on the shape they produce, whatever they
/// disagree on internally.
///
/// Each test picks an implementation with `UIImage.$_expandImplementation.withValue`, which is scoped to the test, so
/// the other suites keep running on the default while these run beside them.
@Suite("Expansion implementations", .tags(.implementations))
struct ExpandImplementationTests {

    typealias Implementation = UIImage.ExpandImplementation

    func expanded(_ image: UIImage, using implementation: Implementation, by delta: CGFloat,
                  each degree: CGFloat) -> UIImage {
        return UIImage.$_expandImplementation.withValue(implementation) {
            image.expanded(bySize: delta, each: degree)
        }
    }

    @Test("every implementation produces the same canvas", arguments: [Implementation.metal, .concurrent])
    func everyImplementationProducesTheSameCanvas(_ implementation: Implementation) throws {
        for fixture in [Fixture.ellipse(), Fixture.thinCross()] {
            let reference = try #require(Bitmap(expanded(fixture, using: .basic, by: 4, each: 90)))
            let output = try #require(Bitmap(expanded(fixture, using: implementation, by: 4, each: 90)))
            #expect(output.width == reference.width && output.height == reference.height)
        }
    }

    /// Both are the union of the same translated copies, so the set of pixels they touch has to match. This is what
    /// proves the kernel's ring geometry and its region of interest, and it holds for the thin fixture too — which it
    /// would not if the kernel had been swapped for a filled-disc dilation.
    @Test("Metal covers the same region as the reference", arguments: [CGFloat(90), 45, 10])
    func metalCoversTheSameRegionAsTheReference(each degree: CGFloat) throws {
        for (name, fixture) in [("solid", Fixture.ellipse()), ("thin", Fixture.thinCross())] {
            let reference = try #require(Bitmap(expanded(fixture, using: .basic, by: 4, each: degree))).alphas
            let metal = try #require(Bitmap(expanded(fixture, using: .metal, by: 4, each: degree))).alphas
            try #require(metal.count == reference.count, "\(name)")

            // Compare the supports, ignoring the faintest antialiasing where the two differ by construction.
            let threshold = UInt8(24)
            let differing = zip(metal, reference).filter { ($0 > threshold) != ($1 > threshold) }.count
            let covered = reference.filter { $0 > threshold }.count
            #expect(covered > 0, "\(name): the reference covers nothing")
            #expect(Double(differing) / Double(covered) < 0.02, "\(name): \(differing) of \(covered) pixels disagree")
        }
    }

    /// `max` is commutative, so unlike the concurrent path the kernel gives the same answer every time even when the
    /// overlapping copies carry different colors.
    @Test("Metal is deterministic on a multi-colored source")
    func metalIsDeterministicOnAMultiColoredSource() throws {
        let first = try #require(Bitmap(expanded(Fixture.stripes(), using: .metal, by: 3, each: 30)))
        for _ in 0..<4 {
            let again = try #require(Bitmap(expanded(Fixture.stripes(), using: .metal, by: 3, each: 30)))
            #expect(again.bytes == first.bytes)
        }
    }

    /// `stroked` goes through the same choke point, so it picks up the implementation without changing its call site.
    @Test("stroking goes through the same choke point", arguments: [Implementation.metal, .concurrent, .basic])
    func strokingGoesThroughTheSameChokePoint(_ implementation: Implementation) {
        let fixture = Fixture.ellipse()
        let stroked = UIImage.$_expandImplementation.withValue(implementation) {
            fixture.stroked(with: .red, size: 3, each: 90)
        }
        #expect(stroked.size == CGSize(width: fixture.size.width + 6, height: fixture.size.height + 6))
    }

    /// The expansion has no recipe form when a CPU implementation is selected, so the chain has to fall back to it.
    @Test("a chain falls back to a CPU implementation", arguments: [Implementation.basic, .concurrent])
    func aChainFallsBackToACPUImplementation(_ implementation: Implementation) {
        let shape = Fixture.catalog(.splashRounded)
        let color = Operation.color
        // `.concurrent` does not reproduce itself, so holding the chain to the strict tolerance would be measuring
        // that. The noise floor itself is asserted right below.
        let tolerance = implementation == .concurrent ? Tolerance.concurrentExpansion : Tolerance.rounding

        UIImage.$_expandImplementation.withValue(implementation) {
            #expect(mismatch(shape.processed { $0.expanded(bySize: 3, each: 45) },
                             shape.expanded(bySize: 3, each: 45), tolerance: tolerance) == nil)
            #expect(mismatch(shape.processed { $0.stroked(with: color, size: 3, each: 45) },
                             shape.stroked(with: color, size: 3, each: 45), tolerance: tolerance) == nil)
            if implementation == .concurrent {
                #expect(mismatch(shape.stroked(with: color, size: 3, each: 45),
                                 shape.stroked(with: color, size: 3, each: 45),
                                 tolerance: Tolerance.concurrentExpansion) == nil, "against itself")
            }
        }
    }
}
