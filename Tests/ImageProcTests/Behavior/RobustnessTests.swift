//
//  RobustnessTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// No operation traps. What cannot be processed comes back unchanged, with a message printed.
@Suite("Robustness")
struct RobustnessTests {

    /// `withAlphaComponent` is the exception: it redraws through UIKit, which can draw a `CIImage` backed image, so it
    /// does produce a new one.
    @Test("an image without a bitmap comes back unchanged", arguments: Operation.all)
    func anImageWithoutABitmapComesBackUnchanged(_ operation: Operation) {
        let source = Fixture.ciBacked()
        let output = operation(source, with: Fixture.disc())
        if operation.name == "withAlphaComponent" {
            #expect(output.size == source.size)
        } else {
            #expect(output === source)
        }
    }

    @Test("a second image without a bitmap leaves the receiver unchanged", arguments: Operation.composites)
    func aSecondImageWithoutABitmapLeavesTheReceiverUnchanged(_ operation: Operation) {
        let source = Fixture.blocks()
        #expect(operation(source, with: Fixture.ciBacked()) === source)
    }

    @Test("a chain without a bitmap comes back at the same size")
    func aChainWithoutABitmapComesBackAtTheSameSize() {
        let source = Fixture.ciBacked()
        let output = source.processed { $0.colorized(with: .red).expanded(bySize: 2).smoothened(by: 1).colorInverted() }
        #expect(output.size == source.size)
    }

    @Test("inspecting an image without a bitmap gives nothing")
    func inspectingAnImageWithoutABitmapGivesNothing() {
        let source = Fixture.ciBacked()
        #expect(source.opaquePixelDensity == nil)
        #expect(source.withBitmapAsUIColorArray { $0 } == nil)
    }

    @Test("a fully transparent color does not trap")
    func aFullyTransparentColorDoesNotTrap() {
        let source = Fixture.centeredSquare()
        let clear = UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0"))
        #expect(source.colorized(with: clear).size == source.size)
        #expect(source.stroked(with: clear, size: 1).size == CGSize(width: 18, height: 18))
    }

    // MARK: Kernels

    /// The kernels ship as a package resource compiled by the CIKernelCompiler plugin. Loading them used to be a
    /// fatalError, which is how the CocoaPods distribution came to crash instead of degrading, so an unresolvable
    /// function must simply return nil.
    @Test("the kernels load, and an unknown one is nil rather than a trap")
    func theKernelsLoadAndAnUnknownOneIsNil() {
        #expect(KernelLoader.loadFunction(named: "colorize") != nil)
        #expect(KernelLoader.loadFunction(named: "exclude") != nil)
        #expect(KernelLoader.loadFunction(named: "thisFunctionDoesNotExist") == nil)
    }

    /// The expansion samples its neighbours, which a `CIColorKernel` may not do, so it has to load as a general one.
    @Test("the expansion kernel loads as a general kernel")
    func theExpansionKernelLoadsAsAGeneralKernel() {
        #expect(KernelLoader.loadGeneralFunction(named: "expand") != nil)
        #expect(KernelLoader.loadGeneralFunction(named: "thisFunctionDoesNotExist") == nil)
        #expect(ExpandFilter.isAvailable)
    }

    /// The filters used to force unwrap their inputs, so an input Core Image would not take reached the caller as a
    /// trap rather than as the source image unchanged. `ColorFilter` got there for real: `CIColor(color:)` is annotated
    /// non-optional on iOS, yet returns nil for a color in a device-dependent color space under the Mac runtime, and
    /// the nil landed silently in `inputColor`.
    @Test("a filter missing an input produces nothing rather than trapping")
    func aFilterMissingAnInputProducesNothing() throws {
        #expect(ColorFilter().outputImage == nil)
        #expect(ExcludeFilter().outputImage == nil)
        #expect(ExpandFilter().outputImage == nil)

        let cgImage = try #require(Fixture.centeredSquare().cgImage)
        let colorFilter = ColorFilter()
        colorFilter.inputImage = CIImage(cgImage: cgImage)
        #expect(colorFilter.outputImage == nil, "an unset color must not be forced")

        let excludeFilter = ExcludeFilter()
        excludeFilter.inputFirstImage = CIImage(cgImage: cgImage)
        #expect(excludeFilter.outputImage == nil, "an unset second image must not be forced")
    }

    /// A monochrome color still has to produce a color the kernel can take, which is what `_rgbCompliant(_:)` and the
    /// component-wise `CIColor` are for.
    @Test("a monochrome color reaches the kernel as RGB")
    func aMonochromeColorReachesTheKernelAsRGB() throws {
        let cgImage = try #require(Fixture.centeredSquare().cgImage)
        let filter = UIImage._colorizedFilter(color: .black, cgImage: cgImage)
        #expect((filter as? ColorFilter)?.inputColor != nil)
        #expect(filter.outputImage != nil)
    }
}
