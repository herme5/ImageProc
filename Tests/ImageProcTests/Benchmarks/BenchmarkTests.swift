//
//  BenchmarkTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Timings, printed rather than asserted: they depend on the machine, and on a shared CI runner from one run to the
/// next. Skipped when `SKIP_BENCHMARKS` is set, see `Benchmarks.enabled`.
///
/// `.serialized` only orders these tests among themselves: the other suites still run beside them and compete for the
/// CPU and the GPU. For numbers worth comparing, run this suite alone with
/// `-only-testing:ImageProcTests/BenchmarkTests`.
@Suite("Benchmarks", .tags(.benchmark), .enabled(if: Benchmarks.enabled), .serialized)
struct BenchmarkTests {

    static let iterations = 10_000

    @Test("UIColor creation and hexadecimal codes")
    func colors() {
        let random = Benchmarks.median { for _ in 0..<Self.iterations { _ = UIColor.random() } }
        let fromCode = Benchmarks.median {
            for _ in 0..<Self.iterations { _ = UIColor(hexCode: HexadecimalHelper.randomCode()) }
        }
        let toCode = Benchmarks.median { for _ in 0..<Self.iterations { _ = UIColor.random().cgColor.hexCode } }
        print(String(format: "BENCH colors ×%d  random %.2f ms  from code %.2f ms  to code %.2f ms",
                     Self.iterations, random, fromCode, toCode))
    }

    @Test("Operations on a 100 point image")
    func operations() {
        let shape = Fixture.catalog(.splashRounded)
        let timings: [(String, Double)] = [
            ("colorized", Benchmarks.median { _ = shape.colorized(with: .systemIndigo) }),
            ("expanded", Benchmarks.median { _ = shape.expanded(bySize: 20) }),
            ("stroked", Benchmarks.median { _ = shape.stroked(with: .black, size: 20) }),
            ("processed", Benchmarks.median {
                _ = shape.processed { $0.colorized(with: .systemIndigo).expanded(bySize: 20).smoothened(by: 2) }
            }),
            ("sequence", Benchmarks.median {
                _ = shape.colorized(with: .systemIndigo).expanded(bySize: 20).smoothened(by: 2)
            })
        ]
        for (name, milliseconds) in timings {
            print(String(format: "BENCH %-10@ %8.2f ms", name as NSString, milliseconds))
        }
    }

    /// The three expansion implementations against each other. Metal is flat in the number of angles where the CPU
    /// paths are linear in it, and the ordering reverses at few angles, where the GPU round trip dominates.
    @Test("Expansion implementations", .tags(.implementations))
    func expansionImplementations() {
        let implementations: [UIImage.ExpandImplementation] = [.basic, .concurrent, .metal]
        print("BENCH  size  degree      basic  concurrent      metal")

        for side in [CGFloat(100), 500, 1000] {
            let source = Fixture.render(size: CGSize(width: side, height: side)) { context in
                context.setFillColor(UIColor.red.cgColor)
                context.fillEllipse(in: CGRect(x: side * 0.1, y: side * 0.1, width: side * 0.8, height: side * 0.8))
            }
            for degree in [CGFloat(90), 10, 3] {
                let timings = implementations.map { implementation in
                    UIImage.$_expandImplementation.withValue(implementation) {
                        Benchmarks.median(runs: 1) { _ = source.expanded(bySize: 20, each: degree) }
                    }
                }
                print(String(format: "BENCH %5.0f  %6.0f  ", side, degree)
                      + timings.map { String(format: "%9.2f", $0) }.joined(separator: "  "))
            }
        }
    }
}
