//
//  OptionsTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

/// Every operation returns an image that looks like its receiver: rendering mode, alignment insets, configuration,
/// baseline offset and scale are carried over. `drawnAbove` used to lose all of them, because it was implemented by
/// swapping the two images around `drawnUnder`, which made the argument the receiver.
///
/// The operations use an invariant color: a system color varies with the color traits, which makes the output dynamic,
/// and a dynamic image cannot carry a baseline offset. `TraitTests` covers that case.
@Suite("Options")
struct OptionsTests {

    static func source(scale: CGFloat) -> UIImage {
        let shape = Fixture.catalog(.splashRounded)
        let source = UIImage(cgImage: shape.cgImage!, scale: scale, orientation: .up)
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
            .withBaselineOffset(fromBottom: 10)

        // Applying a configuration resolves it against the current trait environment, so round-trip the source once
        // to compare a resolved configuration with a resolved one.
        return source.withConfiguration(source.configuration!)
    }

    /// The other image deliberately has a different scale, to catch an output rendered in its space.
    static func other(scale: CGFloat) -> UIImage {
        return UIImage(cgImage: Fixture.catalog(.splashSquare).cgImage!, scale: scale + 1, orientation: .up)
    }

    @Test("the receiver's options are carried over", arguments: Operation.all, [CGFloat(2), 3])
    func theReceiversOptionsAreCarriedOver(_ operation: Operation, scale: CGFloat) {
        let source = Self.source(scale: scale)
        let output = operation(source, with: Self.other(scale: scale))

        #expect(output.scale == source.scale)
        #expect(output.renderingMode == source.renderingMode)
        #expect(output.alignmentRectInsets == source.alignmentRectInsets)
        #expect(output.baselineOffsetFromBottom == source.baselineOffsetFromBottom)
        #expect(output.configuration == source.configuration)
    }
}
