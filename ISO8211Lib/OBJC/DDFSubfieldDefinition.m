//
//  DDFSubfieldDefinition.m
//  ISO8211Lib
//
//  Created by Christopher Alford on 9/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFSubfieldDefinition.h"

@implementation DDFSubfieldDefinition

@synthesize bIsVariable;
@synthesize nFormatWidth;

//char *_name;   
NSString *pszFormatString = @"";

DDFDataType eType = DDFString;
DDFBinaryFormat eBinaryFormat = DDFBinaryFormatNotBinary;

char chFormatDelimeter;

// Fetched string cache. This is where we hold the values returned from ExtractStringData().
int nMaxBufChars  = 0;
char *pachBuffer;

-(instancetype) init {
    self = [super init];
    if (self) {
        _name = NULL;
        bIsVariable = TRUE;
        nFormatWidth = 0;
        chFormatDelimeter = DDF_UNIT_TERMINATOR;
        eBinaryFormat = DDFBinaryFormatNotBinary;
        eType = DDFString;
        pszFormatString = @"";
        nMaxBufChars = 0;
        pachBuffer = NULL;
    }
    return self;
}

-(void) dealloc {
    _name = NULL;
    pszFormatString = NULL;
    pachBuffer = NULL;
}

-(void) setName: (NSString *) newName {
    _name = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString *) getFormat {
    return pszFormatString;
}

-(int) setFormat: (NSString *) pszFormat {
    pszFormatString = NULL;
    pszFormatString = [pszFormat copy];
    
    // These values will likely be used.
    if ([pszFormatString length] == 1 && [pszFormatString characterAtIndex: 0] != '(') {
        bIsVariable = TRUE;
    } else if ([pszFormatString length] > 1) {
        if([pszFormatString characterAtIndex: 1] == '(') {
            nFormatWidth = atoi([[pszFormatString substringFromIndex: 2] cStringUsingEncoding: NSUTF8StringEncoding]);
            bIsVariable = (nFormatWidth == 0);
        } else {
            bIsVariable = TRUE;
        }
    }
    // Interpret the format string.
    switch([pszFormatString characterAtIndex: 0]) {
        case 'A':
        case 'C':         // It isn't clear to me how this is different than 'A'
            eType = DDFString;
            break;
            
        case 'R':
            eType = DDFFloat;
            break;
            
        case 'I':
        case 'S':
            eType = DDFInt;
            break;
            
        case 'B':
        case 'b':
            // Is the width expressed in bits? (is it a bitstring)
            bIsVariable = FALSE;
            if([pszFormatString characterAtIndex: 1] == '(') {
//                assert( atoi(pszFormatString+2) % 8 == 0 );
                
                nFormatWidth = atoi([[pszFormatString substringFromIndex: 2] cStringUsingEncoding: NSUTF8StringEncoding]) / 8;
                eBinaryFormat = DDFBinaryFormatSInt; // good default, works for SDTS.
                
                if(nFormatWidth < 5) {
                    eType = DDFInt;
                } else {
                    eType = DDFBinaryString;
                }
            } else { // or do we have a binary type indicator? (is it binary)
                eBinaryFormat = (DDFBinaryFormat) ([pszFormatString characterAtIndex: 1] - '0');
                nFormatWidth = atoi([[pszFormatString substringFromIndex: 2] cStringUsingEncoding: NSUTF8StringEncoding]);
                
                if(eBinaryFormat == DDFBinaryFormatSInt || eBinaryFormat == DDFBinaryFormatUInt) {
                    eType = DDFInt;
                } else {
                    eType = DDFFloat;
                }
            }
            break;
            
        case 'X':
            // 'X' is extra space, and shouldn't be directly assigned to a
            // subfield ... I haven't encountered it in use yet though.
            NSLog(@"Format type of '%c' not supported.\n", [pszFormatString characterAtIndex: 0]);
//            assert(FALSE);
            return FALSE;
            
        default:
            NSLog(@"Format type of '%c' not recognised.\n", [pszFormatString characterAtIndex: 0]);
//            assert( FALSE );
            return FALSE;
    }
    return TRUE;
}

-(DDFDataType) getType {
    return eType;
}

-(int) getWidth {
    return nFormatWidth;
}

-(DDFBinaryFormat) getBinaryFormat {
    return eBinaryFormat;
}

