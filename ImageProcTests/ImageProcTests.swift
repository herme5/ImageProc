//
//  ImageProcTests.swift
//  ImageProcTests
//
//  Created by Andrea Ruffino on 22/12/2022.
//  Copyright © 2022 Andrea Ruffino. All rights reserved.
//

import XCTest
@testable import ImageProc

final class ImageProcTests: XCTestCase {

    var appBundle: Bundle!
    var shape0: UIImage!
    var shape1: UIImage!
    var shape2: UIImage!
    var color0: UIColor!
    var color1: UIColor!
    var color2: UIColor!
    
    override func setUpWithError() throws {
        appBundle = Bundle(for: ImageProcTests.self)
        shape0 = UIImage(named: "shape_0", in: appBundle, with: nil)
        shape1 = UIImage(named: "shape_1", in: appBundle, with: nil)
        shape2 = UIImage(named: "shape_2", in: appBundle, with: nil)
        color0 = UIColor.systemIndigo
        color1 = UIColor.systemPink
        color2 = UIColor.systemTeal
    }

    func testColors() throws {
        let redColorHexName =   "#FF0000"
        let greenColorHexName = "#00FF00"
        let blueColorHexName =  "#0000FF"
        
        XCTAssertEqual(UIColor(from:   redColorHexName).hexCode,   redColorHexName)
        XCTAssertEqual(UIColor(from: greenColorHexName).hexCode, greenColorHexName)
        XCTAssertEqual(UIColor(from:  blueColorHexName).hexCode,  blueColorHexName)
        
        XCTAssertEqual(CGColor.from(hexCode:   redColorHexName).hexCode,   redColorHexName)
        XCTAssertEqual(CGColor.from(hexCode: greenColorHexName).hexCode, greenColorHexName)
        XCTAssertEqual(CGColor.from(hexCode:  blueColorHexName).hexCode,  blueColorHexName)
        
        // For coverage
        _ = color0.rgba.red
        _ = color0.rgba.green
        _ = color0.rgba.blue
        _ = color0.rgba.alpha
        
        _ = color0.hsla.hue
        _ = color0.hsla.saturation
        _ = color0.hsla.brightness
        _ = color0.hsla.alpha
        
        _ = color0.hexCode
        _ = color0.moreOpaque()
        _ = color0.lessOpaque()
        _ = color0.lighter()
        _ = color0.darker()
        _ = color0.saturated()
        _ = color0.brightened()
        _ = color0.hueOffset()
    }

    func testImages() throws {
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
    
    func testColorizedBasic() throws {
        measure {
            _ = shape0.colorized(with: color0, method: .basic)
        }
    }
    
    func testColorizedConcurrent() throws {
        measure {
            _ = shape0.colorized(with: color0, method: .concurrent)
        }
    }
    
    func testBasicExpand() throws {
        measure {
            _ = shape0.expand(bySize: 20, method: .basic)
        }
    }
    
    func testConcurrentExpand() throws {
        measure {
            _ = shape0.expand(bySize: 20, method: .concurrent)
        }
    }
}
