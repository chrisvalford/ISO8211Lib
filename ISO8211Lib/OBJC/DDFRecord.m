//
// DDFRecord.m
// Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFUtils.h"
#import "ISO8211.h"

@implementation DDFRecord {
    
    // private:
    DDFModule *poModule;
    int nReuseHeader;
    int nFieldOffset;   // field data area, not dir entries.
    int _sizeFieldTag;
    int _sizeFieldPos;
    int _sizeFieldLength;
    int nDataSize;      // Whole record except leader with header
    char *pachData;
    int nFieldCount;
    NSMutableArray *paoFields; // [DDFField]
    int bIsClone;
}

@synthesize paoFields;

-(instancetype) init: (DDFModule *) moduleIn {
    self = [super init];
    if (self) {
        paoFields = [[NSMutableArray alloc] initWithCapacity:20];
        poModule = moduleIn;
        nReuseHeader = FALSE;
        nFieldOffset = 0;
        nDataSize = 0;
        pachData = NULL;
        nFieldCount = 0;
        bIsClone = FALSE;
        _sizeFieldTag = 4;
        _sizeFieldPos = 0;
        _sizeFieldLength = 0;
    }
    return self;
}

-(void) dealloc {
    [self Clear];
    if( bIsClone ) {
        [poModule RemoveCloneRecord: self];
    }
}

-(void) Dump: (FILE *) fp {
    fprintf(fp, "DDFRecord:\n" );
    fprintf(fp, "    nReuseHeader = %d\n", nReuseHeader );
    fprintf(fp, "    nDataSize = %d\n", nDataSize );
    fprintf(fp, "    _sizeFieldLength=%d, _sizeFieldPos=%d, _sizeFieldTag=%d\n",
             _sizeFieldLength, _sizeFieldPos, _sizeFieldTag );

    for(int i = 0; i < nFieldCount; i++) {
        [paoFields[i] Dump: fp];
    }
}

-(int) GetDataSize {
    return nDataSize;
}

-(const char *) GetData {
    return pachData;
}

-(DDFModule *) GetModule {
    return poModule;
}

