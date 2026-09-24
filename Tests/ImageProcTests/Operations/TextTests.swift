//
//  TextTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 24/09/2026.
//  Copyright © 2026 Andrea Ruffino. All rights reserved.
//

import UIKit
import Testing
@testable import ImageProc

@Suite("Text")
struct TextTests {

    static let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24)]

    @Test("text renders at the size it needs")
    func textRendersAtTheSizeItNeeds() throws {
        let text = NSAttributedString(string: "hello", attributes: Self.attributes)
        let image = try #require(UIImage(text: text))
        // The renderer rounds the size the text needs up to whole pixels.
        let needed = text.size()
        #expect(image.size.width >= needed.width && image.size.width - needed.width < 1)
        #expect(image.size.height >= needed.height && image.size.height - needed.height < 1)
        #expect(try #require(image.opaquePixelDensity) > 0)
    }

    @Test("a plain string renders with its attributes")
    func aPlainStringRendersWithItsAttributes() throws {
        let plain = try #require(UIImage(text: "hello"))
        let large = try #require(UIImage(text: "hello", attributes: Self.attributes))
        #expect(large.size.height > plain.size.height)
    }

    @Test("an explicit size wins over the size the text needs")
    func anExplicitSizeWinsOverTheSizeTheTextNeeds() {
        #expect(UIImage(text: "hello", size: CGSize(width: 40, height: 20))?.size == CGSize(width: 40, height: 20))
    }

    @Test("nothing to draw means no image, rather than an empty one")
    func nothingToDrawMeansNoImage() {
        #expect(UIImage(text: "") == nil)
        #expect(UIImage(text: "hello", size: .zero) == nil)
    }
}
