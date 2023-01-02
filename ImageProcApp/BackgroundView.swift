//
//  BackgroundView.swift
//  ImageProcApp
//
//  Created by Andrea Ruffino on 21/04/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit

class BackgroundView: UIView {
    
    private var backgroundLayer: BackgroundLayer {
        return layer as! BackgroundLayer
    }
    
    override public class var layerClass: AnyClass {
        return BackgroundLayer.self
    }
    
    override var bounds: CGRect {
        didSet { layer.setNeedsDisplay() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        layer.contentsScale = UIScreen.main.scale
    }
}

fileprivate class BackgroundLayer: CALayer {
    
    private let lineColor = UIColor(displayP3Red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0)
    
    private let minorLineWidth = CGFloat(1)
    
    private let majorLineWidth = CGFloat(2)
    
    private let minorLineSpace = CGFloat(10)
    
    private let majorLineSpace = CGFloat(100)
    
    override func draw(in context: CGContext) {
        super.draw(in: context)
        let rect = self.bounds
        guard !rect.isEmpty else {
            return
        }
        
        UIGraphicsPushContext(context)
        context.setStrokeColor(lineColor.cgColor)
        
        // Minor lines
        context.setLineWidth(minorLineWidth)
        var x = rect.minX
        while x < rect.maxX {
            context.move(to:    CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += minorLineSpace
        }
        var y = rect.minY
        while y < rect.maxY {
            context.move(to:    CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += minorLineSpace
        }
        context.strokePath()
        
        // Major lines
        context.setLineWidth(majorLineWidth)
        x = rect.minX
        while x < rect.maxX {
            context.move(to:    CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += majorLineSpace
        }
        y = rect.minY
        while y < rect.maxY {
            context.move(to:    CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += majorLineSpace
        }
        context.strokePath()
        
        UIGraphicsPopContext()
    }
}