-(int) ReadHeader {
    // Clear any existing information.
    [self Clear];
    
    // Read the 24 byte leader.
    char achLeader[nLeaderSize];
    long nReadBytes = fread(achLeader,1,nLeaderSize, [poModule GetFP]);
    if(nReadBytes == 0 && feof([poModule GetFP])) {
        return FALSE;
    } else if(nReadBytes != (int) nLeaderSize) {
        NSLog(@"Leader is short on DDF file.");
        return FALSE;
    }
    
    // Extract information from leader.
    long _recLength = [DDFUtils DDFScanInt: achLeader+0 nMaxChars: 5];
    char _leaderIden = achLeader[6];
    long _fieldAreaStart = [DDFUtils DDFScanInt: achLeader+12 nMaxChars: 5];
    
    _sizeFieldLength = achLeader[20] - '0';
    _sizeFieldPos = achLeader[21] - '0';
    _sizeFieldTag = achLeader[23] - '0';
    
    if(_sizeFieldLength < 0 || _sizeFieldLength > 9
       || _sizeFieldPos < 0 || _sizeFieldPos > 9
       || _sizeFieldTag < 0 || _sizeFieldTag > 9) {
        NSLog(@"ISO8211 record leader appears to be corrupt.");
        return FALSE;
    }
    
    if(_leaderIden == 'R') {
        nReuseHeader = TRUE;
    }
    nFieldOffset = _fieldAreaStart - nLeaderSize;
    
    // Is there anything seemly screwy about this record?
    if((_recLength < 24 || _recLength > 100000000
        || _fieldAreaStart < 24 || _fieldAreaStart > 100000)
       && (_recLength != 0)) {
        NSLog(@"Data record appears to be corrupt on DDF file.\n -- ensure that the files were uncompressed without modifying\ncarriage return/linefeeds (by default WINZIP does this).");
        return FALSE;
    }
    
    // Handle the normal case with the record length available.
    if(_recLength != 0) {
        // Read the remainder of the record.
        nDataSize = _recLength - nLeaderSize;
        pachData = (char *) malloc(nDataSize);
        
        if(fread(pachData, 1, nDataSize, [poModule GetFP]) != (size_t) nDataSize) {
            NSLog(@"Data record is short on DDF file.");
            return FALSE;
        }
        
        // If we don't find a field terminator at the end of the record
        // we will read extra bytes till we get to it.
        while(pachData[nDataSize-1] != DDF_FIELD_TERMINATOR) {
            nDataSize++;
            pachData = (char *) realloc(pachData,nDataSize);
            
            if(fread(pachData + nDataSize - 1, 1, 1, [poModule GetFP]) != 1) {
                NSLog(@"Data record is short on DDF file.");
                return FALSE;
            }
            NSLog(@"Didn't find field terminator, read one more byte.");
        }
        
        // Loop over the directory entries, making a pass counting them.
        int i;
        int nFieldEntryWidth = _sizeFieldLength + _sizeFieldPos + _sizeFieldTag;
        nFieldCount = 0;
        for(i = 0; i < nDataSize; i += nFieldEntryWidth) {
            if(pachData[i] == DDF_FIELD_TERMINATOR) {
                break;
            }
            nFieldCount++;
        }
        
        // Allocate, and read field definitions.
        for(i = 0; i < nFieldCount; i++) {
            char szTag[128];
            int nEntryOffset = i*nFieldEntryWidth;
            long nFieldLength, nFieldPos;
            
            // Read the position information and tag.
            strncpy(szTag, pachData+nEntryOffset, _sizeFieldTag);
            szTag[_sizeFieldTag] = '\0';
            nEntryOffset += _sizeFieldTag;
            nFieldLength = [DDFUtils DDFScanInt: pachData+nEntryOffset nMaxChars: _sizeFieldLength];
            nEntryOffset += _sizeFieldLength;
            nFieldPos = [DDFUtils DDFScanInt: pachData+nEntryOffset nMaxChars: _sizeFieldPos];
            
            // Find the corresponding field in the module directory.
            DDFFieldDefinition *poFieldDefn = [poModule FindFieldDefn: @(szTag)];
            
            if(poFieldDefn == NULL) {
                NSLog(@"Undefined field '%s' encountered in data record.", szTag);
                return FALSE;
            }
            
            // Create DDFField and assign the info.
            DDFField *newDDFField = [[DDFField alloc] init];
            [newDDFField Initialize: poFieldDefn
                            pszData: [NSString stringWithCString: pachData + _fieldAreaStart + nFieldPos - nLeaderSize  encoding: NSUTF8StringEncoding]
                              nSize: nFieldLength];
            [paoFields addObject: newDDFField];
        }
        return TRUE;
    }
    
    // Handle the exceptional case where the record length is zero.
    // In this case we have to read all the data based on
    // the size of data items as per ISO8211 spec Annex C, 1.5.1.
    //
    // See Bugzilla bug 181 and test with file US4CN21M.000.
    else {
        NSLog(@"Record with zero length, use variant (C.1.5.1) logic.");
        
        // _recLength == 0, handle the large record.
        // Read the remainder of the record.
        nDataSize = 0;
        pachData = NULL;
        
        // Loop over the directory entries, making a pass counting them.
        int nFieldEntryWidth = _sizeFieldLength + _sizeFieldPos + _sizeFieldTag;
        nFieldCount = 0;
        int i=0;
        char *tmpBuf = (char *)malloc(nFieldEntryWidth);
        
        if(tmpBuf == NULL)
        {
            NSLog(@"Attempt to allocate %d byte ISO8211 record buffer failed.", nFieldEntryWidth);
            return FALSE;
        }
        
        // while we're not at the end, store this entry,
        // and keep on reading...
        do {
            // read an Entry:
            if(nFieldEntryWidth != (int) fread(tmpBuf, 1, nFieldEntryWidth, [poModule GetFP])) {
                NSLog(@"Data record is short on DDF file.");
                return FALSE;
            }
            
            // move this temp buffer into more permanent storage:
            char *newBuf = (char*)malloc(nDataSize+nFieldEntryWidth);
            if(pachData!=NULL) {
                memcpy(newBuf, pachData, nDataSize);
                pachData = nil;
            }
            memcpy(&newBuf[nDataSize], tmpBuf, nFieldEntryWidth);
            pachData = newBuf;
            nDataSize += nFieldEntryWidth;
            
            if(DDF_FIELD_TERMINATOR != tmpBuf[0]) {
                nFieldCount++;
            }
        }
        while(DDF_FIELD_TERMINATOR != tmpBuf[0]);
        
        // Now, rewind a little.  Only the TERMINATOR should have been read:
        int rewindSize = nFieldEntryWidth - 1;
        FILE *fp = [poModule GetFP];
        long pos = ftell(fp) - rewindSize;
        fseek(fp, pos, SEEK_SET);
        nDataSize -= rewindSize;
        
        // Okay, now let's populate the heck out of pachData...
        for(i=0; i<nFieldCount; i++) {
            int nEntryOffset = (i*nFieldEntryWidth) + _sizeFieldTag;
            int nFieldLength = (int) [DDFUtils DDFScanInt: pachData + nEntryOffset
                                          nMaxChars: _sizeFieldLength];
            char *tmpBuf = (char*)malloc(nFieldLength);
            
            // read an Entry:
            if(nFieldLength != (int) fread(tmpBuf, 1, nFieldLength, [poModule GetFP])) {
                NSLog(@"Data record is short on DDF file.");
                return FALSE;
            }
            
            // move this temp buffer into more permanent storage:
            char *newBuf = (char*)malloc(nDataSize+nFieldLength);
            memcpy(newBuf, pachData, nDataSize);
            pachData = nil;
            memcpy(&newBuf[nDataSize], tmpBuf, nFieldLength);
            tmpBuf = nil;
            pachData = newBuf;
            nDataSize += nFieldLength;
        }
        // Allocate, and read field definitions.
        for(i = 0; i < nFieldCount; i++) {
            char szTag[128];
            int nEntryOffset = i*nFieldEntryWidth;
            int nFieldLength, nFieldPos;
            
            // Read the position information and tag.
            strncpy(szTag, pachData+nEntryOffset, _sizeFieldTag);
            szTag[_sizeFieldTag] = '\0';
            
            nEntryOffset += _sizeFieldTag;
            nFieldLength = (int) [DDFUtils DDFScanInt: pachData+nEntryOffset
                                      nMaxChars: _sizeFieldLength];
            
            nEntryOffset += _sizeFieldLength;
            nFieldPos = (int) [DDFUtils DDFScanInt: pachData+nEntryOffset
                                   nMaxChars: _sizeFieldPos];
            
            // Find the corresponding field in the module directory.
            DDFFieldDefinition *poFieldDefn = [poModule FindFieldDefn: @(szTag)];
            
            if(poFieldDefn == NULL) {
                NSLog(@"Undefined field '%s' encountered in data record.", szTag);
                return FALSE;
            }
            DDFField *newDDFField = [[DDFField alloc] init];
            // Assign info the DDFField.
            [newDDFField Initialize: poFieldDefn
                            pszData: [NSString stringWithCString: pachData + _fieldAreaStart + nFieldPos - nLeaderSize encoding: NSUTF8StringEncoding]
                              nSize: nFieldLength];
            [paoFields addObject: newDDFField];
        }
        return TRUE;
    }
}

