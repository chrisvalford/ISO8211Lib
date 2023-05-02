//
//  DDFFieldDefn.m
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFFieldDefinition.h"
#import "DDFUtils.h"

@implementation DDFFieldDefinition

@synthesize _fieldName;
//private:

DDFModule * poModule;


char *      _arrayDescr;
char *      _formatControls;

int         bRepeatingSubfields;
int         nFixedWidth;    // zero if variable.

DDF_data_struct_code _data_struct_code;

DDF_data_type_code   _data_type_code;

NSMutableArray *subfieldDefinitions; //[DDFSubfieldDefinition] 

-(instancetype) init {
    self = [super init];
    if (self) {
        poModule = NULL;
        _fieldName = NULL;
        _arrayDescr = NULL;
        _formatControls = NULL;
        subfieldDefinitions = [[NSMutableArray alloc] init];
        bRepeatingSubfields = FALSE;
        nFixedWidth = 0;
    }
    return self;
}

-(void)dealloc {
    _tag = nil;
    _fieldName = nil;
    _arrayDescr = nil;
    _formatControls = nil;
    [subfieldDefinitions removeAllObjects];
}

-(int) Create: (NSString *) pszTag
 pszFieldName: (NSString *) pszFieldName
pszDescription: (NSString *) pszDescription
eDataStructCode: (DDF_data_struct_code) eDataStructCode
eDataTypeCode: (DDF_data_type_code) eDataTypeCode
    pszFormat: (NSString *) pszFormat { // TODO: = NULL;
//    assert(pszTag == NULL);
    poModule = NULL;
    pszTag = [pszTag copy];
    _fieldName = [pszFieldName copy];
    _arrayDescr = [pszDescription UTF8String];
    _formatControls = "";
    _data_struct_code = eDataStructCode;
    _data_type_code = eDataTypeCode;
    
    if(pszFormat != NULL) {
        _formatControls = [pszFormat UTF8String];
    }
    if(pszDescription != NULL && [pszDescription isEqualToString: @"*"]) {
        bRepeatingSubfields = TRUE;
    }
    return TRUE;
}

-(void) AddSubfield: (DDFSubfieldDefinition *) poNewSFDefn
   bDontAddToFormat: (int) bDontAddToFormat { // TODO: = false
    [subfieldDefinitions addObject: poNewSFDefn];
    if(bDontAddToFormat) {
        return;
    }
    
    // Add this format to the format list.  We don't bother aggregating formats here.
    if(_formatControls == NULL || strlen(_formatControls) == 0) {
        free(_formatControls);
        _formatControls = strdup("()");
    }
    
    int nOldLen = (int)strlen(_formatControls);
    
    char *pszNewFormatControls = (char *)malloc(nOldLen+3+[[poNewSFDefn GetFormat] length]);
    strcpy(pszNewFormatControls, _formatControls);
    pszNewFormatControls[nOldLen-1] = '\0';
    if(pszNewFormatControls[nOldLen-2] != '(') {
        strcat( pszNewFormatControls, "," );
    }
    strcat(pszNewFormatControls, [[poNewSFDefn GetFormat] cStringUsingEncoding: NSUTF8StringEncoding]);
    strcat(pszNewFormatControls, ")");
    
    free(_formatControls);
    _formatControls = pszNewFormatControls;
    
    // Add the subfield name to the list.
    if(_arrayDescr == NULL) {
        _arrayDescr = strdup("");
    }
    _arrayDescr = (char *) realloc(_arrayDescr,
                                   strlen(_arrayDescr)+poNewSFDefn.name.length+2);
    if(strlen(_arrayDescr) > 0) {
        strcat(_arrayDescr, "!");
    }
    strcat(_arrayDescr, poNewSFDefn.name.UTF8String);
}

-(void) AddSubfield: (NSString *)pszName
          pszFormat: (NSString *) pszFormat {
    DDFSubfieldDefinition *poSFDefn = [[DDFSubfieldDefinition alloc] init];
    
    //[poSFDefn SetName: pszName];
    poSFDefn.name = pszName;
    [poSFDefn SetFormat: pszFormat];
    [self AddSubfield: poSFDefn bDontAddToFormat: FALSE];
}

