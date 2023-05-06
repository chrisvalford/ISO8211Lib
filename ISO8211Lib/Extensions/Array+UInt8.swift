//
//  Array+UInt8.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 23/01/2017.
//  Copyright © 2017 Marine+Digital. All rights reserved.
//

import Foundation

public extension Array where Element == UInt8 {
    
    init(uint8Array: [UInt8]) {
        self = uint8Array.map { UInt8($0) }
    }

    init(data: Data) {
        self = data.map { UInt8($0) }
    }
    
    /// Initialize array similar to String(format: String, values...)
    /// - Parameter format: Format string, i.e. "%d" for an Integer.
    init(format: String, value: Int) {
        let partOneString = String(format: format, value)
        let partOneData: [UInt8] = Array(partOneString.utf8)
        self = partOneData
    }

    /// Similar to String.componets(seperatedBy:...)
    /// - Parameter seperatedBy: `UInt8` value to split array by.
    /// - Returns: Array of UInt8 arrays, or [] if cannot find seperatedBy value.
    func components(seperatedBy: UInt8) -> [[UInt8]] {

        var components = [[UInt8]]()
        var row = [UInt8]()
        for i in 0..<self.count {
            if self[i] != seperatedBy {
                row.append(self[i])
            } else {
                components.append(row)
                row.removeAll()
            }
        }
        components.append(row)
        return components
    }
    
    func substring(from: Int) -> [UInt8] {
        if from > self.count {
            return []
        }
        let subarray = self[from...]
        return Array(subarray)
    }
    
    /// char * strncpy ( char * destination, const char * source, size_t num );
    /// self, count, returns
    /// Copy characters from string
    ///Copies the first num characters of source to destination. If the end of the source C string (which is signaled by a null-character) is found before num characters have been copied, destination is padded with zeros until a total of num characters have been written to it.
    /// No null-character is implicitly appended at the end of destination if source is longer than num. Thus, in this case, destination shall not be considered a null terminated C string (reading it as such would overflow).
    /// destination and source shall not overlap (see memmove for a safer alternative when overlapping).
    ///
    func strncopy(count: Int) -> [UInt8]? {
        if count > self.count {
            return nil
        }
        return Array(self[...count])
    }

    func intValue(start: Int, end: Int) -> Int? {
        if end > self.count {
            return nil
        }
        let slice = self[start...end]
        guard let stringValue = String(bytes: slice, encoding: .utf8),
              let n = Int(stringValue) else {
            debugPrint("Invalid UInt range for Int conversion")
            return nil
        }
        return n
    }
    
    //let sample: [UInt8] = [32,48,48,48,48,50]
    //let i = sample.int(start: 1, end: sample.count-1)
    func int(start: Int, end: Int) throws -> Int {
        guard let flString = String(bytes: Array(self[start...end]), encoding: .utf8) else {
            throw DDFException.invalidIntegerValue
        }
        let trimmedflString = flString.replacingOccurrences(of: "^0+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedflString != "" else {
            return 0
            //throw DDFException.invalidIntegerValue
        }
        guard let value = Int(trimmedflString) else {
            throw DDFException.invalidIntegerValue
        }
        return value
    }

    /// Extract a substring terminated by a comma (or end of string).
    /// Commas in brackets are ignored as terminated with bracket
    /// nesting understood gracefully. If the returned string would
    /// being and end with a bracket then strip off the brackets.
    ///
    /// Given a string like "(A,3(B,C),D),X,Y)" return "A,3(B,C),D".
    /// Give a string like "3A,2C" return "3A".
    /// - Returns: Formatted substring
    ///
    func extractSubstring() -> [UInt8] {
        var nBracket = 0
        var pszReturn: [UInt8] = []
        var i = 0
        while (i < self.count) && (nBracket > 0 || self[i] != 44) { // ,
            if self[i] == 40 { // (
                nBracket += 1
            } else if self[i] == 41 { // )
                nBracket -= 1
            }
            i += 1
        }
        if self[0] == 40 {
            pszReturn = Array(self[1...(i - 2)])
        } else {
            if i < self.count {
                pszReturn = Array(self[0...i])
            } else {
                pszReturn = self
            }
        }
        if pszReturn.last == 44 {
            return pszReturn.dropLast()
        }
        return pszReturn
    }
    
