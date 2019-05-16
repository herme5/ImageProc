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
        
        let img_0 = UIImage(named: "shape_0")!
        let img_1 = UIImage(named: "shape_1")!.colorized(with: UIColor(value: 0x6890f6))
        
        items.append(contentsOf:
            [ProcessedImage(function: "Colorized", sourceImage: img_0,
                            processedImage: [(["0x08af76"], img_0.colorized(with: UIColor(value: 0x08af76))),
                                             (["0xc8a026"], img_0.colorized(with: UIColor(value: 0xc8a026))),
                                             (["0x6890f6"], img_0.colorized(with: UIColor(value: 0x6890f6)))]),
             ProcessedImage(function: "Stroked", sourceImage: img_0,
                            processedImage: [(["0x08af76", "1","1"], img_0.stroked(with: UIColor(value: 0x08af76), size: 1)),
                                             (["0x08af76", "5","1"], img_0.stroked(with: UIColor(value: 0x08af76), size: 5)),
                                             (["0x08af76","10","1"], img_0.stroked(with: UIColor(value: 0x08af76), size: 10))]),
             ProcessedImage(function: "Smoothened", sourceImage: img_0,
                            processedImage: [([ "1"], img_0.smoothened(by: 1)),
                                             ([ "5"], img_0.smoothened(by: 5)),
                                             (["10"], img_0.smoothened(by: 10))]),
             ProcessedImage(function: "Scaled", sourceImage: img_0,
                            processedImage: [([ "60","false"], img_0.scaledWidth(to: 60, keepAspectRatio: false)),
                                             ([ "60","true" ], img_0.scaledWidth(to: 60, keepAspectRatio: true)),
                                             (["140","false"], img_0.scaledHeight(to: 140, keepAspectRatio: false)),
                                             (["140","true" ], img_0.scaledHeight(to: 140, keepAspectRatio: true))]),
             ProcessedImage(function: "Cropped", sourceImage: img_0,
                            processedImage: [([ "0", "0","50","50"], img_0.cropped(to: CGRect(x:  0, y:  0, width: 50, height: 50))),
                                             (["50", "0","50","50"], img_0.cropped(to: CGRect(x: 50, y:  0, width: 50, height: 50))),
                                             ([ "0","50","50","50"], img_0.cropped(to: CGRect(x:  0, y: 50, width: 50, height: 50))),
                                             (["50","50","50","50"], img_0.cropped(to: CGRect(x: 50, y: 50, width: 50, height: 50)))]),
             ProcessedImage(function: "Rotated", sourceImage: img_0,
                            processedImage: [([ "0","true"], img_0.rotated(by:  0)),
                                             (["15","true"], img_0.rotated(by: 15)),
                                             (["30","true"], img_0.rotated(by: 30)),
                                             (["45","true"], img_0.rotated(by: 45))]),
             ProcessedImage(function: "Flipped", sourceImage: img_0,
                            processedImage: [(["horizontally"], img_0.flippedHorizontally()),
                                             (["vertically"  ], img_0.flippedVertically())]),
                ProcessedImage(function: "Draw", sourceImage: img_0,
                               processedImage: [([ "drawUnder"], img_0.drawUnder(image: img_1)),
                                                (["drawBefore"], img_0.drawAbove(image: img_1))])
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
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}