-(int) GenerateDDREntry: (char **) ppachData
               pnLength: (int *) pnLength {
    *pnLength = 9 + [_fieldName length] + 1
    + (int)strlen(_arrayDescr) + 1
    + (int)strlen(_formatControls) + 1;
    
    if(strlen(_formatControls) == 0) {
        *pnLength -= 1;
    }
    if(ppachData == NULL) {
        return TRUE;
    }
    *ppachData = (char *) malloc(*pnLength+1);
    
    if(_data_struct_code == dsc_elementary) {
        (*ppachData)[0] = '0';
    } else if(_data_struct_code == dsc_vector) {
        (*ppachData)[0] = '1';
    } else if(_data_struct_code == dsc_array) {
        (*ppachData)[0] = '2';
    } else if(_data_struct_code == dsc_concatenated) {
        (*ppachData)[0] = '3';
    }
    
    if(_data_type_code == dtc_char_string) {
        (*ppachData)[1] = '0';
    } else if(_data_type_code == dtc_implicit_point) {
        (*ppachData)[1] = '1';
    } else if(_data_type_code == dtc_explicit_point) {
        (*ppachData)[1] = '2';
    } else if(_data_type_code == dtc_explicit_point_scaled) {
        (*ppachData)[1] = '3';
    } else if(_data_type_code == dtc_char_bit_string) {
        (*ppachData)[1] = '4';
    } else if(_data_type_code == dtc_bit_string) {
        (*ppachData)[1] = '5';
    } else if(_data_type_code == dtc_mixed_data_type) {
        (*ppachData)[1] = '6';
    }
    (*ppachData)[2] = '0';
    (*ppachData)[3] = '0';
    (*ppachData)[4] = ';';
    (*ppachData)[5] = '&';
    (*ppachData)[6] = ' ';
    (*ppachData)[7] = ' ';
    (*ppachData)[8] = ' ';
    sprintf(*ppachData + 9, "%s%c%s", [_fieldName cStringUsingEncoding: NSUTF8StringEncoding], DDF_UNIT_TERMINATOR, _arrayDescr);
    if(strlen(_formatControls) > 0) {
        sprintf(*ppachData + strlen(*ppachData), "%c%s", DDF_UNIT_TERMINATOR, _formatControls);
    }
    sprintf(*ppachData + strlen(*ppachData), "%c", DDF_FIELD_TERMINATOR);
    return TRUE;
}

