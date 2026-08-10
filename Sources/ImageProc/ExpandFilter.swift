//
//  ExpandFilter.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/08/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import CoreImage

/// An image processor that replicates the opaque pixels of an image all around the origin.
///
/// The ExpandFilter class produces a CIImage object as output. The filter takes an image, a radius in pixels and the
/// directions to replicate towards. The output extent is the input one grown by the radius on every side.
///
/// Where the CPU implementations scatter one translated copy per direction into a layer and composite the layers, the
/// kernel gathers: each output pixel reads the ring of source samples around itself and keeps the most opaque one. It
/// needs no intermediate buffer and, `max` being commutative, its result does not depend on the order the directions
/// happen to be visited in.
internal class ExpandFilter: CIFilter {

    /// The original input image as a `CIImage`.
    var inputImage: CIImage?

    /// The distance to replicate to, in pixels.
    var inputRadius: CGFloat = 0

    /// The directions to replicate towards, in degrees, as a step between 0 and 360.
    var inputDegreeStep: CGFloat = 3

    /// The Metal function name.
    private static let functionName = "expand"

    /// The Metal kernel, or `nil` when the compiled library could not be loaded.
    private static let kernel: CIKernel? = {
        return KernelLoader.loadGeneralFunction(named: functionName)
    }()

    /// Whether the kernel is available, and so whether this filter can produce anything at all.
    static var isAvailable: Bool {
        return kernel != nil
    }

    /// The resulting image, or `nil` when the kernel is unavailable.
    override var outputImage: CIImage? {
        guard let kernel = ExpandFilter.kernel, let inputImage else {
            return nil
        }

        let radius = inputRadius
        let count = (360.0 / inputDegreeStep).rounded(.up)
        let extent = inputImage.extent.insetBy(dx: -radius, dy: -radius)
        let arguments = [inputImage, radius, count, inputDegreeStep] as [Any]

        // Every output pixel reads the ring of radius `radius` around itself, so the region of interest is the
        // requested rect grown by that much. Core Image clips silently rather than complaining when this is short,
        // which shows up as an expansion that stops at the edges of the source.
        return kernel.apply(extent: extent, roiCallback: { _, rect in
            return rect.insetBy(dx: -radius, dy: -radius)
        }, arguments: arguments)
    }
}
