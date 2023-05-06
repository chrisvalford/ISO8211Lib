//
//  String+.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 25/4/22.
//  Copyright © 2020-2023 marine+digital. All rights reserved.
//

import Foundation

// Convert String to [UInt8]
public extension String {
    var byteArray: [UInt8] {
        let bytes = self.utf8
        return [UInt8](bytes)
    }
}

public extension Substring {
    var string: String { return String(self) }
}

// extend String to enable sub-script with Int to get Character or sub-string
public extension String {
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }

    // for convenience we should include String return
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)

        return String(self[start...end])
    }
}
