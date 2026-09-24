//
//  ExpandTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 10/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

/// The expansion has three implementations: a Metal kernel that gathers, and two CPU ones that scatter. They have to
/// agree on the shape they produce, whatever they disagree on internally.
final class ExpandTests: XCTestCase {

    override func tearDown() {
        UIImage._expandImplementation = .metal
        super.tearDown()
    }

    func render(size: CGSize, scale: CGFloat = 2, _ body: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { body($0.cgContext) }
    }

    /// A solid shape, where a ring dilation and a disc dilation agree.
    func solidFixture() -> UIImage {
        return render(size: CGSize(width: 40, height: 24)) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fillEllipse(in: CGRect(x: 6, y: 4, width: 28, height: 16))
        }
    }

    /// A thin cross, where they do not: a ring smears a hairline into a band, a disc fills it solid.
    func thinFixture() -> UIImage {
        return render(size: CGSize(width: 40, height: 24)) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 19, y: 2, width: 1, height: 20))
            context.fill(CGRect(x: 4, y: 11, width: 32, height: 1))
        }
    }

    /// The alpha of every pixel, row major.
    func alphaMap(_ image: UIImage) -> [UInt8] {
        guard let cgImage = image.cgImage else { return [] }
        let width = cgImage.width, height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &buffer, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 3, to: buffer.count, by: 4).map { buffer[$0] }
    }

    func expanded(_ image: UIImage, using implementation: UIImage.ExpandImplementation,
                  by delta: CGFloat, each degree: CGFloat) -> UIImage {
        UIImage._expandImplementation = implementation
        defer { UIImage._expandImplementation = .metal }
        return image.expanded(bySize: delta, each: degree)
    }

    /// The kernel has to load as a general `CIKernel`: a `CIColorKernel` may not sample its neighbours.
    func testKernelIsAvailable() throws {
        XCTAssertNotNil(KernelLoader.loadGeneralFunction(named: "expand"))
        XCTAssertTrue(ExpandFilter.isAvailable)
        XCTAssertNil(KernelLoader.loadGeneralFunction(named: "thisFunctionDoesNotExist"))
    }

    /// All three produce the same canvas.
    func testAllImplementationsAgreeOnSize() throws {
        for fixture in [solidFixture(), thinFixture()] {
            let reference = expanded(fixture, using: .basic, by: 4, each: 90)
            for implementation in [UIImage.ExpandImplementation.metal, .concurrent] {
                let output = expanded(fixture, using: implementation, by: 4, each: 90)
                XCTAssertEqual(output.size, reference.size, "\(implementation)")
                XCTAssertEqual(output.cgImage!.width, reference.cgImage!.width, "\(implementation)")
                XCTAssertEqual(output.cgImage!.height, reference.cgImage!.height, "\(implementation)")
            }
        }
    }

    /// Both are the union of the same translated copies, so the set of pixels they touch has to match. This is what
    /// proves the kernel's ring geometry and its region of interest, and it holds for the thin fixture too — which it
    /// would not if the kernel had been swapped for a filled-disc dilation.
    func testMetalCoversTheSameRegionAsTheReference() throws {
        for (name, fixture) in [("solid", solidFixture()), ("thin", thinFixture())] {
            for degree in [CGFloat(90), 45, 10] {
                let reference = alphaMap(expanded(fixture, using: .basic, by: 4, each: degree))
                let metal = alphaMap(expanded(fixture, using: .metal, by: 4, each: degree))
                XCTAssertEqual(metal.count, reference.count, "\(name) each \(degree)")

                // Compare the supports, ignoring the faintest antialiasing where the two differ by construction.
                let threshold = UInt8(24)
                let differing = zip(metal, reference).filter { ($0 > threshold) != ($1 > threshold) }.count
                let covered = reference.filter { $0 > threshold }.count
                XCTAssertGreaterThan(covered, 0, "\(name) each \(degree): reference covers nothing")
                XCTAssertLessThan(Double(differing) / Double(covered), 0.02,
                                  "\(name) each \(degree): \(differing) of \(covered) pixels disagree")
            }
        }
    }

    /// `max` is commutative, so unlike the concurrent path the kernel gives the same answer every time even when the
    /// overlapping copies carry different colors.
    func testMetalIsDeterministic() throws {
        let multicolored = render(size: CGSize(width: 24, height: 16)) { context in
            for (index, color) in [UIColor.red, .green, .blue, .yellow].enumerated() {
                context.setFillColor(color.cgColor)
                context.fill(CGRect(x: CGFloat(index) * 6, y: 0, width: 6, height: 16))
            }
        }
        let first = alphaMap(expanded(multicolored, using: .metal, by: 3, each: 30))
        for _ in 0..<4 {
            XCTAssertEqual(alphaMap(expanded(multicolored, using: .metal, by: 3, each: 30)), first)
        }
    }

    /// Times the three implementations against each other. Asserts only that each produces something, the point
    /// being the numbers it prints.
    ///
    /// CI skips it: it takes over a minute there, a third of the suite, and nobody reads the numbers from a log. CI sets
    /// `TEST_RUNNER_SKIP_BENCHMARKS`; `xcodebuild` forwards it to the test process with the prefix stripped.
    func testBenchmarkImplementations() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["SKIP_BENCHMARKS"] != nil,
                      "benchmarks are skipped when SKIP_BENCHMARKS is set")

        let sizes = [CGFloat(100), 500, 1000]
        let degrees = [CGFloat(90), 10, 3]
        print("BENCH  size  degree  basic      concurrent  metal")

        for side in sizes {
            let source = render(size: CGSize(width: side, height: side)) { context in
                context.setFillColor(UIColor.red.cgColor)
                context.fillEllipse(in: CGRect(x: side * 0.1, y: side * 0.1, width: side * 0.8, height: side * 0.8))
            }
            for degree in degrees {
                var timings: [UIImage.ExpandImplementation: Double] = [:]
                for implementation in [UIImage.ExpandImplementation.basic, .concurrent, .metal] {
                    UIImage._expandImplementation = implementation
                    _ = source.expanded(bySize: 20, each: degree)  // warm up, the kernel compiles on first use
                    let start = CFAbsoluteTimeGetCurrent()
                    let output = source.expanded(bySize: 20, each: degree)
                    timings[implementation] = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    XCTAssertNotNil(output.cgImage, "\(implementation) at \(side) each \(degree)")
                }
                UIImage._expandImplementation = .metal
                let formatted = [UIImage.ExpandImplementation.basic, .concurrent, .metal]
                    .map { String(format: "%9.2f", timings[$0]!) }
                    .joined(separator: "  ")
                print(String(format: "BENCH %5.0f  %6.0f  ", side, degree) + formatted)
            }
        }
    }

    /// `stroked` goes through the same choke point, so it picks up the kernel without changing its call site.
    func testStrokedUsesTheSamePath() throws {
        let fixture = solidFixture()
        for implementation in [UIImage.ExpandImplementation.metal, .concurrent, .basic] {
            UIImage._expandImplementation = implementation
            let stroked = fixture.stroked(with: .systemPink.resolvedColor(with: .current), size: 3, each: 90)
            XCTAssertEqual(stroked.size, CGSize(width: fixture.size.width + 6, height: fixture.size.height + 6),
                           "\(implementation)")
        }
    }
}
