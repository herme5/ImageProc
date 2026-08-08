//
//  StringExtension.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import Foundation

internal extension String {

    subscript (index: Int) -> Character {
        return self[self.index(startIndex, offsetBy: index)]
    }

    subscript (range: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return self[start ..< end]
    }

    subscript (range: Range<Int>) -> String {
        return String(self[range] as Substring)
    }
}
