//
//  DDFRecord.h
//  ISO8211Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#ifndef DDFRecord_h
#define DDFRecord_h

#import <Foundation/Foundation.h>

#import "ISO8211.h"
#import "DDFRecord.h"

@class DDFModule;
@class DDFFieldDefinition;

/**
 * Contains instance data from one data record (DR).  The data is contained
 * as a list of DDFField instances partitioning the raw data into fields.
 */
@interface DDFRecord: NSObject

@property (retain) NSMutableArray* paoFields; // DDFField[nFieldCount];

//public:
-(instancetype) init: (DDFModule *) moduleIn;
-(void) dealloc;

/**
 * Make a copy of a record.
 *
 * This method is used to make a copy of a record that will become (mostly)
 * the properly of application.  However, it is automatically destroyed if
 * the DDFModule it was created relative to is destroyed, as it's field
 * and subfield definitions relate to that DDFModule.  However, it does
 * persist even when the record returned by DDFModule::ReadRecord() is
 * invalidated, such as when reading a new record.  This allows an application
 * to cache whole DDFRecords.
 *
 * @return A new copy of the DDFRecord.  This can be delete'd by the
 * application when no longer needed, otherwise it will be cleaned up when
 * the DDFModule it relates to is destroyed or closed.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) DDFRecord *Clone;

/**
 * Recreate a record referencing another module.
 *
 * Works similarly to the DDFRecord::Clone() method, but creates the
 * new record with reference to a different DDFModule.  All DDFFieldDefinition
 * references are transcribed onto the new module based on field names.
 * If any fields don't have a similarly named field on the target module
 * the operation will fail.  No validation of field types and properties
 * is done, but this operation is intended only to be used between
 * modules with matching definitions of all affected fields.
 *
 * The new record will be managed as a clone by the target module in
 * a manner similar to regular clones.
 *
 * @param poTargetModule the module on which the record copy should be
 * created.
 *
 * @return NULL on failure or a pointer to the cloned record.
 */
-(DDFRecord *) cloneOn: (DDFModule *) poTargetModule;

/**
 * Write out record contents to debugging file.
 *
 * A variety of information about this record, and all it's fields and
 * subfields is written to the given debugging file handle.  Note that
 * field definition information (ala DDFFieldDefinition) isn't written.
 *
 * @param fp The standard io file handle to write to.  ie. stderr
 */
-(void) dump: (FILE *) fp;

/// Get the number of DDFFields on this record.
@property (NS_NONATOMIC_IOSONLY, readonly) int getFieldCount;

/**
 * Find the named field within this record.
 *
 * @param pszName The name of the field to fetch.  The comparison is
 * case insensitive.
 * @param iFieldIndex The instance of this field to fetch.  Use zero (the
 * default) for the first instance.
 *
 * @return Pointer to the requested DDFField.  This pointer is to an
 * internal object, and should not be freed.  It remains valid until
 * the next record read.
 */
-(DDFField *) findField: (const char *) pszName
            iFieldIndex: (int) iFieldIndex;  // = 0;

/**
 * Fetch field object based on index.
 *
 * @param i The index of the field to fetch.  Between 0 and GetFieldCount()-1.
 *
 * @return A DDFField pointer, or NULL if the index is out of range.
 */
-(DDFField *) getField: (int) i;

/**
 * Fetch value of a subfield as an integer.  This is a convenience
 * function for fetching a subfield of a field within this record.
 *
 * @param pszField The name of the field containing the subfield.
 * @param iFieldIndex The instance of this field within the record.  Use
 * zero for the first instance of this field.
 * @param pszSubfield The name of the subfield within the selected field.
 * @param iSubfieldIndex The instance of this subfield within the record.
 * Use zero for the first instance.
 * @param pnSuccess Pointer to an int which will be set to TRUE if the fetch
 * succeeds, or FALSE if it fails.  Use NULL if you don't want to check
 * success.
 * @return The value of the subfield, or zero if it failed for some reason.
 */
-(int) getIntSubfield: (const char *) pszField
          iFieldIndex: (int) iFieldIndex
          pszSubfield: (const char *) pszSubfield
       iSubfieldIndex: (int) iSubfieldIndex
            pnSuccess: (int *) pnSuccess;

