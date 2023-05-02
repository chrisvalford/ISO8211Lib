//
//  DDFSubfieldDefinition.h
//  Lib
//
//  Created by Christopher Alford on 9/4/23.
//

#ifndef DDFSubfieldDefn_h
#define DDFSubfieldDefn_h

#import "ISO8211.h"

/**
  General data type
    */
typedef NS_ENUM(NSInteger, DDFDataType) {
    DDFInt,
    DDFFloat,
    DDFString,
    DDFBinaryString
};

/**
 * Information from the DDR record describing one subfield of a DDFFieldDefn.
 * All subfields of a field will occur in each occurance of that field
 * (as a `DDFField`) in a `DDFRecord`.
 * Subfield's actually contain formatted data (as instances within a record).
 */
@interface DDFSubfieldDefinition: NSObject

-(instancetype) init;
-(void) dealloc;

/** Get pointer to subfield name. */
@property NSString *name; // a.k.a. subfield mnemonic

/** Get pointer to subfield format string */
@property (readonly) NSString *GetFormat;

/**
* While interpreting the format string we don't support:
*       o Passing an explicit terminator for variable length field.
*       o 'X' for unused data ... this should really be filtered out by DDFFieldDefn::ApplyFormats(), but isn't.
*       o 'B' bitstrings that aren't a multiple of eight.
*/
-(int) SetFormat: (NSString *) pszFormat;

/**
 * Get the general type of the subfield.  This can be used to
 * determine which of `ExtractFloatData()`, `ExtractIntData()` or
 * `ExtractStringData()` should be used.
 * - Returns: The subfield type.  One of `DDFInt`, `DDFFloat`, `DDFString` or `DDFBinaryString`.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) DDFDataType GetType;

// bIsVariable determines whether we using the
// chFormatDelimeter (TRUE), or the fixed width (FALSE).
@property (assign, readonly) int bIsVariable;
@property (assign, readonly) int nFormatWidth;

/**
 * Extract a subfield value as a float.  Given a pointer to the data
 * for this subfield (from within a DDFRecord) this method will return the
 * floating point data for this subfield.  The number of bytes
 * consumed as part of this field can also be fetched.  This method may be
 * called for any type of subfield, and will return zero if the subfield is
 * not numeric.
 *
 * - Parameters:
 *    - pachSourceData: `NSString` containing raw data for this field.  This
 * may have come from DDFRecord::GetData(), taking into account skip factors
 * over previous subfields data.
 *    - nMaxBytes: The maximum number of bytes that are accessable after
 * pachSourceData.
 *    - pnConsumedBytes: Pointer to an integer into which the number of
 * bytes consumed by this field should be written.  May be NULL to ignore.
 * This is used as a skip factor to increment pachSourceData to point to the
 * next subfields data.
 *
 * - Returns: The subfield's numeric value (or zero if it isn't numeric).
 *
 */
-(double) ExtractFloatData: (NSString *) pachSourceData
                 nMaxBytes: (int) nMaxBytes
           pnConsumedBytes: (int *) pnConsumedBytes;

/**
 * Extract a subfield value as an integer.  Given a pointer to the data
 * for this subfield (from within a DDFRecord) this method will return the
 * int data for this subfield.  The number of bytes
 * consumed as part of this field can also be fetched.  This method may be
 * called for any type of subfield, and will return zero if the subfield is
 * not numeric.
 *
 *  - Parameters:
 *     - pachSourceData: `NSString` containing raw data for this field.  This
 * may have come from DDFRecord::GetData(), taking into account skip factors
 * over previous subfields data.
 *     - nMaxBytes: The maximum number of bytes that are accessable after
 * pachSourceData.
 *     - pnConsumedBytes: Pointer to an integer into which the number of
 * bytes consumed by this field should be written.  May be NULL to ignore.
 * This is used as a skip factor to increment pachSourceData to point to the
 * next subfields data.
 *
 * - Returns: The subfield's numeric value (or zero if it isn't numeric).
 *
 */
-(int) ExtractIntData: (NSString *) pachSourceData
            nMaxBytes: (int) nMaxBytes
      pnConsumedBytes: (int *) pnConsumedBytes;

/**
 * Extract a zero terminated string containing the data for this subfield.
 * Given a pointer to the data
 * for this subfield (from within a DDFRecord) this method will return the
 * data for this subfield.  The number of bytes
 * consumed as part of this field can also be fetched.  This number may
 * be one longer than the string length if there is a terminator character
 * used.
 *
 * This function will return the raw binary data of a subfield for
 * types other than DDFString, including data past zero chars.  This is
 * the standard way of extracting DDFBinaryString subfields for instance.<p>
 *
 * - Parameters:
 *    - pachSourceData: `NSString` containing raw data for this field.  This
 * may have come from DDFRecord::GetData(), taking into account skip factors
 * over previous subfields data.
 *    - nMaxBytes: The maximum number of bytes that are accessable after
 * pachSourceData.
 *    - pnConsumedBytes: Pointer to an integer into which the number of
 * bytes consumed by this field should be written.  May be NULL to ignore.
 * This is used as a skip factor to increment pachSourceData to point to the
 * next subfields data.
 *
 * - Returns: A pointer to a buffer containing the data for this field.  The
 * returned pointer is to an internal buffer which is invalidated on the
 * next ExtractStringData() call on this DDFSubfieldDefn().  It should not
 * be freed by the application.
 *
 */
