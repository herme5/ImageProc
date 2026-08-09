//
//  BackgroundView.swift
//  ImageProcApp
//
//  Created by Andrea Ruffino on 21/04/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit

private enum Style {
    static let backgroundColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: return UIColor(displayP3Red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)
        case .dark: return UIColor(displayP3Red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)
        @unknown default: fatalError("Unknown user interface trait \"\(traitCollection.userInterfaceStyle)\"")
        }
    }

    static let lineColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light: return UIColor(displayP3Red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0)
        case .dark: return UIColor(displayP3Red: 0.84, green: 0.84, blue: 0.84, alpha: 1.0)
        @unknown default: fatalError("Unknown user interface trait \"\(traitCollection.userInterfaceStyle)\"")
        }
    }
}

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
        backgroundColor = Style.backgroundColor
        layer.contentsScale = UIScreen.main.scale
        updateLineColor()

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: BackgroundView, _) in
                view.updateLineColor()
            }
        }
    }

    @available(iOS, deprecated: 17.0, message: "registerForTraitChanges(_:handler:) takes over from iOS 17")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #unavailable(iOS 17.0) else { return }
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateLineColor()
        }
    }

    private func updateLineColor() {
        backgroundLayer.lineColor = Style.lineColor.resolvedColor(with: traitCollection).cgColor
    }
}

private class BackgroundLayer: CALayer {

    /// Resolved by the view against its own trait collection, and redrawn whenever it changes.
    var lineColor = Style.lineColor.cgColor {
        didSet { setNeedsDisplay() }
    }

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
        context.setStrokeColor(lineColor)

        // Minor lines
        context.setLineWidth(minorLineWidth)
        var x = rect.minX
        while x < rect.maxX {
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += minorLineSpace
        }
        var y = rect.minY
        while y < rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += minorLineSpace
        }
        context.strokePath()

        // Major lines
        context.setLineWidth(majorLineWidth)
        x = rect.minX
        while x < rect.maxX {
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += majorLineSpace
        }
        y = rect.minY
        while y < rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += majorLineSpace
        }
        context.strokePath()

        UIGraphicsPopContext()
    }
}