-(void) dump: (FILE *) fp {
    fprintf( fp, "    DDFSubfieldDefn:\n" );
    fprintf( fp, "        Label = '%s'\n", [_name UTF8String]);
    fprintf( fp, "        FormatString = '%s'\n", [pszFormatString cStringUsingEncoding: NSUTF8StringEncoding]);
}

-(void) log {
    NSLog(@"    DDFSubfieldDefn:\n" );
    NSLog(@"        Label = '%@'\n", _name );
    NSLog(@"        FormatString = '%s'\n", [pszFormatString cStringUsingEncoding: NSUTF8StringEncoding]);
}

-(void) dumpData: (NSString *) pachData
       nMaxBytes: (int) nMaxBytes
              fp: (FILE *) fp {
    if(eType == DDFFloat) {
        fprintf(fp, "      Subfield '%s' = %f\n",
                [_name UTF8String],
                [self extractFloatData: pachData nMaxBytes: nMaxBytes pnConsumedBytes: NULL]);
    } else if( eType == DDFInt ) {
        fprintf(fp, "      Subfield '%s' = %d\n",
                [_name UTF8String],
                [self extractIntData: pachData nMaxBytes: nMaxBytes pnConsumedBytes: NULL]);
    } else if(eType == DDFBinaryString) {
        int nBytes, i;
        GByte *pabyBString = (GByte *) [[self extractStringData: pachData nMaxBytes: nMaxBytes pnConsumedBytes: &nBytes] cStringUsingEncoding: NSUTF8StringEncoding];
        
        fprintf(fp, "      Subfield '%s' = 0x", [_name UTF8String]);
        for(i = 0; i < MIN(nBytes,24); i++) {
            fprintf(fp, "%02X", pabyBString[i]);
        }
        if(nBytes > 24) {
            fprintf(fp, "%s", "..." );
        }
        fprintf(fp, "\n");
    } else {
        fprintf(fp, "      Subfield '%s' = '%s'\n",
                [_name UTF8String],
                [[self extractStringData: pachData nMaxBytes: nMaxBytes pnConsumedBytes: NULL] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
}

-(double) extractFloatData: (NSString *) pachSourceData
                 nMaxBytes: (int) nMaxBytes
           pnConsumedBytes: (int *) pnConsumedBytes {
    switch([pszFormatString characterAtIndex: 0]) {
        case 'A':
        case 'I':
        case 'R':
        case 'S':
        case 'C':
            return atof([[self extractStringData: pachSourceData
                                      nMaxBytes: nMaxBytes
                                pnConsumedBytes: pnConsumedBytes] cStringUsingEncoding: NSUTF8StringEncoding]);
            
        case 'B':
        case 'b':
        {
            unsigned char abyData[8];
            
//            assert(nFormatWidth <= nMaxBytes);
            if(pnConsumedBytes != NULL) {
                *pnConsumedBytes = nFormatWidth;
            }
            // Byte swap the data if it isn't in machine native format.
            // In any event we copy it into our buffer to ensure it is
            // word aligned.
#ifdef CPL_LSB
            if([pszFormatString characterAtIndex: 0] == 'B')
#else
                if([pszFormatString characterAtIndex: 0] == 'b')
#endif
                {
                    for(int i = 0; i < nFormatWidth; i++) {
                        assert([pachSourceData length] > 1);
                        abyData[nFormatWidth-i-1] = [pachSourceData characterAtIndex: i];
                    }
                } else {
                    memcpy(abyData, [pachSourceData cStringUsingEncoding: NSUTF8StringEncoding], nFormatWidth);
                }
            
            // Interpret the bytes of data.
            switch( eBinaryFormat ) {
                case DDFBinaryFormatUInt:
                    if( nFormatWidth == 1 ) {
                        return( abyData[0] );
                    } else if( nFormatWidth == 2 ) {
                        return( *((GUInt16 *) abyData) );
                    } else if( nFormatWidth == 4 ) {
                        return( *((GUInt32 *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0.0;
                    }
                    
                case DDFBinaryFormatSInt:
                    if( nFormatWidth == 1 ) {
                        return( *((signed char *) abyData) );
                    } else if( nFormatWidth == 2 ) {
                        return( *((GInt16 *) abyData) );
                    } else if( nFormatWidth == 4 ) {
                        return( *((GInt32 *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0.0;
                    }
                    
                case DDFBinaryFormatFloatReal:
                    if(nFormatWidth == 4) {
                        return( *((float *) abyData) );
                    } else if( nFormatWidth == 8 ) {
                        return( *((double *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0.0;
                    }
                    
                case DDFBinaryFormatNotBinary:
                case DDFBinaryFormatFPReal:
                case DDFBinaryFormatFloatComplex:
//                    assert(FALSE);
                    return 0.0;
            }
            break;
            // end of 'b'/'B' case.
        }
            
        default:
//            assert(FALSE);
            return 0.0;
    }
    
//    assert(FALSE);
    return 0.0;
    
}

-(int) extractIntData: (NSString *) pachSourceData
            nMaxBytes: (int) nMaxBytes
      pnConsumedBytes: (int *) pnConsumedBytes {
    switch([pszFormatString characterAtIndex: 0]) {
        case 'A':
        case 'I':
        case 'R':
        case 'S':
        case 'C':
            return atoi([[self extractStringData: pachSourceData nMaxBytes: nMaxBytes pnConsumedBytes: pnConsumedBytes] cStringUsingEncoding: NSUTF8StringEncoding]);
            
        case 'B':
        case 'b':
        {
            unsigned char abyData[8];
            
            if(nFormatWidth > nMaxBytes) {
                NSLog(@"Attempt to extract int subfield %@ with format %@\nfailed as only %d bytes available.  Using zero.", _name, pszFormatString, nMaxBytes);
                return 0;
            }
            
            if(pnConsumedBytes != NULL) {
                *pnConsumedBytes = nFormatWidth;
            }
            
            // Byte swap the data if it isn't in machine native format.
            // In any event we copy it into our buffer to ensure it is
            // word aligned.
#ifdef CPL_LSB
            if(pszFormatString[0] == 'B')
#else
                if([pszFormatString characterAtIndex: 0] == 'b')
#endif
                {
                    for(int i = 0; i < nFormatWidth; i++) {
                        abyData[nFormatWidth-i-1] = [pachSourceData characterAtIndex: i];
                    }
                } else {
                    memcpy(abyData, [pachSourceData cStringUsingEncoding: NSUTF8StringEncoding], nFormatWidth);
                }
            
            // Interpret the bytes of data.
            switch(eBinaryFormat) {
                case DDFBinaryFormatUInt:
                    if(nFormatWidth == 4) {
                        return( (int) *((GUInt32 *) abyData) );
                    } else if(nFormatWidth == 1) {
                        return( abyData[0] );
                    } else if(nFormatWidth == 2) {
                        return( *((GUInt16 *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0;
                    }
                    
                case DDFBinaryFormatSInt:
                    if(nFormatWidth == 4) {
                        return( *((GInt32 *) abyData) );
                    } else if(nFormatWidth == 1) {
                        return( *((signed char *) abyData) );
                    } else if(nFormatWidth == 2) {
                        return( *((GInt16 *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0;
                    }
                    
                case DDFBinaryFormatFloatReal:
                    if(nFormatWidth == 4) {
                        return( (int) *((float *) abyData) );
                    } else if(nFormatWidth == 8) {
                        return( (int) *((double *) abyData) );
                    } else {
//                        assert(FALSE);
                        return 0;
                    }
                    
                case DDFBinaryFormatNotBinary:
                case DDFBinaryFormatFPReal:
                case DDFBinaryFormatFloatComplex:
//                    assert(FALSE);
                    return 0;
            }
            break;
            // end of 'b'/'B' case.
        }
            
        default:
//            assert(FALSE);
            return 0;
    }
    
//    assert(FALSE);
    return 0;
}

-(NSString  *) extractStringData: (NSString *) pachSourceData
                         nMaxBytes: (int) nMaxBytes
                   pnConsumedBytes: (int *) pnConsumedBytes {
    if (pachSourceData == NULL) {
        return NULL;
    }
    int nLength = [self getDataLength: pachSourceData nMaxBytes: nMaxBytes pnConsumedBytes: pnConsumedBytes];
    
    // Do we need to grow the buffer?
    if(nMaxBufChars < nLength+1) {
        free(pachBuffer);
        nMaxBufChars = nLength+1;
        pachBuffer = (char *) malloc(nMaxBufChars);
    }
    
    // Copy the data to the buffer.  We use memcpy() so that it will work for binary data.
    memcpy(pachBuffer, [pachSourceData cStringUsingEncoding: NSUTF8StringEncoding], nLength);
    pachBuffer[nLength] = '\0';
    return [NSString stringWithCString: pachBuffer encoding: NSUTF8StringEncoding];
}

-(int) formatStringValue: (NSMutableString *) pachData
         nBytesAvailable: (int) nBytesAvailable
             pnBytesUsed: (int *) pnBytesUsed
                pszValue: (const char *) pszValue
            nValueLength: (int) nValueLength { // TODO: Default value = -1
    int nSize;
    
    if(nValueLength == -1) {
        nValueLength = (int) strlen(pszValue);
    }
    
    if(bIsVariable) {
        nSize = nValueLength + 1;
    } else {
        nSize = nFormatWidth;
    }
    
    if(pnBytesUsed != NULL) {
        *pnBytesUsed = nSize;
    }
    
    if(pachData == NULL) {
        return TRUE;
    }
    
    if(nBytesAvailable < nSize) {
        return FALSE;
    }
    
    if(bIsVariable) {
        strncpy([pachData cStringUsingEncoding: NSUTF8StringEncoding], pszValue, nSize-1 );
        //[pachData characterAtIndex: nSize-1] = DDF_UNIT_TERMINATOR;
        [pachData insertString: [NSString stringWithFormat: @"%c", DDF_UNIT_TERMINATOR] atIndex: nSize-1];
    } else {
        if([self getBinaryFormat] == DDFBinaryFormatNotBinary) {
            memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], ' ', nSize);
            memcpy([pachData cStringUsingEncoding: NSUTF8StringEncoding], pszValue, MIN(nValueLength,nSize));
        } else {
            memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], 0, nSize );
            memcpy([pachData cStringUsingEncoding: NSUTF8StringEncoding], pszValue, MIN(nValueLength,nSize));
        }
    }
    return TRUE;
}

-(int) formatIntValue: (NSMutableString *) pachData
      nBytesAvailable: (int) nBytesAvailable
          pnBytesUsed: (int *) pnBytesUsed
            nNewValue: (int) nNewValue {
    int nSize;
    char szWork[30];
    
    sprintf( szWork, "%d", nNewValue );
    
    if(bIsVariable) {
        nSize = (int) strlen(szWork) + 1;
    } else {
        nSize = nFormatWidth;
        if([self getBinaryFormat] == DDFBinaryFormatNotBinary && (int) strlen(szWork) > nSize) {
            return FALSE;
        }
    }
    
    if(pnBytesUsed != NULL) {
        *pnBytesUsed = nSize;
    }
    
    if(pachData == NULL) {
        return TRUE;
    }
    
    if(nBytesAvailable < nSize) {
        return FALSE;
    }
    
    if(bIsVariable) {
        strncpy([pachData UTF8String], szWork, nSize-1 );
        [pachData insertString: [NSString stringWithFormat: @"%c", DDF_UNIT_TERMINATOR] atIndex: nSize-1];
        //pachData[nSize-1] = DDF_UNIT_TERMINATOR;
    } else {
        GUInt32 nMask = 0xff;
        int i;
        
        switch([self getBinaryFormat]) {
            case DDFBinaryFormatNotBinary:
                memset([pachData UTF8String], '0', nSize );
                strncpy([[pachData substringFromIndex: nSize - strlen(szWork)] UTF8String], szWork,
                        strlen(szWork) );
                break;
                
            case DDFBinaryFormatUInt:
            case DDFBinaryFormatSInt:
                for(i = 0; i < nFormatWidth; i++) {
                    int iOut;
                    
                    // big endian required?
                    if([pszFormatString characterAtIndex: 0] == 'B') {
                        iOut = nFormatWidth - i - 1;
                    } else {
                        iOut = i;
                    }
                    [pachData insertString: [NSString stringWithFormat: @"%c", (nNewValue & nMask) >> (i*8)] atIndex: iOut];
                    //pachData[iOut] = (nNewValue & nMask) >> (i*8);
                    nMask *= 256;
                }
                break;
                
            case DDFBinaryFormatFloatReal:
//                assert(FALSE);
                break;
                
            default:
//                assert(FALSE);
                break;
        }
    }
    return TRUE;
}

-(int) formatFloatValue: (NSMutableString *) pachData
        nBytesAvailable: (int) nBytesAvailable
            pnBytesUsed: (int *)pnBytesUsed
             dfNewValue: (double) dfNewValue {
    int nSize;
    char szWork[120];
    
    sprintf(szWork, "%.16g", dfNewValue);
    
    if(bIsVariable) {
        nSize = (int)strlen(szWork) + 1;
    } else {
        nSize = nFormatWidth;
        if([self getBinaryFormat] == DDFBinaryFormatNotBinary && (int) strlen(szWork) > nSize) {
            return FALSE;
        }
    }
    
    if(pnBytesUsed != NULL) {
        *pnBytesUsed = nSize;
    }
    
    if(pachData == NULL) {
        return TRUE;
    }
    
    if(nBytesAvailable < nSize) {
        return FALSE;
    }
    
    if(bIsVariable) {
        strncpy([pachData cStringUsingEncoding: NSUTF8StringEncoding], szWork, nSize-1 );
        [pachData insertString: [NSString stringWithFormat: @"%c", DDF_UNIT_TERMINATOR] atIndex: nSize-1];
        //[pachData characterAtIndex: nSize-1] = DDF_UNIT_TERMINATOR;
    } else {
        if([self getBinaryFormat] == DDFBinaryFormatNotBinary) {
            memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], '0', nSize);
            strncpy([[pachData substringFromIndex: nSize - strlen(szWork)] cStringUsingEncoding: NSUTF8StringEncoding], szWork, strlen(szWork));
        } else {
//            assert(FALSE);
            /* implement me */
        }
    }
    return TRUE;
}

- (int) getDataLength: (NSString *) pachSourceData
            nMaxBytes: (int) nMaxBytes
      pnConsumedBytes: (int *) pnConsumedBytes {
    if(!bIsVariable) {
        if(nFormatWidth > nMaxBytes) {
            NSLog(@"Only %d bytes available for subfield %@ with\nformat string %@ ... returning shortened data.",
                  nMaxBytes, _name, pszFormatString);
            
            if(pnConsumedBytes != NULL) {
                *pnConsumedBytes = nMaxBytes;
            }
            return nMaxBytes;
        } else {
            if(pnConsumedBytes != NULL) {
                *pnConsumedBytes = nFormatWidth;
            }
            return nFormatWidth;
        }
    } else {
        int nLength = 0;
        int bCheckFieldTerminator = TRUE;
        
        /* We only check for the field terminator because of some buggy
         * datasets with missing format terminators.  However, we have found
         * the field terminator is a legal character within the fields of
         * some extended datasets (such as JP34NC94.000).  So we don't check
         * for the field terminator if the field appears to be multi-byte
         * which we established by the first character being out of the
         * ASCII printable range (32-127).
         */
        
        if([pachSourceData characterAtIndex: 0] < 32 || [pachSourceData  characterAtIndex: 0] >= 127) {
            bCheckFieldTerminator = FALSE;
        }
        
        while(nLength < nMaxBytes && [pachSourceData characterAtIndex: nLength] != chFormatDelimeter) {
            if(bCheckFieldTerminator && [pachSourceData characterAtIndex: nLength] == DDF_FIELD_TERMINATOR) {
                break;
            }
            nLength++;
        }
        
        if(pnConsumedBytes != NULL) {
            if(nMaxBytes == 0) {
                *pnConsumedBytes = nLength;
            } else {
                *pnConsumedBytes = nLength+1;
            }
        }
        return nLength;
    }
}

-(int) getDefaultValue: (NSMutableString *)pachData
       nBytesAvailable: (int) nBytesAvailable
           pnBytesUsed: (int *) pnBytesUsed {
    int nDefaultSize;

    if(!bIsVariable) {
        nDefaultSize = nFormatWidth;
    } else {
        nDefaultSize = 1;
    }

    if(pnBytesUsed != NULL) {
        *pnBytesUsed = nDefaultSize;
    }

    if(pachData == NULL) {
        return TRUE;
    }

    if(nBytesAvailable < nDefaultSize) {
        return FALSE;
    }

    if(bIsVariable) {
        [pachData insertString: [NSString stringWithFormat: @"%c", DDF_UNIT_TERMINATOR] atIndex:0];
        //pachData[0] = DDF_UNIT_TERMINATOR;
    } else {
        if([self getBinaryFormat] == DDFBinaryFormatNotBinary) {
            if([self getType] == DDFInt || [self getType] == DDFFloat) {
                memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], '0', nDefaultSize );
            } else {
                memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], ' ', nDefaultSize );
            }
        } else {
            memset([pachData cStringUsingEncoding: NSUTF8StringEncoding], 0, nDefaultSize );
        }
    }
    return TRUE;
}

@end
