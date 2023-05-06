//
//  StringProtocol+.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 6/2/23.
//

import Foundation

public extension StringProtocol {
    subscript(offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }

    subscript(offset: Int) -> String {
        String(self[index(startIndex, offsetBy: offset)])
    }

    subscript(_ range: CountableRange<Int>) -> SubSequence {
        return prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }
    subscript(range: CountableClosedRange<Int>) -> SubSequence {
        return prefix(range.lowerBound + range.count)
            .suffix(range.count)
    }

    subscript(range: PartialRangeThrough<Int>) -> SubSequence {
        return prefix(range.upperBound.advanced(by: 1))
    }
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
        return prefix(range.upperBound)
    }
    subscript(range: PartialRangeFrom<Int>) -> SubSequence {
        return suffix(Swift.max(0, count - range.lowerBound))
    }

    var asciiValues: [UInt8] {
        compactMap(\.asciiValue)
    }

    var asciiValue: UInt8 {
        let n = compactMap(\.asciiValue)
        return n.first ?? 0
    }
}