-(NSString *) ExtractStringData: (NSString *) pachSourceData
                         nMaxBytes: (int) nMaxBytes
                   pnConsumedBytes: (int *) pnConsumedBytes;

/**
 * Scan for the end of variable length data.  Given a pointer to the data
 * for this subfield (from within a `DDFRecord`) this method will return the
 * number of bytes which are data for this subfield.  The number of bytes
 * consumed as part of this field can also be fetched.  This number may
 * be one longer than the length if there is a terminator character
 * used.
 *
 * This method is mainly for internal use, or for applications which
 * want the raw binary data to interpret themselves.  Otherwise use one
 * of `ExtractStringData`, `ExtractIntData` or `ExtractFloatData`.
 *
 * - Parameters:
 *   - pachSourceData: `NSString` containing raw data for this field.
 *   This may have come from DDFRecord::GetData(),
 *   taking into account skip factors over previous subfields data.
 *   - nMaxBytes: The maximum number of bytes that are accessable after pachSourceData.
 *   - pnConsumedBytes: Pointer to an integer into which the number
 *   of bytes consumed by this field should be written.  May be NULL to ignore.
 *
 * - Returns: The number of bytes at pachSourceData which are actual data for
 * this record (not including unit, or field terminator).
 */
- (int) GetDataLength: (NSString *) pachSourceData
            nMaxBytes: (int) nMaxBytes
      pnConsumedBytes: (int *) pnConsumedBytes;

/**
 * Dump subfield value to debugging file.
 *
 * - Parameters:
 *   - pachData: `NSString` containing raw data for this field.
 *   - nMaxBytes: Maximum number of bytes available in pachData.
 *   - fp: File to write report to.
 */
-(void) DumpData: (NSString *) pachData
       nMaxBytes: (int) nMaxBytes
              fp: (FILE *) fp;

-(int) FormatStringValue: (NSString *) pachData
         nBytesAvailable: (int) nBytesAvailable
             pnBytesUsed: (int *) pnBytesUsed
                pszValue: (const char *) pszValue
            nValueLength: (int) nValueLength; // TODO: Default value = -1;

-(int) FormatIntValue: (NSString *) pachData
      nBytesAvailable: (int) nBytesAvailable
          pnBytesUsed: (int *) pnBytesUsed
            nNewValue: (int) nNewValue;

-(int) FormatFloatValue: (NSString *) pachData
        nBytesAvailable: (int) nBytesAvailable
            pnBytesUsed: (int *)pnBytesUsed
             dfNewValue: (double) dfNewValue;

/** Get the subfield width (zero for variable). */
@property (NS_NONATOMIC_IOSONLY, readonly) int GetWidth; // zero for variable.

/**
 * Get default data.
 *
 * Returns the default subfield data contents for this subfield definition.
 * For variable length numbers this will normally be "0<unit-terminator>".
 * For variable length strings it will be "<unit-terminator>".  For fixed
 * length numbers it is zero filled.  For fixed length strings it is space
 * filled.  For binary numbers it is binary zero filled.
 *
 * - Parameters:
 *   - pachData: `NSString` buffer into which the returned default will be placed. May be `NULL` if just querying default size.
 *   - nBytesAvailable: the size of pachData in bytes.
 *   - pnBytesUsed: will receive the size of the subfield default data in bytes.
 *
 * - Returns: `TRUE` on success or `FALSE` on failure or if the passed buffer is too small to hold the default.
 */
-(int) GetDefaultValue: (NSString *)pachData
       nBytesAvailable: (int) nBytesAvailable
           pnBytesUsed: (int *) pnBytesUsed;

/**
 * Write out subfield definition info to debugging file.
 *
 * A variety of information about this field definition is written to the
 * give debugging file handle.
 *
 * - Parameter fp: The standard io file handle to write to.  ie. stderr
 */
-(void) Dump: (FILE *) fp;

/**
  Binary format: this is the digit immediately following the B or b for
  binary formats.
  */
typedef NS_ENUM(NSInteger, DDFBinaryFormat) {
    DDFBinaryFormatNotBinary=0,
    DDFBinaryFormatUInt=1,
    DDFBinaryFormatSInt=2,
    DDFBinaryFormatFPReal=3,
    DDFBinaryFormatFloatReal=4,
    DDFBinaryFormatFloatComplex=5
};

@property (NS_NONATOMIC_IOSONLY, readonly) DDFBinaryFormat GetBinaryFormat;

-(void) Log;

@end

#endif /* DDFSubfieldDefn_h */
