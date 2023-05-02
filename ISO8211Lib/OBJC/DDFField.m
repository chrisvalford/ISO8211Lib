//
//  DDFField.m
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFField.h"

@implementation DDFField

//private:
DDFFieldDefinition *poDefn;
long nDataSize;
NSString *pachData;

-(void) Initialize: (DDFFieldDefinition *) poDefnIn
           pszData: (NSString *) pachDataIn
             nSize: (long) nDataSizeIn {
    pachData = pachDataIn;
    nDataSize = nDataSizeIn;
    poDefn = poDefnIn;
}

- (void) Initialize: (DDFField *) poField
            pszData: (NSString *) pachDataIn {
    DDFFieldDefinition * poDefn = [poField GetFieldDefn];
    long dataSize = [poField GetDataSize];
    [self Initialize: poDefn
             pszData: pachDataIn
               nSize: dataSize];
}

-(NSString *) GetData {
    return pachData;
}

-(long) GetDataSize {
    return nDataSize;
}

-(int) GetRepeatCount {
    if(![poDefn IsRepeating]) {
        return 1;
    }

// The occurance count depends on how many copies of this
// field's list of subfields can fit into the data space.
    if([poDefn GetFixedWidth]) {
        return (int)nDataSize / [poDefn GetFixedWidth];
    }

// Note that it may be legal to have repeating variable width
// subfields, but I don't have any samples, so I ignore it for now.
// The file data/cape_royal_AZ_DEM/1183XREF.DDF has a repeating
// variable length field, but the count is one, so it isn't
// much value for testing.

    int iOffset = 0, iRepeatCount = 1;
    
    while(TRUE) {
        for(int iSF = 0; iSF < [poDefn GetSubfieldCount]; iSF++) {
            int nBytesConsumed;
            DDFSubfieldDefinition * poThisSFDefn = [poDefn GetSubfield: iSF];

            if([poThisSFDefn GetWidth] > nDataSize - iOffset) {
                nBytesConsumed = [poThisSFDefn GetWidth];
            } else {
                [poThisSFDefn GetDataLength: [pachData substringFromIndex: iOffset]
                                  nMaxBytes: (int)nDataSize - iOffset
                            pnConsumedBytes: &nBytesConsumed];
            }

            iOffset += nBytesConsumed;
            if(iOffset > nDataSize) {
                return iRepeatCount - 1;
            }
        }

        if(iOffset > nDataSize - 2) {
            return iRepeatCount;
        }
        iRepeatCount++;
    }
}

-(DDFFieldDefinition *) GetFieldDefn {
    return poDefn;
}

-(NSString *) GetInstanceData: (int) nInstance
                         pnSize: (int *) pnInstanceSize {
    int nRepeatCount = [self GetRepeatCount];
    NSString *pachWrkData;

    if(nInstance < 0 || nInstance >= nRepeatCount) {
        return NULL;
    }

// Special case for fields without subfields (like "0001").
// We don't currently handle repeating simple fields.
    if([poDefn GetSubfieldCount] == 0) {
        pachWrkData = [self GetData];
        if(pnInstanceSize != 0) {
            *pnInstanceSize = (int)[self GetDataSize];
        }
        return pachWrkData;
    }

// Get a pointer to the start of the existing data for this
// iteration of the field.
    int nBytesRemaining1, nBytesRemaining2;
    DDFSubfieldDefinition *poFirstSubfield;
    poFirstSubfield = [poDefn GetSubfield: 0];
    pachWrkData = [self GetSubfieldData: poFirstSubfield
                             pnMaxBytes: &nBytesRemaining1
                         iSubfieldIndex: nInstance];

// Figure out the size of the entire field instance, including
// unit terminators, but not any trailing field terminator.
    if(pnInstanceSize != NULL) {
        DDFSubfieldDefinition *poLastSubfield;
        int nLastSubfieldWidth;
        NSString *pachLastData;
        poLastSubfield = [poDefn GetSubfield: [poDefn GetSubfieldCount]-1];
        pachLastData = [self GetSubfieldData: poLastSubfield
                                  pnMaxBytes: &nBytesRemaining2
                              iSubfieldIndex: nInstance];
        [poLastSubfield GetDataLength: pachLastData
                            nMaxBytes: nBytesRemaining2
                      pnConsumedBytes: &nLastSubfieldWidth];
        *pnInstanceSize = nBytesRemaining1 - (nBytesRemaining2 - nLastSubfieldWidth);
    }
    return pachWrkData;
}