-(int) GetFieldCount {
    return nFieldCount;
}

-(DDFField *) FindField: (const char *) pszName
            iFieldIndex: (int) iFieldIndex {  // = 0;
    for(int i = 0; i < nFieldCount; i++) {
        DDFField *field = paoFields[i];
        DDFFieldDefinition *definition = [field GetFieldDefn];
        NSString *foundName = [definition GetName];
        if([foundName isEqualToString: @(pszName)]) {
            if(iFieldIndex == 0) {
                return paoFields[i];
            } else {
                iFieldIndex--;
            }
        }
    }
    return NULL;
}

-(DDFField *) GetField: (int) i {
    if(i < 0 || i >= nFieldCount) {
        return NULL;
    } else {
        return paoFields[i];
    }
}

-(int) ResizeField: (DDFField *) poField
      nNewDataSize: (int) nNewDataSize {
    int iTarget, i;
    int nBytesToMove;
    
    // Find which field we are to resize.                              */
    
    for(iTarget = 0; iTarget < nFieldCount; iTarget++) {
        if(paoFields[iTarget] == poField) {
            break;
        }
    }
    
    if(iTarget == nFieldCount) {
//        assert(FALSE);
        return FALSE;
    }
    
    // Reallocate the data buffer accordingly.
    int nBytesToAdd = nNewDataSize - [poField GetDataSize];
    const char *pachOldData = pachData;
    
    // Don't realloc things smaller ... we will cut off some data.
    if(nBytesToAdd > 0) {
        pachData = (char *) realloc(pachData, nDataSize + nBytesToAdd);
    }
    nDataSize += nBytesToAdd;
    
    // How much data needs to be shifted up or down after this field?
    nBytesToMove = nDataSize - ([[poField GetData] UTF8String]+[poField GetDataSize]-pachOldData+nBytesToAdd);
    
    // Update fields to point into newly allocated buffer.
    for(i = 0; i < nFieldCount; i++) {
        DDFField *field = paoFields[i];
        int nOffset = [[field GetData] UTF8String] - pachOldData;
        [field Initialize: paoFields[i]
                  pszData: [NSString stringWithUTF8String: pachData + nOffset]];
    }
    
    // Shift the data beyond this field up or down as needed.
    if(nBytesToMove > 0) {
        memmove((char *)[[poField GetData] UTF8String]+[poField GetDataSize]+nBytesToAdd,
                (char *)[[poField GetData] UTF8String]+[poField GetDataSize],
                nBytesToMove);
    }
    
    // Update the target fields info.
    [poField Initialize: [poField GetFieldDefn]
                pszData: [poField GetData]
                  nSize: [poField GetDataSize] + nBytesToAdd];

    // Shift all following fields down, and update their data locations.
    if(nBytesToAdd < 0) {
        for(i = iTarget+1; i < nFieldCount; i++) {
            DDFField *field = paoFields[i];
            NSString *pszOldDataLocation = [field GetData];
            [paoFields[i] Initialize: field
                             pszData: [pszOldDataLocation substringFromIndex: nBytesToAdd]];
        }
    } else {
        for(i = nFieldCount-1; i > iTarget; i--) {
            DDFField *field = paoFields[i];
            NSString *pszOldDataLocation = [field GetData];
            [paoFields[i] Initialize: paoFields[i]
                             pszData: [pszOldDataLocation substringFromIndex: nBytesToAdd]];
        }
    }
    return TRUE;
}

-(int) DeleteField: (DDFField *) poTarget {
    int iTarget, i;
    
    // Find which field we are to delete.
    for(iTarget = 0; iTarget < nFieldCount; iTarget++) {
        if(paoFields[iTarget] == poTarget) {
            break;
        }
    }
    if(iTarget == nFieldCount) {
        return FALSE;
    }
    
    // Change the target fields data size to zero.  This takes care
    // of repacking the data array, and updating all the following
    // field data pointers.
    [self ResizeField: poTarget nNewDataSize: 0];
    
    // remove the target field, moving down all the other fields
    // one step in the field list.
    for(i = iTarget; i < nFieldCount-1; i++) {
        paoFields[i] = paoFields[i+1];
    }
    nFieldCount--;
    return TRUE;
}