/**
 * Fetch value of a subfield as a float (double).  This is a convenience
 * function for fetching a subfield of a field within this record.
 *
 * @param pszField The name of the field containing the subfield.
 * @param iFieldIndex The instance of this field within the record.  Use
 * zero for the first instance of this field.
 * @param pszSubfield The name of the subfield within the selected field.
 * @param iSubfieldIndex The instance of this subfield within the record.
 * Use zero for the first instance.
 * @param pnSuccess Pointer to an int which will be set to TRUE if the fetch
 * succeeds, or FALSE if it fails.  Use NULL if you don't want to check
 * success.
 * @return The value of the subfield, or zero if it failed for some reason.
 */
-(double) getFloatSubfield: (const char *) pszField
               iFieldIndex: (int) iFieldIndex
               pszSubfield: (const char *) pszSubfield
            iSubfieldIndex: (int) iSubfieldIndex
                 pnSuccess: (int *) pnSuccess; // = NULL

/**
 * Fetch value of a subfield as a string.  This is a convenience
 * function for fetching a subfield of a field within this record.
 *
 * @param pszField The name of the field containing the subfield.
 * @param iFieldIndex The instance of this field within the record.  Use
 * zero for the first instance of this field.
 * @param pszSubfield The name of the subfield within the selected field.
 * @param iSubfieldIndex The instance of this subfield within the record.
 * Use zero for the first instance.
 * @param pnSuccess Pointer to an int which will be set to TRUE if the fetch
 * succeeds, or FALSE if it fails.  Use NULL if you don't want to check
 * success.
 * @return The value of the subfield, or NULL if it failed for some reason.
 * The returned pointer is to internal data and should not be modified or
 * freed by the application.
 */
-(NSString *) getStringSubfield: (const char *) pszField
                    iFieldIndex: (int) iFieldIndex
                    pszSubfield: (const char *) pszSubfield
                 iSubfieldIndex: (int) iSubfieldIndex
                      pnSuccess: (int *) pnSuccess; // = NULL

/**
 * Set an integer subfield in record.
 *
 * The value of a given subfield is replaced with a new integer value
 * formatted appropriately.
 *
 * @param pszField the field name to operate on.
 * @param iFieldIndex the field index to operate on (zero based).
 * @param pszSubfield the subfield name to operate on.
 * @param iSubfieldIndex the subfield index to operate on (zero based).
 * @param nNewValue the new value to place in the subfield.
 *
 * @return TRUE if successful, and FALSE if not.
 */
-(int) setIntSubfield: (const char *) pszField
          iFieldIndex: (int) iFieldIndex
          pszSubfield: (const char *) pszSubfield
       iSubfieldIndex: (int) iSubfieldIndex
            nNewValue: (int) nNewValue;

/**
 * Set a string subfield in record.
 *
 * The value of a given subfield is replaced with a new string value
 * formatted appropriately.
 *
 * @param pszField the field name to operate on.
 * @param iFieldIndex the field index to operate on (zero based).
 * @param pszSubfield the subfield name to operate on.
 * @param iSubfieldIndex the subfield index to operate on (zero based).
 * @param pszValue the new string to place in the subfield.  This may be
 * arbitrary binary bytes if nValueLength is specified.
 * @param nValueLength the number of valid bytes in pszValue, may be -1 to
 * internally fetch with strlen().
 *
 * @return TRUE if successful, and FALSE if not.
 */
-(int) setStringSubfield: (const char *) pszField
             iFieldIndex: (int) iFieldIndex
             pszSubfield: (const char *) pszSubfield
          iSubfieldIndex: (int) iSubfieldIndex
                pszValue: (const char *) pszValue
            nValueLength: (int) nValueLength; // =-1

/**
 * Set a float subfield in record.
 *
 * The value of a given subfield is replaced with a new float value
 * formatted appropriately.
 *
 * @param pszField the field name to operate on.
 * @param iFieldIndex the field index to operate on (zero based).
 * @param pszSubfield the subfield name to operate on.
 * @param iSubfieldIndex the subfield index to operate on (zero based).
 * @param dfNewValue the new value to place in the subfield.
 *
 * @return TRUE if successful, and FALSE if not.
 */
-(int) setFloatSubfield: (const char *) pszField
            iFieldIndex: (int) iFieldIndex
            pszSubfield: (const char *) pszSubfield
         iSubfieldIndex: (int) iSubfieldIndex
             dfNewValue: (double) dfNewValue;


/// Fetch size of records raw data (GetData()) in bytes.
@property (NS_NONATOMIC_IOSONLY, readonly) int getDataSize;

/**
 * Fetch the raw data for this record.  The returned pointer is effectively
 * to the data for the first field of the record, and is of size GetDataSize().
 */
