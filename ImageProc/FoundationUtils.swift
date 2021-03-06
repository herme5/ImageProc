//
//  FoundationUtils.swift
//  Anagram
//
//  Created by Andrea Ruffino on 10/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

import Foundation

// MARK: - String extension

extension String {
    
    subscript (index: Int) -> Character {
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    subscript (index: Int) -> String {
        return String(self[index] as Character)
    }
    
    subscript (range: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: range.lowerBound)
        return self[start ..< self.endIndex]
    }
    
    subscript (range: Range<Int>) -> String {
        return String(self[range] as Substring)
    }
    
    subscript (indexes: [Int]) -> String {
        var output = String()
        for i in indexes { output += self[i] }
        return output
    }
    
    subscript (ranges: [Range<Int>]) -> String {
        var output = String()
        for r in ranges { output += self[r] }
        return output
    }
}