-(DDFField *) AddField: (DDFFieldDefinition *) poDefn {
//    // Reallocate the fields array larger by one, and initialize the new field.
//    DDFField *paoNewFields;
//
//    paoNewFields = new DDFField[nFieldCount+1];
//    if(nFieldCount > 0) {
//        memcpy(paoNewFields, paoFields, sizeof(DDFField) * nFieldCount);
//        delete[] paoFields;
//    }
//    paoFields = paoNewFields;
//    nFieldCount++;
//
//    // Initialize the new field properly.
//    if(nFieldCount == 1) {
//        paoFields[0].Initialize(poDefn, [self GetData], 0);
//    } else {
//        paoFields[nFieldCount-1].Initialize(
//                                            poDefn,
//                                            paoFields[nFieldCount-2].GetData()
//                                            + paoFields[nFieldCount-2].GetDataSize(),
//                                            0);
        
        // Create a new DDFField with this definition
        DDFField *newField = [[DDFField alloc] init];
        [newField Initialize: poDefn pszData: [NSString stringWithCString: [self GetData] encoding: NSUTF8StringEncoding] nSize:0];
        [paoFields addObject: newField];
        nFieldCount++;
//    }
    
    // Initialize field.
    [self CreateDefaultFieldInstance: newField iIndexWithinField: 0];
    return newField;
}

-(int) CreateDefaultFieldInstance: (DDFField *)poField
               iIndexWithinField : (int) iIndexWithinField {
    int nRawSize, nSuccess;
    char *pachRawData;
    
    pachRawData = [[[poField GetFieldDefn] GetDefaultValue: &nRawSize] cStringUsingEncoding: NSUTF8StringEncoding];
    if(pachRawData == NULL) {
        return FALSE;
    }
    nSuccess = [self SetFieldRaw: poField iIndexWithinField: iIndexWithinField pachRawData: pachRawData nRawDataSize: nRawSize];
    pachRawData = NULL;
    return nSuccess;
}

-(int) SetFieldRaw: (DDFField *)poField
 iIndexWithinField: (int) iIndexWithinField
       pachRawData: (const char *)pachRawData
      nRawDataSize: (int) nRawDataSize {
    int         iTarget, nRepeatCount;
    
    //Find which field we are to update.
    for(iTarget = 0; iTarget < nFieldCount; iTarget++) {
        if(paoFields[iTarget] == poField) {
            break;
        }
    }
    
    if(iTarget == nFieldCount) {
        return FALSE;
    }
    nRepeatCount = [poField GetRepeatCount];
    
    if(iIndexWithinField < 0 || iIndexWithinField > nRepeatCount) {
        return FALSE;
    }
    
    // Are we adding an instance? This is easier and different
    // than replacing an existing instance.
    if(iIndexWithinField == nRepeatCount || ![[poField GetFieldDefn] IsRepeating]) {
        char    *pachFieldData;
        int     nOldSize;
        
        if(![[poField GetFieldDefn] IsRepeating] && iIndexWithinField != 0) {
            return FALSE;
        }
        nOldSize = [poField GetDataSize];
        if(nOldSize == 0) {
            nOldSize++; // for added DDF_FIELD_TERMINATOR.
        }
        if(![self ResizeField:poField nNewDataSize: nOldSize + nRawDataSize]) {
            return FALSE;
        }
        pachFieldData = [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding];
        memcpy(pachFieldData + nOldSize - 1, pachRawData, nRawDataSize);
        pachFieldData[nOldSize+nRawDataSize-1] = DDF_FIELD_TERMINATOR;
        return TRUE;
    }
    
    //Get a pointer to the start of the existing data for this
    //iteration of the field.
    const char *pachWrkData;
    int nInstanceSize;
    
    // We special case this to avoid alot of warnings when initializing
    // the field the first time.
    if([poField GetDataSize] == 0) {
        pachWrkData = [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding];
        nInstanceSize = 0;
    } else {
        pachWrkData = [[poField GetInstanceData: iIndexWithinField
                                        pnSize:  &nInstanceSize] cStringUsingEncoding: NSUTF8StringEncoding];
    }
    
    //Create new image of this whole field.
    int nNewFieldSize = [poField GetDataSize] - nInstanceSize + nRawDataSize;
    char *pachNewImage = (char *) malloc(nNewFieldSize);
    int nPreBytes = pachWrkData - [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding];
    int nPostBytes = [poField GetDataSize] - nPreBytes - nInstanceSize;
    memcpy(pachNewImage, [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding], nPreBytes);
    memcpy(pachNewImage + nPreBytes + nRawDataSize, [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding] + nPreBytes + nInstanceSize, nPostBytes);
    memcpy(pachNewImage + nPreBytes, pachRawData, nRawDataSize);
    
    //Resize the field to the desired new size.
    [self ResizeField: poField nNewDataSize: nNewFieldSize];
    memcpy((void *) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding], pachNewImage, nNewFieldSize);
    pachNewImage = NULL;
    return TRUE;
}

