//
//  CIContextExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 22/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import CoreImage

internal extension CIContext {

    /// Shared across renders on purpose: building a `CIContext` costs tens of milliseconds (Metal device handle,
    /// command queue, pipeline cache, texture pool), which dwarfed the render itself when it was done per call.
    /// `CIContext` is documented as safe to use from several threads, and a `static let` is initialized once.
    ///
    /// Intermediates are not cached because these are one-shot renders — nothing is worth keeping between two of
    /// them — which also bounds what a context living for the whole process holds on to. The name labels the Core
    /// Image track in Instruments.
    static let rgbWorkingSpace = CIContext(options: [
        .workingColorSpace: CGColor.defaultRGBColorSpace,
        .cacheIntermediates: false,
        .name: "ImageProc.rgb"])

    /// The counterpart for the operations that never named a working color space. Core Image's default is not
    /// `CGColor.defaultRGBColorSpace`, and a gaussian blur or a color inversion is sensitive to it, so those keep
    /// rendering through this one rather than through `rgbWorkingSpace`.
    static let defaultWorkingSpace = CIContext(options: [
        .cacheIntermediates: false,
        .name: "ImageProc.default"])
}
