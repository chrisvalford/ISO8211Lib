//
//  DDFModule.m
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFModule.h"
#import "DDFUtils.h"
#import "ISO8211.h"
#import "DDFFieldDefinition.h"
#import "DDFRecord.h"

@implementation DDFModule {
    
    // private
    FILE *fpDDF;
    int bReadOnly;
    long nFirstRecordOffset;
    char _interchangeLevel;
    char _inlineCodeExtensionIndicator;
    char _versionNumber;
    char _appIndicator;
    int _fieldControlLength;
    char _extendedCharSet[4];
    long _recLength;
    char _leaderIden;
    long _fieldAreaStart;
    long _sizeFieldLength;
    long _sizeFieldPos;
    long _sizeFieldTag;
}

@synthesize papoFieldDefns;
@synthesize poRecord;
@synthesize papoClones;

// One DirEntry per field.
int nFieldDefnCount;
int nCloneCount;
int nMaxCloneCount;

-(instancetype) init {
    self = [super init];
    if (self) {
        nFieldDefnCount = 0;
        poRecord = NULL;
        papoClones = NULL;
        nCloneCount = nMaxCloneCount = 0;
        fpDDF = NULL;
        bReadOnly = TRUE;
        _interchangeLevel = '\0';
        _inlineCodeExtensionIndicator = '\0';
        _versionNumber = '\0';
        _appIndicator = '\0';
        _fieldControlLength = '\0';
        strcpy(_extendedCharSet, " ! ");
        _recLength = 0;
        _leaderIden = 'L';
        _fieldAreaStart = 0;
        _sizeFieldLength = 0;
        _sizeFieldPos = 0;
        _sizeFieldTag = 0;
        papoFieldDefns = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}

-(void) dealloc {
    [self close];
}

-(int) open: (const char *) filePath bFailQuietly: (int) bFailQuietly { // = false
    static const size_t nLeaderSize = 24;
    
    // Close the existing file if there is one.
    if(fpDDF != NULL) {
        [self close];
    }
    // Open the file.
    fpDDF = fopen(filePath, "rb");
    
    if(fpDDF == NULL) {
        if(!bFailQuietly) {
            NSLog(@"Unable to open DDF file '%s'.", filePath);
        }
        return FALSE;
    }
    
    // Read the 24 byte leader.
    char achLeader[nLeaderSize];
    
    if(fread(achLeader, 1, nLeaderSize, fpDDF) != nLeaderSize) {
        fclose(fpDDF);
        fpDDF = NULL;
        
        if(!bFailQuietly) {
            NSLog(@"Leader is short on DDF file '%s'.", filePath);
        }
        return FALSE;
    }
    
    // Verify that this appears to be a valid DDF file.
    int i, bValid = TRUE;
    
    for(i = 0; i < (int)nLeaderSize; i++) {
        if(achLeader[i] < 32 || achLeader[i] > 126) {
            bValid = FALSE;
        }
    }
    
    if(achLeader[5] != '1' && achLeader[5] != '2' && achLeader[5] != '3') {
        bValid = FALSE;
    }
    
    if(achLeader[6] != 'L') {
        bValid = FALSE;
    }

    if(achLeader[8] != '1' && achLeader[8] != ' ') {
        bValid = FALSE;
    }
    
    // Extract information from leader.
    if(bValid) {
        _recLength                    = [DDFUtils DDFScanInt: achLeader+0 nMaxChars: 5];
        _interchangeLevel             = achLeader[5];
        _leaderIden                   = achLeader[6];
        _inlineCodeExtensionIndicator = achLeader[7];
        _versionNumber                = achLeader[8];
        _appIndicator                 = achLeader[9];
        _fieldControlLength           = (int)[DDFUtils DDFScanInt: achLeader+10 nMaxChars: 2];
        _fieldAreaStart               = [DDFUtils DDFScanInt: achLeader+12 nMaxChars: 5];
        _extendedCharSet[0]           = achLeader[17];
        _extendedCharSet[1]           = achLeader[18];
        _extendedCharSet[2]           = achLeader[19];
        _extendedCharSet[3]           = '\0';
        _sizeFieldLength              = [DDFUtils DDFScanInt: achLeader+20 nMaxChars: 1];
        _sizeFieldPos                 = [DDFUtils DDFScanInt: achLeader+21 nMaxChars: 1];
        _sizeFieldTag                 = [DDFUtils DDFScanInt: achLeader+23 nMaxChars: 1];
        
        if(_recLength < 12 || _fieldControlLength == 0 || _fieldAreaStart < 24 || _sizeFieldLength == 0 || _sizeFieldPos == 0 || _sizeFieldTag == 0) {
            bValid = FALSE;
        }
    }
    
    // If the header is invalid, then clean up, report the error and return.
    if(!bValid) {
        fclose(fpDDF);
        fpDDF = NULL;
        
        if(!bFailQuietly) {
            NSLog(@"File '%s' does not appear to have\na valid ISO 8211 header.\n", filePath);
        }
        return FALSE;
    }
    
    // Read the whole record info memory.
    char *pachRecord = (char *) malloc(_recLength);
    memcpy(pachRecord, achLeader, nLeaderSize);
    
    if(fread(pachRecord+nLeaderSize, 1, _recLength-nLeaderSize, fpDDF) != _recLength - nLeaderSize) {
        if(!bFailQuietly) {
            NSLog(@"Header record is short on DDF file '%s'.", filePath);
        }
        return FALSE;
    }
    
    // First make a pass counting the directory entries.
    int nFDCount = 0;
    int nFieldEntryWidth = (int) _sizeFieldLength + (int) _sizeFieldPos + (int) _sizeFieldTag;
    
    for(i = nLeaderSize; i < _recLength; i += nFieldEntryWidth) {
        if(pachRecord[i] == DDF_FIELD_TERMINATOR) {
            break;
        }
        nFDCount++;
    }
    
    // Allocate, and read field definitions.
    for(i = 0; i < nFDCount; i++) {
        char szTag[128];
        int nEntryOffset = nLeaderSize + i*nFieldEntryWidth;
        int nFieldLength, nFieldPos;
        
        strncpy(szTag, pachRecord+nEntryOffset, _sizeFieldTag);
        szTag[_sizeFieldTag] = '\0';
        
        nEntryOffset += _sizeFieldTag;
        nFieldLength = (int) [DDFUtils DDFScanInt: pachRecord+nEntryOffset nMaxChars: _sizeFieldLength];
        
        nEntryOffset += _sizeFieldLength;
        nFieldPos = (int) [DDFUtils DDFScanInt: pachRecord+nEntryOffset nMaxChars: _sizeFieldPos];
        
        DDFFieldDefinition *poFDefn = [[DDFFieldDefinition alloc] init];
        if([poFDefn initialize: self
                        pszTag: [NSString stringWithUTF8String: szTag]
                         nSize: nFieldLength
                    pachRecord: [NSString stringWithUTF8String: pachRecord + _fieldAreaStart + nFieldPos]]) {
            [papoFieldDefns insertObject: poFDefn atIndex: nFieldDefnCount];
            nFieldDefnCount++;
        } else {
            poFDefn = nil;
        }
    }
    pachRecord = nil;
    
    // Record the current file offset, the beginning of the first data record.
    nFirstRecordOffset = ftell(fpDDF);
    return TRUE;
}


-(int) create: (const char *) pszFilename {
//    assert(fpDDF == NULL);
    
    // Create the file on disk.
    fpDDF = fopen(pszFilename, "wb+");
    if(fpDDF == NULL) {
        NSLog(@"Failed to create file %s, check path and permissions.", pszFilename);
        return FALSE;
    }
    
    bReadOnly = FALSE;
    
    // Prepare all the field definition information.
    int iField;
    
    _fieldControlLength = 9;
    _recLength = 24 + nFieldDefnCount * (_sizeFieldLength+_sizeFieldPos+_sizeFieldTag) + 1;
    _fieldAreaStart = _recLength;
    
    for(iField=0; iField < nFieldDefnCount; iField++) {
        int nLength;
        [papoFieldDefns[iField] generateDDREntry: NULL pnLength: &nLength];
        _recLength += nLength;
    }
    
    // Setup 24 byte leader.
    char achLeader[25];
    sprintf(achLeader+0, "%05d", (int) _recLength);
    achLeader[5] = _interchangeLevel;
    achLeader[6] = _leaderIden;
    achLeader[7] = _inlineCodeExtensionIndicator;
    achLeader[8] = _versionNumber;
    achLeader[9] = _appIndicator;
    sprintf(achLeader+10, "%02d", (int) _fieldControlLength);
    sprintf(achLeader+12, "%05d", (int) _fieldAreaStart);
    strncpy(achLeader+17, _extendedCharSet, 3);
    sprintf(achLeader+20, "%1d", (int) _sizeFieldLength);
    sprintf(achLeader+21, "%1d", (int) _sizeFieldPos);
    achLeader[22] = '0';
    sprintf(achLeader+23, "%1d", (int) _sizeFieldTag);
    fwrite(achLeader, 24, 1, fpDDF);
    
    
    // Write out directory entries.
    int nOffset = 0;
    for(iField=0; iField < nFieldDefnCount; iField++) {
        char achDirEntry[12];
        int nLength;
        [papoFieldDefns[iField] generateDDREntry: NULL pnLength: &nLength];
        strcpy(achDirEntry, [[papoFieldDefns[iField] getName] UTF8String]);
        sprintf(achDirEntry + _sizeFieldTag, "%03d", nLength);
        sprintf(achDirEntry + _sizeFieldTag + _sizeFieldLength, "%04d", nOffset);
        nOffset += nLength;
        fwrite(achDirEntry, 11, 1, fpDDF);
    }
    
    char chUT = DDF_FIELD_TERMINATOR;
    fwrite(&chUT, 1, 1, fpDDF);
    
    // Write out the field descriptions themselves.
    for(iField=0; iField < nFieldDefnCount; iField++) {
        char *pachData;
        int nLength;
        
        [papoFieldDefns[iField] generateDDREntry: &pachData pnLength: &nLength];
        fwrite(pachData, nLength, 1, fpDDF);
        pachData = nil;
    }
    return TRUE;
}


-(void) close {
    // Close the file.
    if(fpDDF != NULL) {
        fclose(fpDDF);
        fpDDF = NULL;
    }
    
    // Cleanup the working record.
    if(poRecord != NULL) {
        poRecord = NULL;
    }
    
    [papoClones removeAllObjects];
    nMaxCloneCount = 0;
    
    [papoFieldDefns removeAllObjects];
    nFieldDefnCount = 0;
}

-(int) initialize: (char) chInterchangeLevel //= '3',
     chLeaderIden: (char) chLeaderIden //= 'L',
chCodeExtensionIndicator: (char) chCodeExtensionIndicator //= 'E',
  chVersionNumber: (char) chVersionNumber //= '1',
   chAppIndicator: (char) chAppIndicator //= ' ',
pszExtendedCharSet: (const char *) pszExtendedCharSet //= " ! ",
 nSizeFieldLength: (int) nSizeFieldLength //= 3,
    nSizeFieldPos: (int) nSizeFieldPos //= 4,
    nSizeFieldTag: (int) nSizeFieldTag { // = 4);
    _interchangeLevel = chInterchangeLevel;
    _leaderIden = chLeaderIden;
    _inlineCodeExtensionIndicator = chCodeExtensionIndicator;
    _versionNumber = chVersionNumber;
    _appIndicator = chAppIndicator;
    strcpy(_extendedCharSet, pszExtendedCharSet);
    _sizeFieldLength = nSizeFieldLength;
    _sizeFieldPos = nSizeFieldPos;
    _sizeFieldTag = nSizeFieldTag;
    
    return TRUE;
}

-(void) dump: (FILE *) fp {
    fprintf(fp, "DDFModule:\n");
    fprintf(fp, "    _recLength = %ld\n", _recLength);
    fprintf(fp, "    _interchangeLevel = %c\n", _interchangeLevel);
    fprintf(fp, "    _leaderIden = %c\n", _leaderIden);
    fprintf(fp, "    _inlineCodeExtensionIndicator = %c\n", _inlineCodeExtensionIndicator);
    fprintf(fp, "    _versionNumber = %c\n", _versionNumber);
    fprintf(fp, "    _appIndicator = %c\n", _appIndicator);
    fprintf(fp, "    _extendedCharSet = '%s'\n", _extendedCharSet);
    fprintf(fp, "    _fieldControlLength = %d\n", _fieldControlLength);
    fprintf(fp, "    _fieldAreaStart = %ld\n", _fieldAreaStart);
    fprintf(fp, "    _sizeFieldLength = %ld\n", _sizeFieldLength);
    fprintf(fp, "    _sizeFieldPos = %ld\n", _sizeFieldPos);
    fprintf(fp, "    _sizeFieldTag = %ld\n", _sizeFieldTag);
    
    for(int i = 0; i < nFieldDefnCount; i++) {
        [papoFieldDefns[i] Dump: fp];
    }
}

-(void) log {
    NSLog(@"DDFModule:\n");
    NSLog(@"    _recLength = %ld\n", _recLength);
    NSLog(@"    _interchangeLevel = %c\n", _interchangeLevel);
    NSLog(@"    _leaderIden = %c\n", _leaderIden);
    NSLog(@"    _inlineCodeExtensionIndicator = %c\n", _inlineCodeExtensionIndicator);
    NSLog(@"    _versionNumber = %c\n", _versionNumber);
    NSLog(@"    _appIndicator = %c\n", _appIndicator);
    NSLog(@"    _extendedCharSet = '%s'\n", _extendedCharSet);
    NSLog(@"    _fieldControlLength = %d\n", _fieldControlLength);
    NSLog(@"    _fieldAreaStart = %ld\n", _fieldAreaStart);
    NSLog(@"    _sizeFieldLength = %ld\n", _sizeFieldLength);
    NSLog(@"    _sizeFieldPos = %ld\n", _sizeFieldPos);
    NSLog(@"    _sizeFieldTag = %ld\n", _sizeFieldTag);
    
    for(int i = 0; i < nFieldDefnCount; i++) {
        [papoFieldDefns[i] Log];
    }
}

-(DDFRecord *) readRecord {
    if(poRecord == NULL) {
        poRecord = [[DDFRecord alloc] init: self];
    }
    if([poRecord read]) {
        return poRecord;
    } else {
        return NULL;
    }
}

-(void) rewind: (long) nOffset { // = -1
    if(nOffset == -1) {
        nOffset = nFirstRecordOffset;
    }
    if(fpDDF == NULL) {
        return;
    }
    fseek(fpDDF, nOffset, SEEK_SET);
    
    if(nOffset == nFirstRecordOffset && poRecord != NULL) {
        [poRecord clear];
    }
}

-(DDFFieldDefinition *) findFieldDefn: (NSString *) pszFieldName {
    //  Application code may not always use the correct name case.
    for(int i = 0; i < nFieldDefnCount; i++) {
        DDFFieldDefinition *definition = papoFieldDefns[i];
        NSString *foundName = [definition getName];
        if ([pszFieldName isEqualToString: foundName]) {
            return papoFieldDefns[i];
        }
    }
    return NULL;
}

-(int) getFieldCount {
    return nFieldDefnCount;
}

-(DDFFieldDefinition *) getField: (int) i {
    if(i < 0 || i >= nFieldDefnCount) {
        return NULL;
    } else {
        return papoFieldDefns[i];
    }
}

-(void) addField: (DDFFieldDefinition *) poNewFDefn {
//    if (papoFieldDefns == NULL) {
//        papoFieldDefns = [[NSMutableArray alloc] init];
//    }
    [papoFieldDefns addObject: poNewFDefn];
//    [papoFieldDefns insertObject: poNewFDefn atIndex: nFieldDefnCount];
    nFieldDefnCount++;
    
//    papoFieldDefns = (DDFFieldDefn **) realloc(papoFieldDefns, sizeof(void*)*nFieldDefnCount);
//    papoFieldDefns[nFieldDefnCount-1] = poNewFDefn;
}

// This is really just for internal use.
-(int) getFieldControlLength {
    return _fieldControlLength;
}

-(void) addCloneRecord: (DDFRecord *) poRecord {
    if (papoClones == NULL) {
        papoClones = [[NSMutableArray alloc] init];
    }
    [papoClones addObject: poRecord];
    nCloneCount ++;
    
    // Do we need to grow the container array?
//    if(nCloneCount == nMaxCloneCount) {
//        nMaxCloneCount = nCloneCount*2 + 20;
//        papoClones = (DDFRecord **) realloc(papoClones, nMaxCloneCount * sizeof(void*));
//    }
//    // Add to the list.
//    papoClones[nCloneCount++] = poRecord;
}

-(void) removeCloneRecord: (DDFRecord *) poRecord {
    int i;
    
    for(i = 0; i < nCloneCount; i++) {
        if(papoClones[i] == poRecord) {
            papoClones[i] = papoClones[nCloneCount-1];
            nCloneCount--;
            return;
        }
    }
//    assert(FALSE);
}

-(FILE *) getFP {
    return fpDDF;
}

@end
