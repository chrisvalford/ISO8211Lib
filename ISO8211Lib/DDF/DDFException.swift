//
//  DDFException.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 2/5/23.
//

import Foundation

public enum DDFException: Error {
    case recordLength // Add more for other DDFRecord errors
    case invalidOffset // Generic error when position in file/buffer is incorrect
    case undefinedField
    case invalidIntegerValue
    case invalidRecord
    case invalidSubfield
    case invalidIndex
}
