//
//  Exceptions.swift
//  ISO8211Reader
//
//  Created by Christopher Alford on 28/1/22.
//

import Foundation

public enum Exception: Error {
    case IOException
    case NumberFormatException
    case InvalidCharException
    case InvalidHeader
    case indexOutOfRange
    case formatControlsShort
    case formatControlsMissingParenthesis
    case formatControlsProblemSetting
    case formatControlsInvalidCount(tag: String, count: Int)
    case invalidFormatWidth
    case invalidFormat(message: String)
    case formatNotSupported(format: String)
    case formatNotRecognised(format: String)
}
