//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

// Build the library target for device, otherwise import will not find ImageProc
import ImageProc



let image = UIImage(named: "shape")

let t1 = image?.smoothened(by: 5)

let t2 = image?.smoothened(by: 10)

let t3 = image?.colorized(with: .black)
