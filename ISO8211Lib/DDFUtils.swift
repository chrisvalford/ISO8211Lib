//
//  DDFUtils.swift
//  ISO8211Reader
//
//  Created by Christopher Alford on 28/1/22.
//

import Foundation

@objc public class DDFUtils: NSObject {

    public override init() {
        super.init()
    }

    /// DDFScanVariable
    /// Establish the length of a variable length string in a record.
    @objc public class func scanVariable(byteBuffer: [UInt8], maxChars: Int, delimiter: UInt8) -> Int {
        var i = 0
        while i < maxChars - 1 && byteBuffer[i] != delimiter {
            i += 1
        }
        return i
    }

    /// DDFFetchVariable
    /// Fetch a variable length string from a record, and allocate
    /// it as a new string (with CPLStrdup()).
    @objc public class func fetchVariable(byteBuffer: Data,
                                          maxChars: Int,
                                          delimiter1: UInt8,
                                          delimiter2: UInt8,
                                          consumedChars: Int,
                                          completion: (String, Int) -> Void
    ) {
            var i = 0
        var consumed = consumedChars
            while i < maxChars - 1 && byteBuffer[i] != delimiter1 && byteBuffer[i] != delimiter2 {
                i += 1
            }
            consumed = i
            if i < maxChars && (byteBuffer[i] == delimiter1 || byteBuffer[i] == delimiter2) {
                consumed += 1
            }
        if i > 0 {
            var newBuffer = [UInt8](repeating: 0, count: i)
            do {
                try arraycopy(byteBuffer, 0, &newBuffer, 0, i)
            } catch {
                debugPrint(error)
                completion("", consumed)
            }
            guard let rawString = String(bytes: newBuffer, encoding: .utf8) else {
                completion("", consumed)
                return
            }
            var str = ""
            for ch in rawString {
                if ch.asciiValue != 0 {
                    str.append(ch)
                }
            }
            completion(str, consumed)
        }
        completion("", consumed)
    }


    ///
    /// - Parameters:
    ///     - source_arr: array to be copied from
    ///     - sourcePos: starting position in source array from where to copy
    ///     - dest_arr: array to be copied in
    ///     - destPos: starting position in destination array, where to copy in
    ///     - len: total no. of components to be copied.
    /*
     The java.lang.System.arraycopy() method copies a source array from a specific beginning position to the destination array from the mentioned position. No. of arguments to be copied are decided by len argument.
     The components at source_Position to source_Position + length – 1 are copied to destination array from destination_Position to destination_Position + length – 1
     */

    /// Our version inserts the source into the destination so the array may have trailing data!!!
    public class func arraycopy(_ sourceArray: Data,
                          _ sourceIndex: Int,
                          _ destinationArray: inout [UInt8],
                          _ destinationIndex: Int,
                          _ count: Int) throws {
        if sourceArray.count == 0 {
            throw Exception.indexOutOfRange
        }
        if sourceIndex < 0 || destinationIndex < 0 {
            throw Exception.indexOutOfRange
        }
        if sourceIndex + count - 1 > sourceArray.count {
            throw Exception.indexOutOfRange
        }

        let subArray = Array(sourceArray[sourceIndex...(sourceIndex+count-1)])
        destinationArray.insert(contentsOf: subArray, at: destinationIndex)
    }

    @objc public static func DDFScanInt(pszString: Data, //[UInt8],
                                  maxChars: Int,
                                  consumedChars: Int,
                                  completion: (Int, Int) -> Void) {

        var consumed = consumedChars
        var maxChars = maxChars
        if maxChars > 32 || maxChars == 0 {
            maxChars = 32
        }
        guard let str = String(bytes: Array(pszString[0...maxChars-1]), encoding: .utf8) else {
            completion(0, consumed)
            return
        }
        if str.count > 1 {
            let s = str.dropFirst().drop { $0 == "0"}
            guard let value = Int(s) else {
                completion(0, consumed)
                return
            }
        }
        guard let value = Int(str) else {
            completion(0, consumed)
            return
        }
        return completion(value, consumed)
    }

    public class func DDFScanInt(pszString: [UInt8], from: Int, nMaxChars: Int ) -> Int? {
        var maxChars = nMaxChars
        if maxChars > 32 || maxChars == 0 {
            maxChars = 32
        }
        if from+nMaxChars-1 > pszString.count {
            return nil
        }
        let data = Array(pszString[from...from+nMaxChars-1])
        guard let str = String(bytes: data, encoding: .utf8) else {
            return nil
        }
        return Int(str)
    }
}
