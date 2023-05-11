//
//  DDFFieldDefinition.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 2/5/23.
//

import Foundation

@objc class DDFFieldDefinition: NSObject {

    private(set) var _tag: String?
    var _fieldName: [UInt8] = []
    var poModule: DDFModule?
    var _arrayDescr = ""
    var _formatControls: [UInt8] = []
    var bRepeatingSubfields: Bool
    private(set) var nFixedWidth: Int    // zero if variable.
    var _data_struct_code: DDF_data_struct_code
    var _data_type_code: DDF_data_type_code

    var subfieldDefinitions: [DDFSubfieldDefinition] = []

    @objc enum DDF_data_struct_code: Int {
        case dsc_elementary,
             dsc_vector,
             dsc_array,
             dsc_concatenated
    }

    @objc enum DDF_data_type_code: Int {
        case dtc_char_string,
             dtc_implicit_point,
             dtc_explicit_point,
             dtc_explicit_point_scaled,
             dtc_char_bit_string,
             dtc_bit_string,
             dtc_mixed_data_type
    };

    //public:
    @objc override init() {
        poModule = nil
        bRepeatingSubfields = false
        nFixedWidth = 0
        _data_struct_code = .dsc_elementary
        _data_type_code = .dtc_char_string
        super.init()

    }

    @objc deinit {
        _tag = nil
        _fieldName.removeAll()
        _formatControls.removeAll()
        subfieldDefinitions.removeAll()
    }

    @objc func create(pszTag: String,
                      pszFieldName: String,
                      pszDescription: String?,
                      eDataStructCode: DDF_data_struct_code,
                      eDataTypeCode: DDF_data_type_code,
                      pszFormat: String?) -> Bool  {
        //    assert(pszTag == NULL);
        poModule = nil
        _tag = pszTag
        _fieldName = Array(pszFieldName.utf8)
        _arrayDescr = pszDescription != nil ? pszDescription! : "" //.utf8CString
        _formatControls = [0]
        _data_struct_code = eDataStructCode
        _data_type_code = eDataTypeCode

        if pszFormat != nil {
            _formatControls = Array(pszFormat!.utf8)
        }
        if pszDescription != nil && pszDescription == "*" {
            bRepeatingSubfields = true
        }
        return true
    }

    @objc func addSubfield(poNewSFDefn: DDFSubfieldDefinition,
                           bDontAddToFormat: Bool = false) {
        subfieldDefinitions.append(poNewSFDefn)
        if bDontAddToFormat {
            return
        }

        // Add this format to the format list.  We don't bother aggregating formats here.
        if _formatControls.count == 0 {
            _formatControls = Array("()".utf8)
        }

        let nOldLen = _formatControls.count

        var pszNewFormatControls = [UInt8](repeating: 0, count: nOldLen + 3 + poNewSFDefn.getFormat.count)
        pszNewFormatControls.insert(contentsOf: _formatControls, at: 0)
        pszNewFormatControls[nOldLen-1] = 0
        if pszNewFormatControls[nOldLen-2] != "(".asciiValue {
            pszNewFormatControls.append(",".asciiValue)
        }
        pszNewFormatControls.append(contentsOf: poNewSFDefn.getFormat.utf8)
        pszNewFormatControls.append(")".asciiValue)

        _formatControls.removeAll()
        _formatControls = pszNewFormatControls;

        // Add the subfield name to the list.
        //_arrayDescr = (char *) realloc(_arrayDescr,strlen(_arrayDescr)+poNewSFDefn.name.length+2);
        if _arrayDescr.count > 0 {
            _arrayDescr.append("!")
        }
        _arrayDescr.append(poNewSFDefn.name)
    }

    @objc func addSubfield(pszName: String, pszFormat: String) {
        let poSFDefn: DDFSubfieldDefinition = DDFSubfieldDefinition()
        poSFDefn.name = pszName
        poSFDefn.setFormat(pszFormat)
        addSubfield(poNewSFDefn: poSFDefn, bDontAddToFormat: false)
    }