-(NSString *) GetSubfieldData: (DDFSubfieldDefinition *) poSFDefn
                     pnMaxBytes: (int *) pnMaxBytes// = NULL,
                 iSubfieldIndex: (int) iSubfieldIndex { // = 0;
    int iOffset = 0;
    
    if(poSFDefn == NULL) {
        return NULL;
    }

    if(iSubfieldIndex > 0 && [poDefn GetFixedWidth] > 0) {
        iOffset = [poDefn GetFixedWidth] * iSubfieldIndex;
        iSubfieldIndex = 0;
    }

    while(iSubfieldIndex >= 0) {
        for(int iSF = 0; iSF < [poDefn GetSubfieldCount]; iSF++) {
            int nBytesConsumed;
            DDFSubfieldDefinition *poThisSFDefn = [poDefn GetSubfield: iSF];
            if(poThisSFDefn == poSFDefn && iSubfieldIndex == 0) {
                if(pnMaxBytes != NULL) {
                    *pnMaxBytes = (int)nDataSize - iOffset;
                }
                return [pachData substringFromIndex: iOffset];
                //return [NSString stringWithCString: pachData + iOffset encoding: NSUTF8StringEncoding];
            }
            [poThisSFDefn GetDataLength: [pachData substringFromIndex: iOffset]
                              nMaxBytes: (int)nDataSize - iOffset
                        pnConsumedBytes: &nBytesConsumed];
            iOffset += nBytesConsumed;
        }
        iSubfieldIndex--;
    }
    // We didn't find our target subfield or instance!
    return NULL;
}

-(void) Dump: (FILE *) fp {
    int nMaxRepeat = 8;

    if(getenv("DDF_MAXDUMP") != NULL) {
        nMaxRepeat = atoi(getenv("DDF_MAXDUMP"));
    }

    fprintf(fp, "  DDFField:\n");
    fprintf(fp, "      Tag = '%s'\n", [[poDefn GetName] UTF8String]);
    fprintf(fp, "      DataSize = %ld\n", nDataSize);

    fprintf(fp, "      Data = '");
    for(int i = 0; i < MIN(nDataSize,40); i++) {
        assert([pachData length] > 1);
        if([pachData characterAtIndex: i] < 32 || [pachData characterAtIndex: i] > 126) {
            fprintf(fp, "\\%02X", [pachData characterAtIndex: i]);
        } else {
            fprintf(fp, "%c", [pachData characterAtIndex: i]);
        }
    }

    if(nDataSize > 40) {
        fprintf(fp, "...");
    }
    fprintf(fp, "'\n");

// dump the data of the subfields.
    long iOffset = 0;
    int nLoopCount;

    for(nLoopCount = 0; nLoopCount < [self GetRepeatCount]; nLoopCount++) {
        if(nLoopCount > nMaxRepeat) {
            fprintf(fp, "      ...\n");
            break;
        }
        
        for(int i = 0; i < [poDefn GetSubfieldCount]; i++) {
            int nBytesConsumed;

            [[poDefn GetSubfield: i] DumpData: [pachData substringFromIndex: iOffset]
                                    nMaxBytes: (int)nDataSize - (int) iOffset
                                           fp: fp];
        
            [[poDefn GetSubfield: i] GetDataLength: [pachData substringFromIndex: iOffset]
                                         nMaxBytes: (int) nDataSize - (int) iOffset
                                   pnConsumedBytes: &nBytesConsumed];

            iOffset += nBytesConsumed;
        }
    }
}

@end
