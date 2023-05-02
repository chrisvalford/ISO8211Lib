//
//  DDFModule.h
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#ifndef DDFModule_h
#define DDFModule_h

#import <Foundation/Foundation.h>
#import "ISO8211.h"

@class DDFRecord;
@class DDFFieldDefinition;

/**
 * The primary class for reading ISO 8211 files.  This class contains all
 * the information read from the DDR record, and is used to read records
 * from the file.
 */
@interface DDFModule: NSObject

//public:
-(instancetype) init;
-(void) dealloc;

@property (nonatomic, retain) NSMutableArray *papoFieldDefns; // [DDFFieldDefn]
@property (nonatomic, retain) DDFRecord *poRecord;
@property (nonatomic, retain) NSMutableArray *papoClones; // [DDFRecord]

/**
 * Open an ISO 8211 (DDF) file, and read the DDR record to build the field definitions.
 *
 * If the open succeeds the data descriptive record (DDR) will have been
 * read, and all the field and subfield definitions will be available.
 *
 *  - Parameter filePath: The the file to open.
 *  - Parameter bFailQuietly: If `FALSE` an `Error` is issued for non-8211 files, otherwise quietly return `NULL`. Default FALSE
 *
 *  - Returns: `FALSE` if the open fails or `TRUE` if it succeeds.  Errors messages are issued internally with CPLError().
 */
-(int) Open: (const char *) filePath bFailQuietly: (int) bFailQuietly; // = false

/**
 * Create a new initialized DDFModule
 *
 *  - Parameter pszFilename: The file name
 *
 *  - Returns: `FALSE` if the create fails or `TRUE` if it succeeds.  Errors messages are issued internally with CPLError().
 */
-(int) Create: (const char *) pszFilename;

/**
 * Close an ISO 8211 file and clean up
 *      Note that closing a file also destroys essentially all other module datastructures.
 */
-(void) Close;

/**
 * Initialize this DDFModule
 *  - Parameters:
 *      - chInterchangeLevel: defalut '3'
 *      - chLeaderIden: default 'L'
 *      - chCodeExtensionIndicator: default 'E'
 *      - chVersionNumber: default '1'
 *      - chAppIndicator: default 'SPACE'
 *      - pszExtendedCharSet: default " ! "
 *      - nSizeFieldLength: default 3
 *      - nSizeFieldPos: default 4
 *      - nSizeFieldTag:  default 4
 */
-(int) Initialize: (char) chInterchangeLevel //= '3',
     chLeaderIden: (char) chLeaderIden //= 'L',
chCodeExtensionIndicator: (char) chCodeExtensionIndicator //= 'E',
  chVersionNumber: (char) chVersionNumber //= '1',
   chAppIndicator: (char) chAppIndicator //= ' ',
pszExtendedCharSet: (const char *) pszExtendedCharSet //= " ! ",
 nSizeFieldLength: (int) nSizeFieldLength //= 3,
    nSizeFieldPos: (int) nSizeFieldPos //= 4,
    nSizeFieldTag: (int) nSizeFieldTag; // = 4);

/**
 * Write out module info to debugging file.
 *
 * A variety of information about the module is written to the debugging
 * file.  This includes all the field and subfield definitions read from
 * the header.
 *
 *  - Parameter fp: The standard io file handle to write to.  ie. `stderr`.
 */
-(void) Dump: (FILE *) fp;

/**
 * Read one record from the file, and return to the application.
 *
 * - Returns: A pointer to a `DDFRecord` object is returned, or `NULL` if a read
 * error, or end of file occurs.  The returned record is owned by the
 * module, and should not be deleted by the application.  The record is
 * only valid untill the next ReadRecord() at which point it is overwritten.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) DDFRecord *ReadRecord;

/**
 * Return to first record.
 *
 * The next call to ReadRecord() will read the first data record in the file.
 *
 * - Parameter nOffset: the offset in the file to return to.  By default this is
 * -1, a special value indicating that reading should return to the first
 * data record.  Otherwise it is an absolute byte offset in the file.
 */
-(void) Rewind: (long) nOffset; // = -1

/**
 * Fetch the definition of the named field.
 *
 * This function will scan the DDFFieldDefn's on this module, to find
 * one with the indicated field name.
 *
 * - Parameter pszFieldName: The name of the field to search for.  The comparison is case insensitive.
 *
 * - Returns: A pointer to the request `DDFFieldDefn` object is returned, or `NULL`
 * if none matching the name are found.  The return object remains owned by
 * the `DDFModule`, and should not be deleted by application code.
 */
-(DDFFieldDefinition *) FindFieldDefn: (NSString *) pszFieldName;

/** Fetch the number of defined fields. */

@property (NS_NONATOMIC_IOSONLY, readonly) int GetFieldCount;

/**
 * Fetch a field definition by index.
 *
 * - Parameter i: from 0 to GetFieldCount() - 1
 * - Returns: the returned field pointer or `NULL` if the index is out of range.
 */
-(DDFFieldDefinition *) GetField: (int) i;

/**
 * Add new field definition.
 *
 * Field definitions may only be added to `DDFModules` being used for
 * writing, not those being used for reading.  Ownership of the
 * `DDFFieldDefn` object is taken by the `DDFModule`.
 *
 * - Parameter poNewFDefn: Field definition to be added to the module.
 */
-(void) AddField: (DDFFieldDefinition *) poNewFDefn;

// This is really just for internal use.
@property (NS_NONATOMIC_IOSONLY, readonly) int GetFieldControlLength;

/**
 *   Add a clone record
 *
 * We want to keep track of cloned records, so we can clean them up when the module is destroyed.
 *
 * - Parameter poRecord: The `DDFRecord` to clone
 */
-(void) AddCloneRecord: (DDFRecord *) poRecord;

/**
 * Remove a cloned record
 *
 * - Parameter poRecord: Pointer to the clone to remove.
 */
-(void) RemoveCloneRecord: (DDFRecord *) poRecord;

// This is just for DDFRecord.
@property (NS_NONATOMIC_IOSONLY, readonly) FILE *GetFP;

@end

#endif /* DDFModule_h */