@property (NS_NONATOMIC_IOSONLY, readonly) const char *getData;

/**
 * Fetch the DDFModule with which this record is associated.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) DDFModule *getModule;

/**
 * Alter field data size within record.
 *
 * This method will rearrange a DDFRecord altering the amount of space
 * reserved for one of the existing fields.  All following fields will
 * be shifted accordingly.  This includes updating the DDFField infos,
 * and actually moving stuff within the data array after reallocating
 * to the desired size.
 *
 * @param poField the field to alter.
 * @param nNewDataSize the number of data bytes to be reserved for the field.
 *
 * @return TRUE on success or FALSE on failure.
 */
-(int) resizeField: (DDFField *) poField
      nNewDataSize: (int) nNewDataSize;

/**
 * Delete a field instance from a record.
 *
 * Remove a field from this record, cleaning up the data
 * portion and repacking the fields list.  We don't try to
 * reallocate the data area of the record to be smaller.
 *
 * NOTE: This method doesn't actually remove the header
 * information for this field from the record tag list yet.
 * This should be added if the resulting record is even to be
 * written back to disk!
 *
 * @param poTarget the field instance on this record to delete.
 *
 * @return TRUE on success, or FALSE on failure.  Failure can occur if
 * poTarget isn't really a field on this record.
 */
-(int) deleteField: (DDFField *) poTarget;

/**
 * Add a new field to record.
 *
 * Add a new zero sized field to the record.  The new field is always
 * added at the end of the record.
 *
 * NOTE: This method doesn't currently update the header information for
 * the record to include the field information for this field, so the
 * resulting record image isn't suitable for writing to disk.  However,
 * everything else about the record state should be updated properly to
 * reflect the new field.
 *
 * @param poDefn the definition of the field to be added.
 *
 * @return the field object on success, or NULL on failure.
 */
-(DDFField *) addField: (DDFFieldDefinition *) poDefn;

/**
 * Initialize default instance.
 *
 * This method is normally only used internally by the AddField() method
 * to initialize the new field instance with default subfield values.  It
 * installs default data for one instance of the field in the record
 * using the DDFFieldDefn::GetDefaultValue() method and
 * DDFRecord::SetFieldRaw().
 *
 * @param poField the field within the record to be assign a default
 * instance.
 * @param iIndexWithinField the instance to set (may not have been tested with
 * values other than 0).
 *
 * @return TRUE on success or FALSE on failure.
 */
-(int) createDefaultFieldInstance: (DDFField *)poField
                iIndexWithinField: (int) iIndexWithinField;

/**
 * Set the raw contents of a field instance.
 *
 * @param poField the field to set data within.
 * @param iIndexWithinField The instance of this field to replace.  Must
 * be a value between 0 and GetRepeatCount().  If GetRepeatCount() is used, a
 * new instance of the field is appeneded.
 * @param pachRawData the raw data to replace this field instance with.
 * @param nRawDataSize the number of bytes pointed to by pachRawData.
 *
 * @return TRUE on success or FALSE on failure.
 */
-(int) setFieldRaw: (DDFField *)poField
 iIndexWithinField: (int) iIndexWithinField
       pachRawData: (const char *)pachRawData
      nRawDataSize: (int) nRawDataSize;


-(int) updateFieldRaw: (DDFField *) poField
    iIndexWithinField: (int) iIndexWithinField
         nStartOffset: (int) nStartOffset
             nOldSize: (int) nOldSize
          pachRawData: (const char *)pachRawData
         nRawDataSize: (int) nRawDataSize;

/**
 * Write record out to module.
 *
 * This method writes the current record to the module to which it is
 * attached.  Normally this would be at the end of the file, and only used
 * for modules newly created with DDFModule::Create().  Rewriting existing
 * records is not supported at this time.  Calling Write() multiple times
 * on a DDFRecord will result it multiple copies being written at the end of
 * the module.
 *
 * @return TRUE on success or FALSE on failure.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int write;

/**
 * Read a record of data from the file, and parse the header to
 * build a field list for the record (or reuse the existing one
 * if reusing headers).  It is expected that the file pointer
 * will be positioned at the beginning of a data record.  It is
 * the DDFModule's responsibility to do so.
 *
 * This method should only be called by the DDFModule class.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int read;

/**
 * Clear any information associated with the last header in
 * preparation for reading a new header.
 */
-(void) clear;

/**
 * Re-prepares the directory information for the record.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int resetDirectory;

@end

#endif /* DDFRecord_h */