    @objc func generateDDREntry(ppachData: String, pnLength: Int, completion: (_ success: Bool,
                                                                                _ ppachData: [UInt8],
                                                                                _ pnLength: Int)->(Void)) {
        var _pnLength = pnLength
        var _ppachData = ppachData.byteArray
        _pnLength = 9 + _fieldName.count + 1 + _arrayDescr.count + 1 + _formatControls.count + 1

        if _formatControls.count == 0 {
            _pnLength -= 1
        }
        if _ppachData.isEmpty {
            completion(true, _ppachData, _pnLength)
        }
        _ppachData = [UInt8](repeating: 0, count: pnLength + 1)

        if _data_struct_code == .dsc_elementary {
            _ppachData[0] = "0".asciiValue
        } else if _data_struct_code == .dsc_vector {
            _ppachData[0] = "1".asciiValue
        } else if _data_struct_code == .dsc_array {
            _ppachData[0] = "2".asciiValue
        } else if _data_struct_code == .dsc_concatenated {
            _ppachData[0] = "3".asciiValue
        }

        if _data_type_code == .dtc_char_string {
            _ppachData[1] = "0".asciiValue
        } else if _data_type_code == .dtc_implicit_point {
            _ppachData[1] = "1".asciiValue
        } else if _data_type_code == .dtc_explicit_point {
            _ppachData[1] = "2".asciiValue
        } else if _data_type_code == .dtc_explicit_point_scaled {
            _ppachData[1] = "3".asciiValue
        } else if _data_type_code == .dtc_char_bit_string {
            _ppachData[1] = "4".asciiValue
        } else if _data_type_code == .dtc_bit_string {
            _ppachData[1] = "5".asciiValue
        } else if _data_type_code == .dtc_mixed_data_type {
            _ppachData[1] = "6".asciiValue
        }
        _ppachData[2] = "0".asciiValue
        _ppachData[3] = "0".asciiValue
        _ppachData[4] = ";".asciiValue
        _ppachData[5] = "&".asciiValue
        _ppachData[6] = " ".asciiValue
        _ppachData[7] = " ".asciiValue
        _ppachData[8] = " ".asciiValue
        let str = String(format: "%s%c%s", _fieldName, DDF_UNIT_TERMINATOR, _arrayDescr)
        _ppachData.insert(contentsOf: Array(str.utf8), at: 9)
        if _formatControls.count > 0 {
            let str = String(format: "%c%s", DDF_UNIT_TERMINATOR, _formatControls)
            _ppachData.insert(contentsOf: Array(str.utf8), at: ppachData.count) // Possibly +1
        }
        let str2 = String(format: "%c", DDF_FIELD_TERMINATOR)
        _ppachData.insert(contentsOf: Array(str2.utf8), at: ppachData.count)  // Possibly +1
        completion(true, _ppachData, _pnLength)
    }