    /// Given a string that contains a coded size symbol, expand it out.
    ///
    mutating func expandFormat() -> [UInt8] {
        var szDest: [UInt8] = []
        var iSrc = 0
        var nRepeat = 0
        
//        debugPrint(self.string)
        
        while iSrc < self.count {
            /*
             * This is presumably an extra level of brackets around
             * some binary stuff related to rescanning which we don't
             * care to do (see 6.4.3.3 of the standard. We just strip
             * off the extra layer of brackets
             */
            if ((iSrc == 0 || self[iSrc - 1] == 44) && self[iSrc] == 40) {
                var pszContents = Array(self[iSrc...]).extractSubstring()
                //debugPrint("pszContents: \(String(bytes: pszContents, encoding: .utf8) ?? "")")
                let pszExpandedContents = pszContents.expandFormat()
                szDest.append(contentsOf: pszExpandedContents)
                iSrc = iSrc + pszContents.count + 2
                
            } else if (iSrc == 0 || self[iSrc - 1] == 44) && self[iSrc].isDigit {
                // this is a repeated subclause
                let orig_iSrc = iSrc
                // skip over repeat count.
                while self[iSrc].isDigit {
                    iSrc += 1
                }
                let nRepeatString = String(bytes: Array(self[orig_iSrc..<iSrc]), encoding: .utf8) // 3A
                nRepeat = Int(nRepeatString!) ?? 0
                var pszContents = Array(self[iSrc...]).extractSubstring()
                let pszExpandedContents = pszContents.expandFormat()
                for i in 0..<nRepeat {
                    szDest.append(contentsOf: pszExpandedContents)
                    if (i < nRepeat - 1) {
                        szDest.append(44)
                    }
                }
                if iSrc == 40 { // (
                    iSrc += pszContents.count + 2
                } else {
                    iSrc += pszContents.count
                }
            } else {
//                debugPrint("pszSrc: \(self.string)")
//                debugPrint("Appending psZSrc[\(iSrc)] to szDest")
//                debugPrint("szDest: \(szDest.string)")
//                debugPrint("------------------------------------")
                szDest.append(self[iSrc])
                iSrc += 1
            }
        }
//        debugPrint(szDest.string)
        return szDest
    }
    
    func rangeToString(start: Int, length: Int, delimiterA: UInt8, delimiterB: UInt8, consumed: inout Int) -> String {
//        let source = self as! [CChar]
//        let testBytes = source[start...(start+length)]
        let testBytes = self[start...(start+length)]
        var consumed = 0
        for j in 0..<length {
            if (testBytes[j] != unitTerminator) && (testBytes[j] != fieldTerminator) {
                // do what?
            }
            consumed = j
        }
        if consumed < length && (testBytes[consumed] == unitTerminator || testBytes[consumed] == fieldTerminator)  {
            consumed += 1
        }
        let returnData = testBytes[0..<testBytes.startIndex + consumed]
        return String(bytes: Array(returnData), encoding: .utf8) ?? ""
    }



    // TODO: Only matches first character, extend
    func hasPrefix(_ matchingString: String) -> Bool {
        if self.first == UInt8(matchingString) {
            return true
        }
        return false
    }

    // TODO: Check bounds
    func dropFirst() -> [UInt8] {
        return Array(self[1...])
    }

    // DDFFetchVariable()
    /// fetchArray()
    /// Fetch a variable length array from a record, and allocate it as a new array.
    func fetchArray(maximumLength: Int,
                    firstDelimiter: UInt8,
                    secondDelimiter: UInt8,
                    completion: (_ count: Int, _ value: [UInt8]) -> Void) {
        var i = 0
        var consumedCount = 0

        // Find any delimiter
        while i < maximumLength - 1 && self[i] != firstDelimiter && self[i] != secondDelimiter {
            i += 1
        }
        consumedCount = i
        if i < maximumLength && (self[i] == firstDelimiter || self[i] == secondDelimiter) {
            consumedCount += 1
        }
        completion(consumedCount, Array(self[0..<i])) // Skip the delimiter
        //return String(bytes: pszRecord[0...i], encoding: .utf8)!
    }

//    public func fetchArray(maximumLength: Int,
//                            firstDelimiter: UInt8,
//                            secondDelimiter: UInt8,
//                            completion: (_ count: Int, _ value: [UInt8]) -> Void)  {
//        let result = fetchArray(maximumLength: maximumLength, firstDelimiter: firstDelimiter, secondDelimiter: secondDelimiter)
//        guard let count = result.1, let value = result.1 else {
//            completion(result.0, "")
//        }
//        if result.1.isEmpty {
//            completion(result.0, [])
//            return
//        }
//        completion(result.0, result.1)
//    }

    func fetchString(maximumLength: Int,
                     firstDelimiter: UInt8,
                     secondDelimiter: UInt8,
                     completion: (_ count: Int, _ value: [UInt8]) -> Void)  {
        fetchArray(maximumLength: maximumLength, firstDelimiter: firstDelimiter, secondDelimiter: secondDelimiter, completion: { count, data in
            completion(count, data)
        })
    }
}
