//
//  HexadecimalHelper.swift
//  ImageProc
//
//  Created by Andrea Ruffino on 10/03/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

import Foundation

// MARK: - HexadecimalHelper implementation

internal class HexadecimalHelper {
    
    /// The decimal to hexadecimal digits mapping table.
    static let digits: [Character: UInt] = ["0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7,
                                            "8": 8, "9": 9, "A":10, "B":11, "C":12, "D":13, "E":14, "F":15]
    
    /// Initializer is unavailable, this class contains only static members.
    private init() { }
    
    /// Converts an hexadecimal string to integer value. The input string can be either uppercase or lowercase, but must
    /// not contain whitespace or any character that is not an hexadecimal digit. All unrecognized characters will
    /// result in the function returning 0.
    static func valueFrom(string: String) -> UInt {
        var value: UInt = 0
        for (index, char) in string.uppercased().reversed().enumerated() {
            guard let digit = digits[char] else {
                return 0
            }
            // pow(16, index)
            let weight = UInt(1) << (4 * index)
            value += digit * weight
        }
        return value
    }
    
    /// Converts an hexadecimal value to a string. The leading zeros and the case can be specified.
    ///
    /// - parameters:
    ///   - value: the integer value,
    static func stringFrom(value: UInt, digitCount: UInt? = nil, uppercased: Bool = true) -> String {
        return String(format: "%\(digitCount == nil ? "" : "0\(digitCount!)")\(uppercased ? "X" : "x")", value)
    }
}