    @objc func initialize(poModuleIn: DDFModule,
                          pszTag pszTagIn: String,
                          nSize nFieldEntrySize: Int,
                          pachRecord pachFieldArea: String) -> Bool {
        let pachFieldArea = Array(pachFieldArea.utf8)
        var iFDOffset: Int32 = poModuleIn.getFieldControlLength
        var nCharsConsumed: Int32 = 0

        poModule = poModuleIn
        _tag = pszTagIn
        assert(pachFieldArea.count > 1)

        // Set the data struct and type codes.
        switch pachFieldArea[0] {
        case "0".asciiValue:
            _data_struct_code = .dsc_elementary

        case "1".asciiValue:
            _data_struct_code = .dsc_vector

        case "2".asciiValue:
            _data_struct_code = .dsc_array

        case "3".asciiValue:
            _data_struct_code = .dsc_concatenated

        default:
            debugPrint("Unrecognised data_struct_code value %c.\nField %@ initialization incorrect.", pachFieldArea[0], _tag ?? "UNKNOWN")
            _data_struct_code = .dsc_elementary
        }

        switch pachFieldArea[1] {
        case "0".asciiValue:
            _data_type_code = .dtc_char_string

        case "1".asciiValue:
            _data_type_code = .dtc_implicit_point

        case "2".asciiValue:
            _data_type_code = .dtc_explicit_point

        case "3".asciiValue:
            _data_type_code = .dtc_explicit_point_scaled

        case "4".asciiValue:
            _data_type_code = .dtc_char_bit_string

        case "5".asciiValue:
            _data_type_code = .dtc_bit_string

        case "6".asciiValue:
            _data_type_code = .dtc_mixed_data_type

        default:
            debugPrint("Unrecognised data_type_code value %c.\nField %@ initialization incorrect.", pachFieldArea[1], _tag ?? "UNKNOWN")
            _data_type_code = .dtc_char_string
        }

        // Capture the field name, description (sub field names), and format statements.
        var bytes1 = Array(pachFieldArea[Int(iFDOffset)...]).map { CChar($0) }
        bytes1.append(0)
        guard let fn = DDFUtils.ddfFetchVariable(bytes1,
                                           nMaxChars: Int32(nFieldEntrySize) - iFDOffset,
                                           nDelimChar1: DDF_UNIT_TERMINATOR,
                                           nDelimChar2: DDF_FIELD_TERMINATOR,
                                                 pnConsumedChars: &nCharsConsumed) else {
            debugPrint("Error fetching _fieldName")
            return false
        }
        debugPrint("Fetched _fieldName: \(_fieldName)")
        _fieldName = fn.byteArray
        iFDOffset += nCharsConsumed;

        var bytes2 = Array(pachFieldArea[Int(iFDOffset)...]).map { CChar($0) }
        bytes2.append(0)
        _arrayDescr = DDFUtils.ddfFetchVariable(bytes2,
                                                nMaxChars: Int32(nFieldEntrySize) - iFDOffset,
                                                nDelimChar1: DDF_UNIT_TERMINATOR,
                                                nDelimChar2: DDF_FIELD_TERMINATOR,
                                                pnConsumedChars: &nCharsConsumed)
        debugPrint("Fetched _arrayDescr: \(_arrayDescr)")
        if nCharsConsumed > 0 {
            iFDOffset += nCharsConsumed;
        }

        var bytes3 = Array(pachFieldArea[Int(iFDOffset)...]).map { CChar($0) }
        bytes3.append(0)
        guard let fc = DDFUtils.ddfFetchVariable(bytes3,
                                                 nMaxChars: Int32(nFieldEntrySize) - iFDOffset,
                                                 nDelimChar1: DDF_UNIT_TERMINATOR,
                                                 nDelimChar2: DDF_FIELD_TERMINATOR,
                                                 pnConsumedChars: &nCharsConsumed) else {
            debugPrint("Error fetching _formatControls")
            return false
        }
        debugPrint("Fetched _formatControls: \(_formatControls)")
        _formatControls = fc.byteArray

        // Parse the subfield info.
        if _data_struct_code != .dsc_elementary {
            if !buildSubfields() {
                return false
            }
            if !applyFormats() {
                return false
            }
        }
        return true
    }