-(int) UpdateFieldRaw: (DDFField *) poField
    iIndexWithinField: (int) iIndexWithinField
         nStartOffset: (int) nStartOffset
             nOldSize: (int) nOldSize
          pachRawData: (const char *)pachRawData
         nRawDataSize: (int) nRawDataSize {
    int iTarget, nRepeatCount;
    
    //Find which field we are to update.
    for(iTarget = 0; iTarget < nFieldCount; iTarget++) {
        if(paoFields[iTarget] == poField) {
            break;
        }
    }
    if(iTarget == nFieldCount) {
        return FALSE;
    }
    nRepeatCount = [poField GetRepeatCount];
    if(iIndexWithinField < 0 || iIndexWithinField >= nRepeatCount) {
        return FALSE;
    }
    
    // Figure out how much pre and post data there is.
    int nInstanceSize;
    char *pachWrkData = [[poField GetInstanceData: iIndexWithinField
                                                   pnSize: &nInstanceSize] cStringUsingEncoding: NSUTF8StringEncoding];
    int nPreBytes = pachWrkData - [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding] + nStartOffset;
    int nPostBytes = [poField GetDataSize] - nPreBytes - nOldSize;
    
    // If we aren't changing the size, just copy over the existing data.
    if(nOldSize == nRawDataSize) {
        memcpy(pachWrkData + nStartOffset, pachRawData, nRawDataSize);
        return TRUE;
    }
    
    // If we are shrinking, move in the new data, and shuffle down the old before resizing.
    if(nRawDataSize < nOldSize) {
        memcpy(((char*) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes, pachRawData, nRawDataSize);
        memmove(((char *) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes + nRawDataSize,
                ((char *) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes + nOldSize, nPostBytes);
    }
    
    // Resize the whole buffer.
    if(![self ResizeField: poField
             nNewDataSize: [poField GetDataSize] - nOldSize + nRawDataSize]) {
        return FALSE;
    }
    
    // If we growing the buffer, shuffle up the post data, and move in our new values.
    if(nRawDataSize >= nOldSize) {
        memmove(((char *) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes + nRawDataSize,
                ((char *) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes + nOldSize,
                nPostBytes);
        memcpy(((char*) [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding]) + nPreBytes,
               pachRawData, nRawDataSize);
    }
    return TRUE;
}

-(int) GetIntSubfield: (const char *) pszField
          iFieldIndex: (int) iFieldIndex
          pszSubfield: (const char *) pszSubfield
       iSubfieldIndex: (int) iSubfieldIndex
            pnSuccess: (int *) pnSuccess { // = NULL
    
    int nDummyErr;
    
    if(pnSuccess == NULL) {
        pnSuccess = &nDummyErr;
    }
    *pnSuccess = FALSE;
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return 0;
    }
    
    // Get the subfield definition
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return 0;
    }
    
    // Get a pointer to the data.
    int nBytesRemaining;
    const char *pachData = [[poField GetSubfieldData: poSFDefn
                                         pnMaxBytes: &nBytesRemaining
                                     iSubfieldIndex: iSubfieldIndex] cStringUsingEncoding: NSUTF8StringEncoding];
    // Return the extracted value.
    *pnSuccess = TRUE;
    return([poSFDefn ExtractIntData: [NSString stringWithCString: pachData encoding: NSUTF8StringEncoding]
                          nMaxBytes: nBytesRemaining
                    pnConsumedBytes: NULL]);
}

-(double) GetFloatSubfield: (const char *) pszField
               iFieldIndex: (int) iFieldIndex
               pszSubfield: (const char *) pszSubfield
            iSubfieldIndex: (int) iSubfieldIndex
                 pnSuccess: (int *) pnSuccess { // = NULL
    
    int nDummyErr;
    
    if(pnSuccess == NULL)
        pnSuccess = &nDummyErr;
    
    *pnSuccess = FALSE;
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return 0;
    }
    
    // Get the subfield definition.
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return 0;
    }
    
    //Get a pointer to the data.
    int nBytesRemaining;
    const char *pachData = [[poField GetSubfieldData: poSFDefn
                                         pnMaxBytes: &nBytesRemaining
                                     iSubfieldIndex: iSubfieldIndex] cStringUsingEncoding: NSUTF8StringEncoding];
    // Return the extracted value.
    *pnSuccess = TRUE;
    return([poSFDefn ExtractFloatData: [NSString stringWithCString: pachData encoding: NSUTF8StringEncoding]
                            nMaxBytes: nBytesRemaining
                      pnConsumedBytes: NULL]);
}

-(NSString *) GetStringSubfield: (const char *) pszField
                      iFieldIndex: (int) iFieldIndex
                      pszSubfield: (const char *) pszSubfield
                   iSubfieldIndex: (int) iSubfieldIndex
                        pnSuccess: (int *) pnSuccess { // = NULL
    int nDummyErr;
    
    if(pnSuccess == NULL) {
        pnSuccess = &nDummyErr;
    }
    *pnSuccess = FALSE;
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return NULL;
    }
    
    // Get the subfield definition
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return NULL;
    }
    
    // Get a pointer to the data.
    int nBytesRemaining;
    NSString *pachData = [poField GetSubfieldData: poSFDefn
                                         pnMaxBytes: &nBytesRemaining
                                     iSubfieldIndex: iSubfieldIndex];
    
    // Return the extracted value.
    *pnSuccess = TRUE;
    return([poSFDefn ExtractStringData: pachData
                             nMaxBytes: nBytesRemaining
                       pnConsumedBytes: NULL]);
}

