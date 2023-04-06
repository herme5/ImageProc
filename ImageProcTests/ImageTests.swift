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
    
    let iterationCount = 5
    
    func repeated(_ body: () -> Void) {
        for _ in 0 ..< iterationCount {
            body()
        }
    }
    
    override func setUpWithError() throws {
        appBundle = Bundle(for: ImageTests.self)
        shape0 = UIImage(named: "shape_0", in: appBundle, with: nil)
        shape1 = UIImage(named: "shape_1", in: appBundle, with: nil)
        shape2 = UIImage(named: "shape_2", in: appBundle, with: nil)
        color0 = UIColor.systemIndigo
        color1 = UIColor.systemPink
        color2 = UIColor.systemTeal
    }
    
    func testImages() throws {
        measure {
            _ = shape0.sizeInPixel
            _ = shape0.colorized(with: color0, method: .basic)
            _ = shape0.colorized(with: color0, method: .concurrent)
            _ = shape0.expand(bySize: 1, method: .basic)
            _ = shape0.expand(bySize: 1, method: .concurrent)
            _ = shape0.stroked(with: color0, size: 1)
            _ = shape0.smoothened(by: 1)
            _ = shape0.stroked(with: color0, size: 1)
            _ = shape0.withAlphaComponent(1)
            _ = shape0.scaled(to: shape0.sizeInPixel / 2)
            _ = shape0.scaledWidth(to: 10)
            _ = shape0.scaledHeight(to: 10)
            _ = shape0.cropped(to: CGRect(origin: .zero, size: shape0.sizeInPixel / 2))
            _ = shape0.rotated(by: 60)
            _ = shape0.flippedHorizontally()
            _ = shape0.flippedVertically()
            _ = shape0.drawnAbove(image: shape1)
            _ = shape0.drawnUnder(image: shape1)
        }
    }
    
    func testOperationBoundaries() throws {
        
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
}