    @objc func buildSubfields() -> Bool {
        var subfieldNames: [String]
        var pszSublist: String = _arrayDescr

        /* -------------------------------------------------------------------- */
        /*      It is valid to define a field with _arrayDesc                   */
        /*      '*STPT!CTPT!ENPT*YCOO!XCOO' and formatControls '(2b24)'.        */
        /*      This basically indicates that there are 3 (YCOO,XCOO)           */
        /*      structures named STPT, CTPT and ENPT.  But we can't handle      */
        /*      such a case gracefully here, so we just ignore the              */
        /*      "structure names" and treat such a thing as a repeating         */
        /*      YCOO/XCOO array.  This occurs with the AR2D field of some       */
        /*      AML S-57 files for instance.                                    */
        /*                                                                      */
        /*      We accomplish this by ignoring everything before the last       */
        /*      '*' in the subfield list.                                       */
        /* -------------------------------------------------------------------- */
        if let range = pszSublist.range(of: "*", options: .backwards) {
            pszSublist = String(pszSublist[range.upperBound...])
        }

        // Strip off the repeating marker, when it occurs, but mark our field as repeating.
        assert(pszSublist.count > 1)
        if pszSublist[0] == "*" {
            bRepeatingSubfields = true
            pszSublist = String(pszSublist[1...])
        }

        // split list of fields.
        subfieldNames = pszSublist.components(separatedBy: "!")

        // minimally initialize the subfields.  More will be done later.
        for iSF in 0 ..< subfieldNames.count {
            let poSFDefn: DDFSubfieldDefinition = DDFSubfieldDefinition()
            poSFDefn.name = subfieldNames[iSF];
            addSubfield(poNewSFDefn: poSFDefn, bDontAddToFormat: true)
        }
        subfieldNames.removeAll()
        return true
    }

    @objc func applyFormats() -> Bool {
        var pszFormatList: [UInt8] = []
        var papszFormatItems: [[UInt8]]

        // DEBUG:
        var fc: [UInt8] = [UInt8](repeating: 0, count: _formatControls.count+1)
        fc.insert(contentsOf: _formatControls, at: 0)
        debugPrint("_formatControls: \(String(cString: fc))")
        // end DEBUG

        // Verify that the format string is contained within brackets.
        if _formatControls.count < 2
            || _formatControls[0] != "(".asciiValue
            || _formatControls[_formatControls.count-1] != ")".asciiValue {
            debugPrint("Format controls for \(_tag ?? "MISSING") field missing brackets: \(_formatControls)")
            return false
        }

        // Duplicate the string, and strip off the brackets.
        pszFormatList = _formatControls.expandFormat()

        // Tokenize based on commas.
        papszFormatItems = pszFormatList.components(seperatedBy: ",".asciiValue)
        //pszFormatList = nil;

        // Apply the format items to subfields.
        var iFormatItem: Int = 0
        for index in 0..<papszFormatItems.count {
            if papszFormatItems[index].isEmpty {
                break
            }
            iFormatItem = index

            var pszPastPrefix: [UInt8] = papszFormatItems[iFormatItem]
            var ppCount = 0
            // FIXME: Is this supposed to find the last occurance of a number?
//            for i in 0 ..< pszPastPrefix.count {
//                if pszPastPrefix[i] >= "0".asciiValue && pszPastPrefix[i] <= "9".asciiValue {
//                    ppCount += 1  // The start index i n pszPastPrefix
//                }
//            }
            debugPrint(ppCount)

            // Did we get too many formats for the subfields created by names?
            // This may be legal by the 8211 specification, but isn't encountered
            // in any formats we care about so we just blow.
            if iFormatItem >= subfieldDefinitions.count {
                debugPrint("Got more formats than subfields for field '%@'.", _tag ?? "MISSING")
                break
            }
            // FIXME:
            let str = String(bytes: Array(pszPastPrefix[ppCount...]), encoding: .utf8)
            let result = subfieldDefinitions[iFormatItem].setFormat(str)
            if result == 0 { // false
                return false
            }
        }

        // Verify that we got enough formats, cleanup and return.
        papszFormatItems.removeAll()

        if iFormatItem < ( subfieldDefinitions.count - 1) {
            debugPrint("Got less formats than subfields for field: \(_tag ?? "MISSING").");
            return false
        }

        // If all the fields are fixed width, then we are fixed width too.
        // This is important for repeating fields.
        nFixedWidth = 0;
        for i in 0 ..< subfieldDefinitions.count {
            if subfieldDefinitions[i].getWidth == 0 {
                nFixedWidth = 0
                break
            } else {
                nFixedWidth += Int(subfieldDefinitions[i].getWidth)
            }
        }
        return true
    }