-(int) Initialize: (DDFModule *) poModuleIn
           pszTag: (NSString *) pszTagIn
            nSize: (int) nFieldEntrySize
       pachRecord: (NSString *) pachFieldArea {
    int iFDOffset = [poModuleIn GetFieldControlLength];
    int nCharsConsumed;
    
    poModule = poModuleIn;
    _tag = pszTagIn;

    assert([pachFieldArea length] > 1);
    // Set the data struct and type codes.
    switch([pachFieldArea characterAtIndex: 0]) {
        case '0':
            _data_struct_code = dsc_elementary;
            break;
            
        case '1':
            _data_struct_code = dsc_vector;
            break;
            
        case '2':
            _data_struct_code = dsc_array;
            break;
            
        case '3':
            _data_struct_code = dsc_concatenated;
            break;
            
        default:
            NSLog(@"Unrecognised data_struct_code value %c.\nField %@ initialization incorrect.", [pachFieldArea characterAtIndex: 0], _tag);
            _data_struct_code = dsc_elementary;
    }
    
    switch([pachFieldArea characterAtIndex: 1]) {
        case '0':
            _data_type_code = dtc_char_string;
            break;
            
        case '1':
            _data_type_code = dtc_implicit_point;
            break;
            
        case '2':
            _data_type_code = dtc_explicit_point;
            break;
            
        case '3':
            _data_type_code = dtc_explicit_point_scaled;
            break;
            
        case '4':
            _data_type_code = dtc_char_bit_string;
            break;
            
        case '5':
            _data_type_code = dtc_bit_string;
            break;
            
        case '6':
            _data_type_code = dtc_mixed_data_type;
            break;
            
        default:
            NSLog(@"Unrecognised data_type_code value %c.\nField %@ initialization incorrect.", [pachFieldArea characterAtIndex: 1], _tag);
            _data_type_code = dtc_char_string;
    }
    
    // Capture the field name, description (sub field names), and format statements.
    _fieldName = [DDFUtils DDFFetchVariable: [[pachFieldArea substringFromIndex: iFDOffset] UTF8String]
                                  nMaxChars: nFieldEntrySize - iFDOffset
                                nDelimChar1: DDF_UNIT_TERMINATOR
                                nDelimChar2: DDF_FIELD_TERMINATOR
                            pnConsumedChars: &nCharsConsumed];
    iFDOffset += nCharsConsumed;
    
    _arrayDescr = [[DDFUtils DDFFetchVariable: [[pachFieldArea substringFromIndex: iFDOffset] UTF8String]
                                   nMaxChars: nFieldEntrySize - iFDOffset
                                 nDelimChar1: DDF_UNIT_TERMINATOR
                                 nDelimChar2: DDF_FIELD_TERMINATOR
                             pnConsumedChars: &nCharsConsumed] cStringUsingEncoding: NSUTF8StringEncoding];
    iFDOffset += nCharsConsumed;
    
    _formatControls = [[DDFUtils DDFFetchVariable: [[pachFieldArea substringFromIndex: iFDOffset] UTF8String]
                                       nMaxChars: nFieldEntrySize - iFDOffset
                                     nDelimChar1: DDF_UNIT_TERMINATOR
                                     nDelimChar2: DDF_FIELD_TERMINATOR
                                 pnConsumedChars: &nCharsConsumed] cStringUsingEncoding: NSUTF8StringEncoding];
    
    // Parse the subfield info.
    if(_data_struct_code != dsc_elementary) {
        if(![self BuildSubfields]) {
            return FALSE;
        }
        if(![self ApplyFormats]) {
            return FALSE;
        }
    }
    return TRUE;
}

-(void) Dump: (FILE *) fp {
    const char *pszValue = "";
    
    fprintf(fp, "  DDFFieldDefn:\n");
    fprintf(fp, "      Tag = '%s'\n", [_tag UTF8String]);
    fprintf(fp, "      _fieldName = '%s'\n", [_fieldName cStringUsingEncoding: NSUTF8StringEncoding]);
    fprintf(fp, "      _arrayDescr = '%s'\n", _arrayDescr);
    fprintf(fp, "      _formatControls = '%s'\n", _formatControls);
    
    switch(_data_struct_code) {
        case dsc_elementary:
            pszValue = "elementary";
            break;
            
        case dsc_vector:
            pszValue = "vector";
            break;
            
        case dsc_array:
            pszValue = "array";
            break;
            
        case dsc_concatenated:
            pszValue = "concatenated";
            break;
            
        default:
//            assert(FALSE);
            pszValue = "(unknown)";
    }
    
    fprintf(fp, "      _data_struct_code = %s\n", pszValue);
    
    switch(_data_type_code) {
        case dtc_char_string:
            pszValue = "char_string";
            break;
            
        case dtc_implicit_point:
            pszValue = "implicit_point";
            break;
            
        case dtc_explicit_point:
            pszValue = "explicit_point";
            break;
            
        case dtc_explicit_point_scaled:
            pszValue = "explicit_point_scaled";
            break;
            
        case dtc_char_bit_string:
            pszValue = "char_bit_string";
            break;
            
        case dtc_bit_string:
            pszValue = "bit_string";
            break;
            
        case dtc_mixed_data_type:
            pszValue = "mixed_data_type";
            break;
            
        default:
//            assert(FALSE);
            pszValue = "(unknown)";
            break;
    }
    
    fprintf(fp, "      _data_type_code = %s\n", pszValue);
    
    for(int i = 0; i < [subfieldDefinitions count]; i++) {
        [subfieldDefinitions[i] Dump: fp];
    }
}