-(int) SetIntSubfield: (const char *) pszField
          iFieldIndex: (int) iFieldIndex
          pszSubfield: (const char *) pszSubfield
       iSubfieldIndex: (int) iSubfieldIndex
            nNewValue: (int) nNewValue {
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return FALSE;
    }
    
    // Get the subfield definition
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return FALSE;
    }
    
    // How long will the formatted value be?
    int nFormattedLen;
    if(![poSFDefn FormatIntValue: NULL
                 nBytesAvailable: 0
                     pnBytesUsed: &nFormattedLen
                       nNewValue: nNewValue]) {
        return FALSE;
    }
    
    // Get a pointer to the data.
    int nMaxBytes;
    NSString *pachSubfieldData = [poField GetSubfieldData: poSFDefn
                                                   pnMaxBytes: &nMaxBytes
                                               iSubfieldIndex: iSubfieldIndex];
    
    // Add new instance if we have run out of data.
    assert([pachSubfieldData length] > 1);
    if(nMaxBytes == 0 || (nMaxBytes == 1 && [pachSubfieldData characterAtIndex: 0] == DDF_FIELD_TERMINATOR)) {
        [self CreateDefaultFieldInstance: poField
                       iIndexWithinField: iSubfieldIndex];
        
        // Refetch.
        pachSubfieldData = [poField GetSubfieldData: poSFDefn
                      pnMaxBytes: &nMaxBytes
                  iSubfieldIndex: iSubfieldIndex];
    }
    
    // If the new length matches the existing length, just overlay and return.
    int nExistingLength;
    [poSFDefn GetDataLength: pachSubfieldData
                  nMaxBytes: nMaxBytes
            pnConsumedBytes: &nExistingLength];
    
    if(nExistingLength == nFormattedLen) {
        return [poSFDefn FormatIntValue: pachSubfieldData
                        nBytesAvailable: nFormattedLen
                            pnBytesUsed: NULL
                              nNewValue: nNewValue];
    }
    
    // We will need to resize the raw data.
    int nInstanceSize;
    const char *pachFieldInstData = [[poField GetInstanceData: iFieldIndex
                                                      pnSize: &nInstanceSize] cStringUsingEncoding: NSUTF8StringEncoding];
    int nStartOffset = [pachSubfieldData cStringUsingEncoding: NSUTF8StringEncoding] - pachFieldInstData;
    char *pachNewData = (char *) malloc(nFormattedLen);
    [poSFDefn FormatIntValue: [NSMutableString stringWithCString: pachNewData encoding: NSUTF8StringEncoding]
             nBytesAvailable: nFormattedLen
                 pnBytesUsed: NULL
                   nNewValue: nNewValue];
    
    int nSuccess = [self UpdateFieldRaw: poField
                      iIndexWithinField: iFieldIndex
                           nStartOffset: nStartOffset
                               nOldSize: nExistingLength
                            pachRawData: pachNewData
                           nRawDataSize: nFormattedLen];
    pachNewData = nil;
    return nSuccess;
}

-(int) SetStringSubfield: (const char *) pszField
             iFieldIndex: (int) iFieldIndex
             pszSubfield: (const char *) pszSubfield
          iSubfieldIndex: (int) iSubfieldIndex
                pszValue: (const char *) pszValue
            nValueLength: (int) nValueLength {
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return FALSE;
    }
    
    // Get the subfield definition
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return FALSE;
    }
    
    // How long will the formatted value be?
    int nFormattedLen;
    if(![poSFDefn FormatStringValue: NULL
                    nBytesAvailable: 0
                        pnBytesUsed: &nFormattedLen
                           pszValue: pszValue
                       nValueLength: nValueLength]) {
        return FALSE;
    }
    
    // Get a pointer to the data.
    int nMaxBytes;
    NSString *pachSubfieldData = [poField GetSubfieldData: poSFDefn
                                                   pnMaxBytes: &nMaxBytes
                                               iSubfieldIndex: iSubfieldIndex];
    
    //Add new instance if we have run out of data.
    assert([pachSubfieldData length] > 1);
    if(nMaxBytes == 0 || (nMaxBytes == 1 && [pachSubfieldData characterAtIndex: 0] == DDF_FIELD_TERMINATOR)) {
        [self CreateDefaultFieldInstance: poField iIndexWithinField: iSubfieldIndex];
        
        // Refetch.
        pachSubfieldData = [poField GetSubfieldData: poSFDefn
                                                 pnMaxBytes: &nMaxBytes
                                             iSubfieldIndex: iSubfieldIndex];
    }
    
    // If the new length matches the existing length, just overlay and return.
    int nExistingLength;
    [poSFDefn GetDataLength: pachSubfieldData
                  nMaxBytes: nMaxBytes
            pnConsumedBytes: &nExistingLength];
    if(nExistingLength == nFormattedLen) {
        return [poSFDefn FormatStringValue: pachSubfieldData
                           nBytesAvailable: nFormattedLen
                               pnBytesUsed: NULL
                                  pszValue: pszValue
                              nValueLength: nValueLength];
    }
    
    // We will need to resize the raw data.
    int nInstanceSize;
    const char *pachFieldInstData = [[poField GetInstanceData: iFieldIndex
                                                      pnSize: &nInstanceSize] cStringUsingEncoding: NSUTF8StringEncoding];
    int nStartOffset = [pachSubfieldData cStringUsingEncoding: NSUTF8StringEncoding] - pachFieldInstData;
    char *pachNewData = (char *) malloc(nFormattedLen);
    [poSFDefn FormatStringValue: [NSMutableString stringWithCString: pachNewData encoding: NSUTF8StringEncoding]
                nBytesAvailable: nFormattedLen
                    pnBytesUsed: NULL
                       pszValue: pszValue
                   nValueLength: nValueLength];
    
    int nSuccess = [self UpdateFieldRaw: poField
                      iIndexWithinField: iFieldIndex
                           nStartOffset: nStartOffset
                               nOldSize: nExistingLength
                            pachRawData: pachNewData
                           nRawDataSize: nFormattedLen];
    pachNewData = nil;
    return nSuccess;
}