    @objc func dump(fp: FILE ) {
        var pszValue = ""

        //        fprintf(fp, "  DDFFieldDefn:\n");
        //        fprintf(fp, "      Tag = '%s'\n", [_tag UTF8String]);
        //        fprintf(fp, "      _fieldName = '%s'\n", [_fieldName cStringUsingEncoding: NSUTF8StringEncoding]);
        //        fprintf(fp, "      _arrayDescr = '%s'\n", _arrayDescr);
        //        fprintf(fp, "      _formatControls = '%s'\n", _formatControls);
        //
        //        switch _data_struct_code {
        //        case .dsc_elementary:
        //            pszValue = "elementary"
        //
        //        case .dsc_vector:
        //            pszValue = "vector"
        //
        //        case .dsc_array:
        //            pszValue = "array"
        //
        //        case .dsc_concatenated:
        //            pszValue = "concatenated"
        //
        //        default:
        //            //            assert(FALSE);
        //            pszValue = "(unknown)"
        //        }
        //
        //        fprintf(fp, "      _data_struct_code = %s\n", pszValue);
        //
        //        switch _data_type_code {
        //        case .dtc_char_string:
        //            pszValue = "char_string"
        //
        //        case .dtc_implicit_point:
        //            pszValue = "implicit_point"
        //
        //        case .dtc_explicit_point:
        //            pszValue = "explicit_point"
        //
        //        case .dtc_explicit_point_scaled:
        //            pszValue = "explicit_point_scaled"
        //
        //        case .dtc_char_bit_string:
        //            pszValue = "char_bit_string"
        //
        //        case .dtc_bit_string:
        //            pszValue = "bit_string"
        //
        //        case .dtc_mixed_data_type:
        //            pszValue = "mixed_data_type"
        //
        //        default:
        //            //            assert(FALSE);
        //            pszValue = "(unknown)"
        //        }
        //
        //        fprintf(fp, "      _data_type_code = %s\n", pszValue);
        //
        //        for i in 0 ..< subfieldDefinitions.count {
        //            subfieldDefinitions[i].dump(fp)
        //        }
    }

    /** Fetch a pointer to the field name (tag).
     * - Returns: this is an internal copy and shouldn't be freed.
     */
    @objc func getName() -> String {
        return _tag ?? ""
    }

    /** Fetch a longer description of this field.
     * - Returns: this is an internal copy and shouldn't be freed.
     */
    @objc func getDescription() -> String {
        return String(bytes: _fieldName, encoding: .utf8) ?? ""
    }

    /** Get the number of subfields. */
    @objc func getSubfieldCount() -> Int {
        return subfieldDefinitions.count
    }

    /**
     * Get the width of this field.  This function isn't normally used
     * by applications.
     *
     * - Returns: The width of the field in bytes, or zero if the field is not
     * apparently of a fixed width.
     */
    @objc func getFixedWidth() -> Int {
        return nFixedWidth
    }

    /**
     * Fetch repeating flag.
     * @see DDFField::GetRepeatCount()
     * - Returns: TRUE if the field is marked as repeating.
     */
    @objc func isRepeating() -> Bool {
        return bRepeatingSubfields
    }

    /** this is just for an S-57 hack for swedish data */
    @objc func setRepeatingFlag(n: Bool) {
        bRepeatingSubfields = n
    }

    @objc func getSubfield(i: Int) -> DDFSubfieldDefinition? {
        if i < 0 || i >= subfieldDefinitions.count {
            return nil
        }
        return subfieldDefinitions[i]
    }

    @objc func findSubfieldDefn(pszMnemonic: String) -> DDFSubfieldDefinition? {
        for i in 0 ..< subfieldDefinitions.count {
            if pszMnemonic == subfieldDefinitions[i].name {
                return subfieldDefinitions[i]
            }
        }
        return nil
    }