-(void) Log {
    const char *pszValue = "";
    
    NSLog(@"  DDFFieldDefn:\n");
    NSLog(@"      Tag = '%@'\n", _tag);
    NSLog(@"      _fieldName = '%s'\n", [_fieldName cStringUsingEncoding: NSUTF8StringEncoding]);
    NSLog(@"      _arrayDescr = '%s'\n", _arrayDescr);
    NSLog(@"      _formatControls = '%s'\n", _formatControls);
    
    switch(_data_struct_code) {
        case dsc_elementary:
            pszValue = "elementary";
            break;
            
        case dsc_vector:
            pszValue = "vector";
            break;
            
        case dsc_array:
            pszValue = "array";
            break;
            
        case dsc_concatenated:
            pszValue = "concatenated";
            break;
            
        default:
//            assert(FALSE);
            pszValue = "(unknown)";
    }
    
    NSLog(@"      _data_struct_code = %s\n", pszValue);
    
    switch(_data_type_code) {
        case dtc_char_string:
            pszValue = "char_string";
            break;
            
        case dtc_implicit_point:
            pszValue = "implicit_point";
            break;
            
        case dtc_explicit_point:
            pszValue = "explicit_point";
            break;
            
        case dtc_explicit_point_scaled:
            pszValue = "explicit_point_scaled";
            break;
            
        case dtc_char_bit_string:
            pszValue = "char_bit_string";
            break;
            
        case dtc_bit_string:
            pszValue = "bit_string";
            break;
            
        case dtc_mixed_data_type:
            pszValue = "mixed_data_type";
            break;
            
        default:
//            assert(FALSE);
            pszValue = "(unknown)";
            break;
    }
    
    NSLog(@"      _data_type_code = %s\n", pszValue);
    
    for(int i = 0; i < [subfieldDefinitions count]; i++) {
        [subfieldDefinitions[i] Log];
    }
}

-(DDFSubfieldDefinition *) GetSubfield: (int) i {
    if(i < 0 || i >= [subfieldDefinitions count]) {
//        assert(FALSE);
        return NULL;
    }
    return subfieldDefinitions[i];
}

-(DDFSubfieldDefinition *) FindSubfieldDefn: (NSString *) pszMnemonic {
    for(int i = 0; i < [subfieldDefinitions count]; i++) {
        if([pszMnemonic isEqualToString: [subfieldDefinitions[i] GetName]]) {
            return subfieldDefinitions[i];
        }
    }
    return NULL;
}

-(NSString *) ExpandFormat: (NSString *) pszSrc {
    int nDestMax = 32;
    char *pszDest = (char *) malloc(nDestMax+1);
    int iSrc, iDst;
    int nRepeat = 0;
    
    iSrc = 0;
    iDst = 0;
    pszDest[0] = '\0';
    if ([pszSrc length] > 1) {
        assert([pszSrc length] > iSrc);
        while([pszSrc characterAtIndex: iSrc] != '\0') {
            /* This is presumably an extra level of brackets around some
             binary stuff related to rescaning which we don't care to do
             (see 6.4.3.3 of the standard.  We just strip off the extra
             layer of brackets */
            assert(iSrc-1 >= 0);
            if((iSrc == 0 || [pszSrc characterAtIndex: iSrc-1] == ',') && [pszSrc characterAtIndex: iSrc] == '(') {
                char *pszContents = [self ExtractSubstring: [[pszSrc substringFromIndex: iSrc] UTF8String]];
                char *pszExpandedContents = [[self ExpandFormat: [NSString stringWithUTF8String: pszContents]] cStringUsingEncoding: NSUTF8StringEncoding];

                if(((int)strlen(pszExpandedContents) + (int)strlen(pszDest) + 1) > nDestMax) {
                    nDestMax = 2 * ((int)strlen(pszExpandedContents) + (int)strlen(pszDest));
                    pszDest = (char *) realloc(pszDest, nDestMax+1);
                }
                strcat(pszDest, pszExpandedContents);
                iDst = (int)strlen(pszDest);
                iSrc = iSrc + (int)strlen(pszContents) + 2;

                pszContents = nil;
                pszExpandedContents = nil;
            } else if((iSrc == 0 || [pszSrc characterAtIndex: iSrc-1] == ',') && isdigit([pszSrc characterAtIndex: iSrc])) {
                // this is a repeated subclause
                const char *pszNext;
                nRepeat = atoi([pszSrc UTF8String]+iSrc);

                // skip over repeat count.
                for(pszNext = [pszSrc UTF8String]+iSrc; isdigit(*pszNext); pszNext++) {
                    iSrc++;
                }

                char *pszContents = [self ExtractSubstring: pszNext];
                char *pszExpandedContents = [[self ExpandFormat: [NSString stringWithUTF8String: pszContents]] cStringUsingEncoding: NSUTF8StringEncoding];

                for(int i = 0; i < nRepeat; i++) {
                    if((int)(strlen(pszExpandedContents) + strlen(pszDest) + 1) > nDestMax ) {
                        nDestMax = 2 * ((int)strlen(pszExpandedContents) + (int)strlen(pszDest));
                        pszDest = (char *) realloc(pszDest,nDestMax+1);
                    }
                    strcat(pszDest, pszExpandedContents);
                    if(i < nRepeat-1) {
                        strcat(pszDest, ",");
                    }
                }

                iDst = (int)strlen(pszDest);

                if(pszNext[0] == '(') {
                    iSrc = iSrc + (int)strlen(pszContents) + 2;
                } else {
                    iSrc = iSrc + (int)strlen(pszContents);
                }
                pszContents = nil;
                pszExpandedContents = nil;
            } else {
                if(iDst+1 >= nDestMax) {
                    nDestMax = 2 * iDst;
                    pszDest = (char *) realloc(pszDest, nDestMax);
                }
                pszDest[iDst++] = [pszSrc characterAtIndex: iSrc++];
                pszDest[iDst] = '\0';
            }
        }
    }
    return [NSString stringWithCString: pszDest encoding: NSUTF8StringEncoding];
}

