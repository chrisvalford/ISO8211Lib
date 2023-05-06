//
//  UInt8+.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 25/4/22.
//  Copyright © 2020-2023 marine+digital. All rights reserved.
//

import Foundation

let fieldTerminator = UInt8(0x1E)  // ASCII RS (Record separator 30)
let unitTerminator = UInt8(0x1F)   // ASCII US (Unit separator 31)

public extension UInt8 {
    var isDigit: Bool {
        if (48...57).contains(self) {
            return true
        }
        return false
    }
}