    //    func expandFormat(pszSrc: [UInt8]) -> String {
    //        var nDestMax = 32
    //        var pszDest = [UInt8](repeating: 0, count: nDestMax + 1)
    //        var iSrc = 0
    //        var iDst = 0
    //        var nRepeat = 0
    //
    //        if pszSrc.count > 1 {
    //            assert(pszSrc.count > iSrc)
    //            while pszSrc[iSrc] != 0 {
    //                /* This is presumably an extra level of brackets around some
    //                 binary stuff related to rescaning which we don't care to do
    //                 (see 6.4.3.3 of the standard.  We just strip off the extra
    //                 layer of brackets */
    //                assert(iSrc-1 >= 0)
    //                if((iSrc == 0 || [pszSrc characterAtIndex: iSrc-1] == ',') && [pszSrc characterAtIndex: iSrc] == '(') {
    //                    char *pszContents = [self ExtractSubstring: [[pszSrc substringFromIndex: iSrc] UTF8String]];
    //                    char *pszExpandedContents = [[self ExpandFormat: [NSString stringWithUTF8String: pszContents]] cStringUsingEncoding: NSUTF8StringEncoding];
    //
    //                    if(((int)strlen(pszExpandedContents) + (int)strlen(pszDest) + 1) > nDestMax) {
    //                        nDestMax = 2 * ((int)strlen(pszExpandedContents) + (int)strlen(pszDest));
    //                        pszDest = (char *) realloc(pszDest, nDestMax+1);
    //                    }
    //                    strcat(pszDest, pszExpandedContents);
    //                    iDst = (int)strlen(pszDest);
    //                    iSrc = iSrc + (int)strlen(pszContents) + 2;
    //
    //                    pszContents = nil;
    //                    pszExpandedContents = nil;
    //                } else if((iSrc == 0 || [pszSrc characterAtIndex: iSrc-1] == ',') && isdigit([pszSrc characterAtIndex: iSrc])) {
    //                    // this is a repeated subclause
    //                    const char *pszNext;
    //                    nRepeat = atoi([pszSrc UTF8String]+iSrc);
    //
    //                    // skip over repeat count.
    //                    for(pszNext = [pszSrc UTF8String]+iSrc; isdigit(*pszNext); pszNext++) {
    //                        iSrc++;
    //                    }
    //
    //                    char *pszContents = [self ExtractSubstring: pszNext];
    //                    char *pszExpandedContents = [[self ExpandFormat: [NSString stringWithUTF8String: pszContents]] cStringUsingEncoding: NSUTF8StringEncoding];
    //
    //                    for(int i = 0; i < nRepeat; i++) {
    //                        if((int)(strlen(pszExpandedContents) + strlen(pszDest) + 1) > nDestMax ) {
    //                            nDestMax = 2 * ((int)strlen(pszExpandedContents) + (int)strlen(pszDest));
    //                            pszDest = (char *) realloc(pszDest,nDestMax+1);
    //                        }
    //                        strcat(pszDest, pszExpandedContents);
    //                        if(i < nRepeat-1) {
    //                            strcat(pszDest, ",");
    //                        }
    //                    }
    //
    //                    iDst = (int)strlen(pszDest);
    //
    //                    if(pszNext[0] == '(') {
    //                        iSrc = iSrc + (int)strlen(pszContents) + 2;
    //                    } else {
    //                        iSrc = iSrc + (int)strlen(pszContents);
    //                    }
    //                    pszContents = nil;
    //                    pszExpandedContents = nil;
    //                } else {
    //                    if(iDst+1 >= nDestMax) {
    //                        nDestMax = 2 * iDst;
    //                        pszDest = (char *) realloc(pszDest, nDestMax);
    //                    }
    //                    pszDest[iDst++] = [pszSrc characterAtIndex: iSrc++];
    //                    pszDest[iDst] = '\0';
    //                }
    //            }
    //        }
    //        return [NSString stringWithCString: pszDest encoding: NSUTF8StringEncoding];
    //    }