-(NSString *) GetDefaultValue: (int *) pnSize {
    // Loop once collecting the sum of the subfield lengths
    int iSubfield;
    int nTotalSize = 0;
    
    for(iSubfield = 0; iSubfield < [subfieldDefinitions count]; iSubfield++) {
        int nSubfieldSize;
        if(![subfieldDefinitions[iSubfield] GetDefaultValue: NULL
                                      nBytesAvailable: 0
                                          pnBytesUsed: &nSubfieldSize]) {
            return NULL;
        }
        nTotalSize += nSubfieldSize;
    }
    // Allocate buffer.
    char *pachData = (char *) malloc(nTotalSize);
    if(pnSize != NULL) {
        *pnSize = nTotalSize;
    }
    // Loop again, collecting actual default values.
    int nOffset = 0;
    for(iSubfield = 0; iSubfield < [subfieldDefinitions count]; iSubfield++) {
        int nSubfieldSize;
        if(![subfieldDefinitions[iSubfield] GetDefaultValue: [NSString stringWithCString: pachData + nOffset encoding: NSUTF8StringEncoding]
                                      nBytesAvailable: nTotalSize - nOffset
                                          pnBytesUsed: &nSubfieldSize]) {
//            assert(FALSE);
            return NULL;
        }
        nOffset += nSubfieldSize;
    }
//    assert(nOffset == nTotalSize);
    return [NSString stringWithCString: pachData encoding: NSUTF8StringEncoding];
}

-(NSString *) GetName {
    return _tag;
}

-(NSString *) GetDescription {
    return _fieldName;
}

-(int) GetSubfieldCount {
    return (int)[subfieldDefinitions count];
}

-(int) GetFixedWidth {
    return nFixedWidth;
}

-(int) IsRepeating {
    return bRepeatingSubfields;
}

-(void) SetRepeatingFlag: (int) n {
    bRepeatingSubfields = n;
}

