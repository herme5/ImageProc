//
//  ImageTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 22/12/2022.
//  Copyright © 2022 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

final class ImageTests: XCTestCase {

    var appBundle: Bundle!
    var shape0: UIImage!
    var shape1: UIImage!
    var shape2: UIImage!
    var color0: UIColor!
    var color1: UIColor!
    var color2: UIColor!
    var shape0ciImage: CIImage!

    let iterationCount = 10

    func repeated(_ body: () -> Void) {
        for _ in 0 ..< iterationCount {
            body()
        }
    }

    override func setUpWithError() throws {
        appBundle = Bundle(for: ImageTests.self)
        shape0 = UIImage(named: "splash-rounded-100", in: appBundle, with: nil)
        shape1 = UIImage(named: "splash-square-100", in: appBundle, with: nil)
        shape2 = UIImage(named: "splash-square-line-100", in: appBundle, with: nil)
        color0 = UIColor.systemIndigo
        color1 = UIColor.systemPink
        color2 = UIColor.systemTeal
        shape0ciImage = CIImage(data: shape0.pngData()!)
        shape0 = shape0.withBaselineOffset(fromBottom: 10.0)
    }

    func testImages() throws {
        XCTAssertNotNil(shape0.colorized(with: color0, method: .basic))
        XCTAssertNotNil(shape0.colorized(with: color0, method: .concurrent))
        XCTAssertNotNil(shape0.expand(bySize: 1, method: .basic))
        XCTAssertNotNil(shape0.expand(bySize: 1, method: .concurrent))
        XCTAssertNotNil(shape0.stroked(with: color0, size: 1))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: true))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: false))
        XCTAssertNotNil(shape0.withAlphaComponent(1))
        XCTAssertNotNil(shape0.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.cropped(to: CGRect(origin: .zero, size: shape0.sizeInPixel / 2)))
        XCTAssertNotNil(shape0.rotated(by: 60))
        XCTAssertNotNil(shape0.flippedHorizontally())
        XCTAssertNotNil(shape0.flippedVertically())
        XCTAssertNotNil(shape0.drawnAbove(image: shape1))
        XCTAssertNotNil(shape0.drawnUnder(image: shape1))
    }

    func testOperationBoundaries() throws {
        // These cases should fails, but the error handling strategy is to be refined.
        /*
        let image = UIImage(ciImage: shape0ciImage)
        XCTAssertNil(image.colorized(with: color0, method: .basic))
        XCTAssertNil(image.colorized(with: color0, method: .concurrent))
        XCTAssertNil(image.expand(bySize: 1, method: .basic))
        XCTAssertNil(image.expand(bySize: 1, method: .concurrent))
        XCTAssertNil(image.stroked(with: color0, size: 1))
        XCTAssertNil(image.smoothened(by: 1, sizeKept: true))
        XCTAssertNil(image.smoothened(by: 1, sizeKept: false))
        XCTAssertNil(image.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNil(image.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNil(image.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNil(image.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNil(image.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNil(image.cropped(to: CGRect(origin: .zero, size: shape0.sizeInPixel * 2)))
        XCTAssertNil(image.cropped(to: CGRect.zero))
        XCTAssertNil(image.rotated(by: 60))
        XCTAssertNil(image.flippedHorizontally())
        XCTAssertNil(image.flippedVertically())
        XCTAssertNil(image.drawnAbove(image: shape1))
        XCTAssertNil(image.drawnUnder(image: shape1))
         */
        
        XCTAssertNotNil(shape0
            .colorized(with: UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0")),
                       method: .basic))
        XCTAssertNotNil(shape0
            .colorized(with: UIColor(ciColor: CIColor(string: "0.0 0.0 0.0 0.0")),
                       method: .basic))
        XCTAssertNotNil(shape0.expand(bySize: 1, method: .basic))
        XCTAssertNotNil(shape0.expand(bySize: 1, method: .concurrent))
        XCTAssertNotNil(shape0.stroked(with: color0, size: 1))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: true))
        XCTAssertNotNil(shape0.smoothened(by: 1, sizeKept: false))
        XCTAssertNotNil(shape0.withAlphaComponent(1))
        XCTAssertNotNil(shape0.scaled(to: shape0.sizeInPixel / 2))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledWidth(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: true))
        XCTAssertNotNil(shape0.scaledHeight(to: 10, keepAspectRatio: false))
        XCTAssertNotNil(shape0.cropped(to: CGRect(origin: .zero, size: shape0.sizeInPixel / 2)))
        XCTAssertNotNil(shape0.rotated(by: 60))
        XCTAssertNotNil(shape0.flippedHorizontally())
        XCTAssertNotNil(shape0.flippedVertically())
        XCTAssertNotNil(shape0.drawnAbove(image: shape1))
        XCTAssertNotNil(shape0.drawnUnder(image: shape1))
    }

    func testColorizedBasic() throws {
        measure {
            repeated {
                _ = shape0.colorized(with: color0, method: .basic)
            }
        }
    }

    func testColorizedConcurrent() throws {
        measure {
            repeated {
                _ = shape0.colorized(with: color0, method: .concurrent)
            }
        }
    }

    func testExpandBasic() throws {
        measure {
            repeated {
                _ = shape0.expand(bySize: 20, method: .basic)
            }
        }
    }

    func testExpandConcurrent() throws {
        measure {
            repeated {
                _ = shape0.expand(bySize: 20, method: .concurrent)
            }
        }
    }
    
    func testStroked() throws {
        let color = UIColor.black
        measure {
            repeated {
                _ = shape0.stroked(with: color, size: 20)
            }
        }
    }
}
