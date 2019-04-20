//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

// Build the library target for device, otherwise import will not find ImageProc
import ImageProc

let image = UIImage(named: "shape")

let i1 = image?.colorized(with: UIColor.orange)

let i2 = image?.stroked(with: UIColor.orange, size: 10)

let i3 = image?.smoothened(by: 5)

let i4 = image?.colorized(with: UIColor(red: 1, green: 1, blue: 1, alpha: 0.5))

let i5 = image?.withAlphaComponent(0.5)

let i6 = image?.scaled(to: CGSize(width: 50, height: 50))