    @objc func getDefaultValue(pnSize: Int = 0, completion: (String, Int)->()) {
        // Loop once collecting the sum of the subfield lengths
        var nTotalSize = Int32(0)
        var _pnSize = pnSize

        for iSubfield in 0 ..< subfieldDefinitions.count {
            var nSubfieldSize: Int32 = 0
            if (subfieldDefinitions[iSubfield].getDefaultValue(nil,
                                                               nBytesAvailable: 0,
                                                               pnBytesUsed: &nSubfieldSize) == 0) {
                completion("", _pnSize)
            }
            nTotalSize += nSubfieldSize
        }
        // Allocate buffer.
        let pachData = [UInt8](repeating: 0, count: Int(nTotalSize))
        if _pnSize != 0 {
            _pnSize = Int(nTotalSize)
        }
        // Loop again, collecting actual default values.
        var nOffset = 0
        for iSubfield in 0 ..< subfieldDefinitions.count {
            var nSubfieldSize: Int32 = 0
            let data = Array(pachData[nOffset...])
            let df = subfieldDefinitions[iSubfield].getDefaultValue(String(bytes: data, encoding: .utf8),
                                                                    nBytesAvailable: nTotalSize - Int32(nOffset),
                                                                    pnBytesUsed: &nSubfieldSize)
            if df == 0 {
                //            assert(FALSE);
                completion("", _pnSize)
            }
            nOffset += Int(nSubfieldSize)
        }
        //    assert(nOffset == nTotalSize);
        completion(String(bytes: pachData, encoding: .utf8) ?? "", _pnSize)
    }

    func log() {
        var pszValue = ""

        debugPrint("  DDFFieldDefn:\n");
        debugPrint("      Tag = '%@'\n", _tag ?? "MISSING")
        debugPrint("      _fieldName = '%s'\n", _fieldName)
        debugPrint("      _arrayDescr = '%s'\n", _arrayDescr)
        debugPrint("      _formatControls = '%s'\n", _formatControls)

        switch(_data_struct_code) {
        case .dsc_elementary:
            pszValue = "elementary"

        case .dsc_vector:
            pszValue = "vector"

        case .dsc_array:
            pszValue = "array"

        case .dsc_concatenated:
            pszValue = "concatenated"

        default:
            pszValue = "(unknown)"
        }

        debugPrint("      _data_struct_code = %s\n", pszValue)

        switch(_data_type_code) {
        case .dtc_char_string:
            pszValue = "char_string"

        case .dtc_implicit_point:
            pszValue = "implicit_point"

        case .dtc_explicit_point:
            pszValue = "explicit_point"

        case .dtc_explicit_point_scaled:
            pszValue = "explicit_point_scaled"

        case .dtc_char_bit_string:
            pszValue = "char_bit_string"

        case .dtc_bit_string:
            pszValue = "bit_string"

        case .dtc_mixed_data_type:
            pszValue = "mixed_data_type"

        default:
            pszValue = "(unknown)"
        }

        debugPrint("      _data_type_code = %s\n", pszValue)

        for i in 0 ..< subfieldDefinitions.count {
            subfieldDefinitions[i].log()
        }
    }
}

//-(char *) ExtractSubstring: (const char *) pszSrc {
//    int nBracket=0, i;
//    char *pszReturn;
//
//    for(i = 0; pszSrc[i] != '\0' && (nBracket > 0 || pszSrc[i] != ','); i++) {
//        if(pszSrc[i] == '(') {
//            nBracket++;
//        } else if(pszSrc[i] == ')') {
//            nBracket--;
//        }
//    }
//
//    if(pszSrc[0] == '(') {
//        pszReturn = strdup(pszSrc + 1);
//        pszReturn[i-2] = '\0';
//    } else {
//        pszReturn = strdup(pszSrc);
//        pszReturn[i] = '\0';
//    }
//    return pszReturn;
//}

