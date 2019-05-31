//
//  ViewController.swift
//  ImageProcApp
//
//  Created by Andrea Ruffino on 20/04/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit
import ImageProc

struct ProcessedImage {
    
    var function: String
    
    var sourceImage: UIImage
    
    var processedImage: [(parameters: [String], image: UIImage)]
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var back: BackgroundView!
    
    var items: [ProcessedImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let col_1 = UIColor(value: 0x08af76)
        let col_2 = UIColor(value: 0xc8a026)
        let col_3 = UIColor(value: 0x6890f6)
        
        let img_0 = UIImage(named: "shape_0")!
        let img_1 = UIImage(named: "shape_1")!
        let img_2 = img_1.colorized(with: col_2)
        
        items.append(contentsOf:
            [ProcessedImage(function: "im0.colorized(with: UIColor)", sourceImage: img_0,
                            processedImage: [(["#08af76"], img_0.colorized(with: col_1)),
                                             (["#c8a026"], img_0.colorized(with: col_2)),
                                             (["#6890f6"], img_0.colorized(with: col_3))]),
             ProcessedImage(function: "im1.expand(bySize: CGFloat, each: CGFloat)", sourceImage: img_1,
                            processedImage: [(["20","10"], img_1.expand(bySize: 20, each: 10)),
                                             (["20", "5"], img_1.expand(bySize: 20, each: 5)),
                                             (["20", "2"], img_1.expand(bySize: 20, each: 2)),
                                             (["20", "1"], img_1.expand(bySize: 20, each: 1))]),
             ProcessedImage(function: "im1.stroked(with: UIColor, size: CGFloat, alpha: CGFloat)", sourceImage: img_1,
                            processedImage: [(["#08af76","10","0.5"], img_1.stroked(with: col_1, size: 10, alpha: 0.5)),
                                             (["#c8a026","10","0.7"], img_1.stroked(with: col_2, size: 10, alpha: 0.7)),
                                             (["#6890f6","10","1.0"], img_1.stroked(with: col_3, size: 10, alpha: 1.0))]),
             ProcessedImage(function: "im0.smoothened(by: CGFloat, sizeKept: Bool)", sourceImage: img_0,
                            processedImage: [([ "1", "false"], img_0.smoothened(by:  1)),
                                             ([ "5", "false"], img_0.smoothened(by:  5)),
                                             (["10", "false"], img_0.smoothened(by: 10))]),
             ProcessedImage(function: "im0.scaledWidth(to: CGFloat, keepAspectRation: Bool)", sourceImage: img_0,
                            processedImage: [([ "60","false"], img_0.scaledWidth(to:  60, keepAspectRatio: false)),
                                             ([ "60","true" ], img_0.scaledWidth(to:  60, keepAspectRatio: true)),
                                             (["140","false"], img_0.scaledWidth(to: 140, keepAspectRatio: false)),
                                             (["140","true" ], img_0.scaledWidth(to: 140, keepAspectRatio: true))]),
             ProcessedImage(function: "im0.scaledHeight(to: CGFloat, keepAspectRation: Bool)", sourceImage: img_0,
                            processedImage: [([ "60","false"], img_0.scaledHeight(to:  60, keepAspectRatio: false)),
                                             ([ "60","true" ], img_0.scaledHeight(to:  60, keepAspectRatio: true)),
                                             (["140","false"], img_0.scaledHeight(to: 140, keepAspectRatio: false)),
                                             (["140","true" ], img_0.scaledHeight(to: 140, keepAspectRatio: true))]),
             ProcessedImage(function: "im0.cropped(to: CGRect)", sourceImage: img_0,
                            processedImage: [([ "0", "0","50","50"], img_0.cropped(to: CGRect(x:  0, y:  0, width: 50, height: 50))),
                                             (["50", "0","50","50"], img_0.cropped(to: CGRect(x: 50, y:  0, width: 50, height: 50))),
                                             ([ "0","50","50","50"], img_0.cropped(to: CGRect(x:  0, y: 50, width: 50, height: 50))),
                                             (["50","50","50","50"], img_0.cropped(to: CGRect(x: 50, y: 50, width: 50, height: 50)))]),
             ProcessedImage(function: "im0.rotated(by: CGFloat)", sourceImage: img_0,
                            processedImage: [([ "0"], img_0.rotated(by:  0)),
                                             (["15"], img_0.rotated(by: 15)),
                                             (["30"], img_0.rotated(by: 30)),
                                             (["45"], img_0.rotated(by: 45))]),
             ProcessedImage(function: "im0.flippedHorizontally()", sourceImage: img_0,
                            processedImage: [([], img_0.flippedHorizontally())]),
             ProcessedImage(function: "im0.flippedVertically()", sourceImage: img_0,
                            processedImage: [([], img_0.flippedVertically())]),
             ProcessedImage(function: "im0.drawUnder(image: UIImage)", sourceImage: img_0,
                            processedImage: [(["im0.rotated(by: 45).colorized(with: #c8a026)"], img_0.drawUnder(image: img_0.rotated(by: 45).colorized(with: col_2))),
                                             (["im1.colorized(with: 0xc8a026)"               ], img_0.drawUnder(image: img_2))]),
             ProcessedImage(function: "im0.drawAbove(image: UIImage)", sourceImage: img_0,
                            processedImage: [(["im0.rotated(by: 45).colorized(with: #c8a026)"], img_0.drawAbove(image: img_0.rotated(by: 45).colorized(with: col_2))),
                                             (["im1.colorized(with: 0xc8a026)"               ], img_0.drawAbove(image: img_2))])
            ])
        
        self.back = BackgroundView()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.dataSource = self
        self.tableView.backgroundColor = .clear
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageProcessedCell", for: indexPath) as? ProcessedImageCell else {
            return UITableViewCell()
        }
        let item = self.items[indexPath.item]
        cell.backgroundColor = .clear
        cell.data = item
        
        cell.functionLabel.layer.cornerRadius = 5
        cell.functionLabel.layer.zPosition = 1
        
        cell.parametersLabel.layer.cornerRadius = 5
        cell.parametersLabel.layer.zPosition = 1
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}