-(int) SetFloatSubfield: (const char *) pszField
            iFieldIndex: (int) iFieldIndex
            pszSubfield: (const char *) pszSubfield
         iSubfieldIndex: (int) iSubfieldIndex
             dfNewValue: (double) dfNewValue {
    
    // Fetch the field. If this fails, return zero.
    DDFField *poField = [self FindField: pszField iFieldIndex: iFieldIndex];
    if(poField == NULL) {
        return FALSE;
    }
    
    // Get the subfield definition
    DDFSubfieldDefinition *poSFDefn = [[poField GetFieldDefn] FindSubfieldDefn: @(pszSubfield)];
    if(poSFDefn == NULL) {
        return FALSE;
    }
    
    // How long will the formatted value be?
    int nFormattedLen;
    if(![poSFDefn FormatFloatValue: NULL
                   nBytesAvailable: 0
                       pnBytesUsed: &nFormattedLen
                        dfNewValue: dfNewValue]) {
        return FALSE;
    }
    
    // Get a pointer to the data.
    int nMaxBytes;
    NSString *pachSubfieldData = [poField GetSubfieldData: poSFDefn
                                                    pnMaxBytes: &nMaxBytes
                                                iSubfieldIndex: iSubfieldIndex];
    // Add new instance if we have run out of data.
    if(nMaxBytes == 0 || (nMaxBytes == 1 && [pachSubfieldData characterAtIndex: 0] == DDF_FIELD_TERMINATOR)) {
        [self CreateDefaultFieldInstance: poField iIndexWithinField: iSubfieldIndex];
        // Refetch.
        pachSubfieldData = [poField GetSubfieldData: poSFDefn
                                                  pnMaxBytes: &nMaxBytes
                                              iSubfieldIndex: iSubfieldIndex];
    }
    
    // If the new length matches the existing length, just overlay and return.
    int nExistingLength;
    [poSFDefn GetDataLength: pachSubfieldData
                  nMaxBytes: nMaxBytes
            pnConsumedBytes: &nExistingLength];
    
    if(nExistingLength == nFormattedLen) {
        return [poSFDefn FormatFloatValue: pachSubfieldData
                          nBytesAvailable: nFormattedLen
                              pnBytesUsed: NULL
                               dfNewValue: dfNewValue];
    }
    
    // We will need to resize the raw data.
    int nInstanceSize;
    NSString *pachFieldInstData = [poField GetInstanceData: iFieldIndex
                                                      pnSize: &nInstanceSize];
    int nStartOffset = (int) ([pachSubfieldData  cStringUsingEncoding: NSUTF8StringEncoding] - [pachFieldInstData cStringUsingEncoding: NSUTF8StringEncoding]);
    char *pachNewData = (char *) malloc(nFormattedLen);
    
    [poSFDefn FormatFloatValue: [NSMutableString stringWithCString: pachNewData encoding: NSUTF8StringEncoding]
               nBytesAvailable: nFormattedLen
                   pnBytesUsed: NULL
                    dfNewValue: dfNewValue];
    
    int nSuccess = [self UpdateFieldRaw: poField
       iIndexWithinField: iFieldIndex
            nStartOffset: nStartOffset
                nOldSize: nExistingLength
             pachRawData: pachNewData
            nRawDataSize: nFormattedLen];
    pachNewData = nil;
    return nSuccess;
}

-(int) Write {
    if(![self ResetDirectory]) {
        return FALSE;
    }
    
    // Prepare leader.
    char szLeader[nLeaderSize+1];
    
    memset(szLeader, ' ', nLeaderSize);
    
    sprintf(szLeader+0, "%05d", (int) (nDataSize + nLeaderSize));
    szLeader[5] = ' ';
    szLeader[6] = 'D';
    
    sprintf(szLeader + 12, "%05d", (int) (nFieldOffset + nLeaderSize));
    szLeader[17] = ' ';
    
    szLeader[20] = (char) ('0' + _sizeFieldLength);
    szLeader[21] = (char) ('0' + _sizeFieldPos);
    szLeader[22] = '0';
    szLeader[23] = (char) ('0' + _sizeFieldTag);
    
    // notdef: lots of stuff missing
    // Write the leader.
    fwrite(szLeader, nLeaderSize, 1, [poModule GetFP]);
    
    // Write the remainder of the record.
    fwrite(pachData, nDataSize, 1, [poModule GetFP]);
    return TRUE;
}

-(int) Read {
    // Redefine the record on the basis of the header if needed.
    // As a side effect this will read the data for the record as well.
    if(!nReuseHeader) {
        return([self ReadHeader]);
    }
    
    // Otherwise we read just the data and carefully overlay it on the
    // previous records data without disturbing the rest of the record.
    size_t nReadBytes = fread(pachData + nFieldOffset, 1,
                       nDataSize - nFieldOffset,
                       [poModule GetFP]);
    if(nReadBytes != (size_t) (nDataSize - nFieldOffset) && nReadBytes == 0 && feof([poModule GetFP])) {
        return FALSE;
    } else if(nReadBytes != (size_t) (nDataSize - nFieldOffset)) {
        NSLog(@"Data record is short on DDF file.\n");
        return FALSE;
    }
    
    // notdef: eventually we may have to do something at this point to
    // notify the DDFField's that their data values have changed.
    return TRUE;
}

