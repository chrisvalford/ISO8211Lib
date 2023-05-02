//
//  DDFFieldDefinition.h
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#ifndef DDFFieldDefn_h
#define DDFFieldDefn_h

#import "DDFSubfieldDefinition.h"
#import "DDFModule.h"

@class DDFSubfieldDefinition;

/**
 * Information from the DDR defining one field.  Note that just because
 * a field is defined for a DDFModule doesn't mean that it actually occurs
 * on any records in the module.  DDFFieldDefns are normally just significant
 * as containers of the DDFSubfieldDefns.
 */
@interface DDFFieldDefinition: NSObject

@property (readonly) NSString *tag;
@property (readonly) NSString * _fieldName;

typedef NS_ENUM(NSInteger, DDF_data_struct_code) {
    dsc_elementary,
    dsc_vector,
    dsc_array,
    dsc_concatenated
};

typedef NS_ENUM(NSInteger, DDF_data_type_code) {
    dtc_char_string,
    dtc_implicit_point,
    dtc_explicit_point,
    dtc_explicit_point_scaled,
    dtc_char_bit_string,
    dtc_bit_string,
    dtc_mixed_data_type
};

//public:
-(instancetype) init;
-(void)dealloc;

-(int) Create: (NSString *) pszTag
 pszFieldName: (NSString *) pszFieldName
pszDescription: (NSString *) pszDescription
eDataStructCode: (DDF_data_struct_code) eDataStructCode
eDataTypeCode: (DDF_data_type_code) eDataTypeCode
    pszFormat: (NSString *) pszFormat; // TODO: = NULL;

-(void) AddSubfield: (DDFSubfieldDefinition *) poNewSFDefn
   bDontAddToFormat: (int) bDontAddToFormat; // TODO: = false

-(void) AddSubfield: (NSString *)pszName
          pszFormat: (NSString *) pszFormat;

-(int) GenerateDDREntry: (char **) ppachData
               pnLength: (int *) pnLength;


-(int) Initialize: (DDFModule *) poModuleIn
           pszTag: (NSString *) pszTag
            nSize: (int) nSize
       pachRecord: (NSString *) pachRecord;

-(void) Dump: (FILE *) fp;

/** Fetch a pointer to the field name (tag).
 * - Returns: this is an internal copy and shouldn't be freed.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *GetName;

/** Fetch a longer descriptio of this field.
 * - Returns: this is an internal copy and shouldn't be freed.
 */
@property (readonly) NSString *GetDescription;

/** Get the number of subfields. */
@property (NS_NONATOMIC_IOSONLY, readonly) int GetSubfieldCount;

-(DDFSubfieldDefinition *) GetSubfield: (int) i;

-(DDFSubfieldDefinition *) FindSubfieldDefn: (NSString *) pszMnemonic;

/**
 * Get the width of this field.  This function isn't normally used
 * by applications.
 *
 * - Returns: The width of the field in bytes, or zero if the field is not
 * apparently of a fixed width.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int GetFixedWidth;

/**
 * Fetch repeating flag.
 * @see DDFField::GetRepeatCount()
 * - Returns: TRUE if the field is marked as repeating.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int IsRepeating;

-(NSString *) ExpandFormat: (NSString *) pszSrc;

/** this is just for an S-57 hack for swedish data */
-(void) SetRepeatingFlag: (int) n;

-(NSString *) GetDefaultValue: (int *) pnSize;

-(void) Log;

@end

#endif /* DDFFieldDefn_h */
