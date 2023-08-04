//
//  ViewController.swift
//  ImageProcApp
//
//  Created by Andrea Ruffino on 20/04/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import UIKit
import ImageProc

struct ProcessResults {

    var parameters: [String]

    var image: UIImage

    init(_ parameters: [String], _ image: UIImage?) {
        self.parameters = parameters
        self.image = image ?? "⚠️".image()!
    }
}

struct ProcessedImage {

    var function: String = ""

    var sourceImage: UIImage! = nil

    var processedImage: [ProcessResults] = []

    var time: Double = 0.0
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var back: BackgroundView!

    var items: [ProcessedImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let col_1 = UIColor(
            red: CGFloat.random(in: 0.0...1.0),
            green: CGFloat.random(in: 0.0...1.0),
            blue: CGFloat.random(in: 0.0...1.0),
            alpha: 1.0)
        let col_2 = UIColor(
            red: CGFloat.random(in: 0.0...1.0),
            green: CGFloat.random(in: 0.0...1.0),
            blue: CGFloat.random(in: 0.0...1.0),
            alpha: 0.6)
        let col_3 = UIColor(
            red: CGFloat.random(in: 0.0...1.0),
            green: CGFloat.random(in: 0.0...1.0),
            blue: CGFloat.random(in: 0.0...1.0),
            alpha: 0.4)

        let img_0 = UIImage(named: "splash-rounded-100")!
        let img_1 = UIImage(named: "splash-square-100")!
        let img_2 = img_1.colorized(with: col_2)
        let img_3 = UIImage(named: "splash-square-line-100")!

        var res_0 = ProcessedImage()
        measureTime(output: &res_0) { (output) in
            output.function = "im0.colorized(with: UIColor, method: .basic)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([col_1.hexCode], img_0.colorized(with: col_1, method: .basic)),
                ProcessResults([col_2.hexCode], img_0.colorized(with: col_2, method: .basic)),
                ProcessResults([col_3.hexCode], img_0.colorized(with: col_3, method: .basic))
            ]
        }
        var res_1 = ProcessedImage()
        measureTime(output: &res_1) { (output) in
            output.function = "im0.colorized(with: UIColor, method: .concurrent)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([col_1.hexCode], img_0.colorized(with: col_1, method: .concurrent)),
                ProcessResults([col_2.hexCode], img_0.colorized(with: col_2, method: .concurrent)),
                ProcessResults([col_3.hexCode], img_0.colorized(with: col_3, method: .concurrent))
            ]
        }
        var res_2 = ProcessedImage()
        measureTime(output: &res_2) { (output) in
            output.function = "im1.expand(bySize: CGFloat, each: CGFloat, method: .basic)"
            output.sourceImage = img_1
            output.processedImage = [
                ProcessResults(["20", "60"], img_1.expand(bySize: 20, each: 60, method: .basic)),
                ProcessResults(["20", "20"], img_1.expand(bySize: 20, each: 20, method: .basic)),
                ProcessResults(["20", "10"], img_1.expand(bySize: 20, each: 10, method: .basic)),
                ProcessResults(["20", "4"], img_1.expand(bySize: 20, each: 4, method: .basic)),
                ProcessResults(["20", "3"], img_1.expand(bySize: 20, each: 3, method: .basic))
            ]
        }
        var res_3 = ProcessedImage()
        measureTime(output: &res_3) { (output) in
            output.function = "im1.expand(bySize: CGFloat, each: CGFloat, method: .concurrent)"
            output.sourceImage = img_1
            output.processedImage = [
                ProcessResults(["20", "60"], img_1.expand(bySize: 20, each: 60, method: .concurrent)),
                ProcessResults(["20", "20"], img_1.expand(bySize: 20, each: 20, method: .concurrent)),
                ProcessResults(["20", "10"], img_1.expand(bySize: 20, each: 10, method: .concurrent)),
                ProcessResults(["20", "4"], img_1.expand(bySize: 20, each: 4, method: .concurrent)),
                ProcessResults(["20", "3"], img_1.expand(bySize: 20, each: 3, method: .concurrent))
            ]
        }
        var res_22 = ProcessedImage()
        measureTime(output: &res_22) { (output) in
            output.function = "im3.expand(bySize: CGFloat, each: CGFloat, method: .basic)"
            output.sourceImage = img_3
            output.processedImage = [
                ProcessResults(["20", "60"], img_3.expand(bySize: 20, each: 60, method: .basic)),
                ProcessResults(["20", "20"], img_3.expand(bySize: 20, each: 20, method: .basic)),
                ProcessResults(["20", "10"], img_3.expand(bySize: 20, each: 10, method: .basic)),
                ProcessResults(["20", "4"], img_3.expand(bySize: 20, each: 4, method: .basic)),
                ProcessResults(["20", "3"], img_3.expand(bySize: 20, each: 3, method: .basic))
            ]
        }
        var res_32 = ProcessedImage()
        measureTime(output: &res_32) { (output) in
            output.function = "im3.expand(bySize: CGFloat, each: CGFloat, method: .concurrent)"
            output.sourceImage = img_3
            output.processedImage = [
                ProcessResults(["20", "60"], img_3.expand(bySize: 20, each: 60, method: .concurrent)),
                ProcessResults(["20", "20"], img_3.expand(bySize: 20, each: 20, method: .concurrent)),
                ProcessResults(["20", "10"], img_3.expand(bySize: 20, each: 10, method: .concurrent)),
                ProcessResults(["20", "4"], img_3.expand(bySize: 20, each: 4, method: .concurrent)),
                ProcessResults(["20", "3"], img_3.expand(bySize: 20, each: 3, method: .concurrent))
            ]
        }
        var res_4 = ProcessedImage()
        measureTime(output: &res_4) { (output) in
            output.function = "im1.stroked(with: UIColor, size: CGFloat, alpha: CGFloat)"
            output.sourceImage = img_1
            output.processedImage = [
                ProcessResults([col_1.hexCode, "10", "0.2"], img_1.stroked(with: col_1, size: 10, alpha: 0.2)),
                ProcessResults([col_2.hexCode, "10", "0.5"], img_1.stroked(with: col_2, size: 10, alpha: 0.5)),
                ProcessResults([col_3.hexCode, "10", "1.0"], img_1.stroked(with: col_3, size: 10, alpha: 1.0))
            ]
        }
        var res_5 = ProcessedImage()
        measureTime(output: &res_5) { (output) in
            output.function = "im0.smoothened(by: CGFloat, sizeKept: Bool)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([ "1", "false"], img_0.smoothened(by: 1)),
                ProcessResults([ "5", "false"], img_0.smoothened(by: 5)),
                ProcessResults(["10", "false"], img_0.smoothened(by: 10))
            ]
        }
        var res_6 = ProcessedImage()
        measureTime(output: &res_6) { (output) in
            output.function = "im0.scaledWidth(to: CGFloat, keepAspectRation: Bool)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([ "60", "false"], img_0.scaledWidth(to: 60, keepAspectRatio: false)),
                ProcessResults([ "60", "true" ], img_0.scaledWidth(to: 60, keepAspectRatio: true)),
                ProcessResults(["140", "false"], img_0.scaledWidth(to: 140, keepAspectRatio: false)),
                ProcessResults(["140", "true" ], img_0.scaledWidth(to: 140, keepAspectRatio: true))
            ]
        }
        var res_7 = ProcessedImage()
        measureTime(output: &res_7) { (output) in
            output.function = "im0.scaledHeight(to: CGFloat, keepAspectRation: Bool)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([ "60", "false"], img_0.scaledHeight(to: 60, keepAspectRatio: false)),
                ProcessResults([ "60", "true" ], img_0.scaledHeight(to: 60, keepAspectRatio: true)),
                ProcessResults(["140", "false"], img_0.scaledHeight(to: 140, keepAspectRatio: false)),
                ProcessResults(["140", "true" ], img_0.scaledHeight(to: 140, keepAspectRatio: true))
            ]
        }
        var res_8 = ProcessedImage()
        measureTime(output: &res_8) { (output) in
            output.function = "im0.cropped(to: CGRect)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([ "0", "0", "50", "50"], img_0.cropped(to: CGRect(x: 0, y: 0, width: 50, height: 50))),
                ProcessResults(["50", "0", "50", "50"], img_0.cropped(to: CGRect(x: 50, y: 0, width: 50, height: 50))),
                ProcessResults([ "0", "50", "50", "50"], img_0.cropped(to: CGRect(x: 0, y: 50, width: 50, height: 50))),
                ProcessResults(["50", "50", "50", "50"], img_0.cropped(to: CGRect(x: 50, y: 50, width: 50, height: 50)))
            ]
        }
        var res_9 = ProcessedImage()
        measureTime(output: &res_9) { (output) in
            output.function = "im0.rotated(by: CGFloat)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([ "0"], img_0.rotated(by: 0)),
                ProcessResults(["45"], img_0.rotated(by: 45)),
                ProcessResults(["90"], img_0.rotated(by: 90)),
                ProcessResults(["135"], img_0.rotated(by: 135)),
                ProcessResults(["180"], img_0.rotated(by: 180))
            ]
        }
        var res_10 = ProcessedImage()
        measureTime(output: &res_10) { (output) in
            output.function = "im0.flippedHorizontally()"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([], img_0.flippedHorizontally())
            ]
        }
        var res_11 = ProcessedImage()
        measureTime(output: &res_11) { (output) in
            output.function = "im0.flippedVertically()"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults([], img_0.flippedVertically())
            ]
        }
        var res_12 = ProcessedImage()
        measureTime(output: &res_12) { (output) in
            output.function = "im0.drawnUnder(image: UIImage)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults(
                    ["im0.rotated(by: 45).colorized(with: \(col_1.hexCode))"],
                    img_0.drawnUnder(image: img_0.rotated(by: 45).colorized(with: col_1))),
                ProcessResults(
                    ["im2"],
                    img_0.drawnUnder(image: img_2))
            ]
        }
        var res_13 = ProcessedImage()
        measureTime(output: &res_13) { (output) in
            output.function = "im0.drawnAbove(image: UIImage)"
            output.sourceImage = img_0
            output.processedImage = [
                ProcessResults(
                    ["im0.rotated(by: 45).colorized(with: \(col_1.hexCode))"],
                    img_0.drawnAbove(image: img_0.rotated(by: 45).colorized(with: col_1))),
                ProcessResults(
                    ["im2"],
                    img_0.drawnAbove(image: img_2))
            ]
        }

        items.append(contentsOf: [
            res_0, res_1, res_2, res_3, res_22, res_32, res_4, res_5, res_6, res_7, res_8, res_9, res_10, res_11, res_12, res_13
            ])

        self.back = BackgroundView()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.dataSource = self
        self.tableView.backgroundColor = .clear
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
    }
}

@discardableResult
func measureTime(output: inout ProcessedImage, closure: @escaping ((inout ProcessedImage) -> Void)) -> Double {
    let start = DispatchTime.now()

    closure(&output)

    let end = DispatchTime.now()
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000_000

    output.time = timeInterval
    return timeInterval
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let deflt: CGFloat = 12 + 24 + 32

        var maxHeight: CGFloat = items[indexPath.row].sourceImage.size.height

        for processResult in items[indexPath.row].processedImage {
            maxHeight = max(maxHeight, processResult.image.size.height)
        }
        return deflt + maxHeight
    }
}