-(void) Clear {
//    if(paoFields != NULL) {
//        paoFields = NULL;
//    }
    nFieldCount = 0;
    if(pachData != NULL) {
        pachData = NULL;
    }
    nDataSize = 0;
    nReuseHeader = FALSE;
}

-(int) ResetDirectory {
    int iField;
    // Eventually we should try to optimize the size of offset and field length.
    // For now we will use 5 for each which is pretty big.
    _sizeFieldPos = 5;
    _sizeFieldLength = 5;
    
    // Compute how large the directory needs to be.
    int nEntrySize = _sizeFieldPos + _sizeFieldLength + _sizeFieldTag;
    int nDirSize = nEntrySize * nFieldCount + 1;
    
    // If the directory size is different than what is currently
    // reserved for it, we must resize.
    if(nDirSize != nFieldOffset) {
        
        int nNewDataSize = nDataSize - nFieldOffset + nDirSize;
        char *pachNewData = (char *) malloc(nNewDataSize);
        memcpy(pachNewData + nDirSize,
               pachData + nFieldOffset,
               nNewDataSize - nDirSize);
        
        for(iField = 0; iField < nFieldCount; iField++) {
            DDFField *poField = [self GetField: iField];
            int nOffset = [[poField GetData] cStringUsingEncoding: NSUTF8StringEncoding] - pachData - nFieldOffset + nDirSize;
            [poField Initialize: [poField GetFieldDefn]
                        pszData: [NSString stringWithUTF8String: pachNewData + nOffset]
                          nSize: [poField GetDataSize]];
        }
        
        pachData = nil;
        pachData = pachNewData;
        nDataSize = nNewDataSize;
        nFieldOffset = nDirSize;
    }
    
    
    // Now set each directory entry.
    for(iField = 0; iField < nFieldCount; iField++) {
        DDFField *poField = [self GetField: iField];
        DDFFieldDefinition *poDefn = [poField GetFieldDefn];
        char szFormat[128];
        
        sprintf(szFormat, "%%%ds%%0%dd%%0%dd", _sizeFieldTag, _sizeFieldLength, _sizeFieldPos);
        sprintf(pachData + nEntrySize * iField, szFormat,
                [poDefn GetName], [poField GetDataSize],
                [[poField GetData] UTF8String] - pachData - nFieldOffset);
    }
    pachData[nEntrySize * nFieldCount] = DDF_FIELD_TERMINATOR;
    return TRUE;
}

-(DDFRecord *) Clone {
    DDFRecord   *poNR;

    poNR = [[DDFRecord alloc] init: poModule];

    poNR->nReuseHeader = FALSE;
    poNR->nFieldOffset = nFieldOffset;
    
    poNR->nDataSize = nDataSize;
    poNR->pachData = (char *) malloc(nDataSize);
    memcpy( poNR->pachData, pachData, nDataSize );
    
    poNR->nFieldCount = nFieldCount;
    for( int i = 0; i < nFieldCount; i++ ) {
        int     nOffset;
        DDFField *field = paoFields[i];
        nOffset = ([[field GetData] UTF8String] - pachData);

        DDFField *recordField = poNR->paoFields[i];
        [recordField Initialize: [field GetFieldDefn]
                        pszData: [NSString stringWithUTF8String: poNR->pachData + nOffset]
                          nSize: [field GetDataSize]];
        poNR->paoFields[i] = recordField;

//        [poNR->paoFields[i] Initialize: [field GetFieldDefn]
//                               pszData: poNR->pachData + nOffset
//                                 nSize: [field GetDataSize]];


//        nOffset = ([paoFields[i] GetData] - pachData);
//        [poNR->paoFields[i] Initialize: [paoFields[i] GetFieldDefn]
//                               pszData: poNR->pachData + nOffset
//                                 nSize: [paoFields[i] GetDataSize]];
        // FIXME:
//        [poNR->paoFields[i] Initialize:[paoFields[i] GetFieldDefn]
//                               pszData:poNR->pachData + nOffset];
    }
    
    poNR->bIsClone = TRUE;
    [poModule AddCloneRecord: poNR];

    return poNR;
}

-(DDFRecord *) CloneOn: (DDFModule *) poTargetModule {
/* -------------------------------------------------------------------- */
/*      Verify that all fields have a corresponding field definition    */
/*      on the target module.                                           */
/* -------------------------------------------------------------------- */
    int         i;

    for( i = 0; i < nFieldCount; i++ )
    {
        DDFFieldDefinition    *poDefn = [paoFields[i] GetFieldDefn];

        if( [poTargetModule FindFieldDefn: [poDefn GetName]] == NULL )
            return NULL;
    }

/* -------------------------------------------------------------------- */
/*      Create a clone.                                                 */
/* -------------------------------------------------------------------- */
    DDFRecord   *poClone;

    poClone = [self Clone];

/* -------------------------------------------------------------------- */
/*      Update all internal information to reference other module.      */
/* -------------------------------------------------------------------- */
    for( i = 0; i < nFieldCount; i++ )
    {
        DDFField        *poField = poClone->paoFields[i];
        DDFFieldDefinition    *poDefn;

        poDefn = [poTargetModule FindFieldDefn: [[poField GetFieldDefn] GetName]];
        
        [poField Initialize: poDefn
                    pszData: [poField GetData]
                      nSize: [poField GetDataSize]];
    }

    [poModule RemoveCloneRecord: poClone];
    poClone->poModule = poTargetModule;
    [poTargetModule AddCloneRecord: poClone];

    return poClone;
}

@end
