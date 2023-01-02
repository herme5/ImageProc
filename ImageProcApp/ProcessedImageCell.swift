//
//  ImageProcessedCell.swift
//  ImageProcApp
//
//  Created by Andrea Ruffino on 28/04/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import Foundation
import UIKit

class ProcessedImageCell: UITableViewCell {
    
    @IBOutlet weak var functionLabel: UILabel!
    
    @IBOutlet weak var parametersLabel: UILabel!
    
    @IBOutlet weak var sourceImageView: UIImageView!
    
    @IBOutlet weak var functionLabelWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var parametersLabelWidthConstraint: NSLayoutConstraint!
    
    let imageViewSpacing: CGFloat = 56
    
    var resultImageViews = [UIImageView]()
    
    var resultImageBoundingBoxViews = [UIView]()
    
    var data: ProcessedImage? = nil {
        didSet {
            for imageView in resultImageViews {
                imageView.removeFromSuperview()
            }
            resultImageViews.removeAll()
            
            for view in resultImageBoundingBoxViews {
                view.removeFromSuperview()
            }
            resultImageBoundingBoxViews.removeAll()
            
            guard let data = self.data else {
                functionLabel.text = "Function"
                parametersLabel.text = "Parameters"
                sourceImageView.image = nil
                return
            }
            
            functionLabel.text = data.function
            sourceImageView.image = data.sourceImage
            parametersLabel.text = data.processedImage.map({ result -> String in
                return "(\(result.parameters.joined(separator: ", ")))"
            }).joined(separator: "  ") + " in \(String(format: "%.4f", data.time * 1_000)) msecs"
            
            functionLabelWidthConstraint.constant = functionLabel.attributedText!.size().width + 20
            parametersLabelWidthConstraint.constant = parametersLabel.attributedText!.size().width + 40
            
            for index in 0 ..< data.processedImage.count {
                let offset = CGFloat(index) * (imageViewSpacing + sourceImageView.frame.width)
                let x = sourceImageView.frame.maxX + imageViewSpacing + offset
                let y = sourceImageView.frame.minY
                let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: x, y: y), size: sourceImageView.frame.size))
                
                imageView.contentMode = .center
                imageView.layer.zPosition = -2
                imageView.layer.borderWidth = 1
                imageView.layer.borderColor = UIColor.orange.cgColor
                
                imageView.image = data.processedImage[index].image
                
                let bbw = data.processedImage[index].image.size.width
                let bbh = data.processedImage[index].image.size.height
                let bbx = imageView.frame.midX - (bbw / 2)
                let bby = imageView.frame.midY - (bbh / 2)
                let boundingBoxView = UIView(frame: CGRect(x: bbx, y: bby, width: bbw, height: bbh))
                
                boundingBoxView.backgroundColor = .clear
                boundingBoxView.layer.zPosition = -1
                boundingBoxView.layer.borderWidth = 1
                boundingBoxView.layer.borderColor = UIColor.magenta.cgColor
                
                self.addSubview(imageView)
                self.addSubview(boundingBoxView)
                self.resultImageViews.append(imageView)
                self.resultImageBoundingBoxViews.append(boundingBoxView)
            }
            updateConstraints()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.layer.masksToBounds = false
    }
}
