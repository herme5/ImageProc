//
//  Tags.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import Foundation
import Testing

extension Tag {
    /// Times something and prints the result, asserting nothing about it.
    @Tag static var benchmark: Self
    /// Compares the internal expansion implementations, which package users cannot select.
    @Tag static var implementations: Self
    /// Holds an operation to the image orientation contract.
    @Tag static var orientation: Self
    /// Holds an operation to the dynamic color contract.
    @Tag static var traits: Self
}

enum Benchmarks {
    /// Benchmarks run unless `SKIP_BENCHMARKS` is set. CI sets `TEST_RUNNER_SKIP_BENCHMARKS`, which `xcodebuild`
    /// forwards to the test process with the prefix stripped: they take over a minute on a hosted runner, and nobody
    /// reads timings from a log.
    static let enabled = ProcessInfo.processInfo.environment["SKIP_BENCHMARKS"] == nil

    /// Runs the body once to warm it up, then times it over several runs and returns the median in milliseconds.
    ///
    /// `DispatchTime` rather than `ContinuousClock`, which needs iOS 16 where the package supports iOS 15.
    static func median(runs: Int = 5, _ body: () -> Void) -> Double {
        body()
        let durations = (0..<runs).map { _ -> UInt64 in
            let start = DispatchTime.now().uptimeNanoseconds
            body()
            return DispatchTime.now().uptimeNanoseconds - start
        }.sorted()
        return Double(durations[runs / 2]) / 1_000_000
    }
}