-(int) BuildSubfields {
    NSArray *subfieldNames;
    NSMutableString *pszSublist = [NSMutableString stringWithUTF8String: _arrayDescr];
    
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
    NSRange range = [pszSublist rangeOfString: @"*" options: NSBackwardsSearch];
    if (range.location != NSNotFound) {
        pszSublist = [NSMutableString stringWithString: [pszSublist substringFromIndex: NSMaxRange(range)]];
    }
    
    // Strip off the repeating marker, when it occurs, but mark our field as repeating.
    assert([pszSublist length] > 1);
    if([pszSublist characterAtIndex: 0] == '*') {
        bRepeatingSubfields = TRUE;
        pszSublist = [NSMutableString stringWithString: [pszSublist substringFromIndex: 1]];
    }
    
    // split list of fields.
    subfieldNames = [pszSublist componentsSeparatedByString: @"!"];
    
    // minimally initialize the subfields.  More will be done later.
    int nSFCount = (int)subfieldNames.count;
    for(int iSF = 0; iSF < nSFCount; iSF++) {
        DDFSubfieldDefinition *poSFDefn = [[DDFSubfieldDefinition alloc] init];
        //[poSFDefn SetName: [papszSubfieldNames[iSF] UTF8String]];
        poSFDefn.name = subfieldNames[iSF];
        [self AddSubfield: poSFDefn bDontAddToFormat: TRUE];
    }
    subfieldNames = nil;
    return TRUE;
}

-(char *) ExtractSubstring: (const char *) pszSrc {
    int nBracket=0, i;
    char *pszReturn;
    
    for(i = 0; pszSrc[i] != '\0' && (nBracket > 0 || pszSrc[i] != ','); i++) {
        if(pszSrc[i] == '(') {
            nBracket++;
        } else if(pszSrc[i] == ')') {
            nBracket--;
        }
    }
    
    if(pszSrc[0] == '(') {
        pszReturn = strdup(pszSrc + 1);
        pszReturn[i-2] = '\0';
    } else {
        pszReturn = strdup(pszSrc);
        pszReturn[i] = '\0';
    }
    return pszReturn;
}

-(int) ApplyFormats {
    NSString *pszFormatList;
    NSArray *papszFormatItems;
    
    // Verify that the format string is contained within brackets.
    if(strlen(_formatControls) < 2
       || _formatControls[0] != '('
       || _formatControls[strlen(_formatControls)-1] != ')') {
        NSLog(@"Format controls for '%@' field missing brackets:%s", _tag, _formatControls);
        return FALSE;
    }
    
    // Duplicate the string, and strip off the brackets.
    pszFormatList = [self ExpandFormat: [NSString stringWithUTF8String: _formatControls]];
    
    // Tokenize based on commas.
    papszFormatItems = [pszFormatList componentsSeparatedByString: @","];
    pszFormatList = nil;
    
    // Apply the format items to subfields.
    int iFormatItem;
//    for(iFormatItem = 0; papszFormatItems[iFormatItem] != NULL; iFormatItem++ ) {
    for(iFormatItem = 0; iFormatItem < papszFormatItems.count; iFormatItem++ ) {
        const char *pszPastPrefix;
        pszPastPrefix = [papszFormatItems[iFormatItem] UTF8String];
        while(*pszPastPrefix >= '0' && *pszPastPrefix <= '9') {
            pszPastPrefix++;
        }
        
        // Did we get too many formats for the subfields created by names?
        // This may be legal by the 8211 specification, but isn't encountered
        // in any formats we care about so we just blow.
        if(iFormatItem >= [subfieldDefinitions count]) {
            NSLog(@"Got more formats than subfields for field '%@'.", _tag);
            break;
        }
        
        if(![subfieldDefinitions[iFormatItem] SetFormat: [NSString stringWithCString: pszPastPrefix encoding: NSUTF8StringEncoding]]) {
            return FALSE;
        }
    }
    
    // Verify that we got enough formats, cleanup and return.
    papszFormatItems = nil;
    
    if(iFormatItem < [subfieldDefinitions count]) {
        NSLog(@"Got less formats than subfields for field '%@'.", _tag);
        return FALSE;
    }
    
    // If all the fields are fixed width, then we are fixed width too.
    // This is important for repeating fields.
    nFixedWidth = 0;
    for(int i = 0; i < [subfieldDefinitions count]; i++) {
        if([subfieldDefinitions[i] GetWidth] == 0) {
            nFixedWidth = 0;
            break;
        } else {
            nFixedWidth += [subfieldDefinitions[i] GetWidth];
        }
    }
    return TRUE;
}

@end
