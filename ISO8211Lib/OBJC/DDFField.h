//
//  DDFField.h
//  Lib
//
//  Created by Christopher Alford on 10/4/23.
//

#ifndef DDFField_h
#define DDFField_h

#import "DDFFieldDefinition.h"
#import "DDFSubfieldDefinition.h"

@class DDFSubfieldDefinition;

/**
 * This object represents one field in a DDFRecord.  This
 * models an instance of the fields data, rather than it's data definition
 * which is handled by the DDFFieldDefinition class.  Note that a DDFField
 * doesn't have DDFSubfield children as you would expect.  To extract
 * subfield values use GetSubfieldData() to find the right data pointer and
 * then use ExtractIntData(), ExtractFloatData() or ExtractStringData().
 */
@interface DDFField: NSObject

//public:
-(void) Initialize: (DDFFieldDefinition *) poDefn
           pszData: (NSString *) pachDataIn
             nSize: (long) nDataSizeIn;

- (void) Initialize: (DDFField *) poField
            pszData: (NSString *) pachDataIn;

-(void) Dump: (FILE *) fp;

-(NSString *) GetSubfieldData: (DDFSubfieldDefinition *) poSFDefn
                     pnMaxBytes: (int *) pnMaxBytes// = NULL,
                 iSubfieldIndex: (int) iSubfieldIndex; // = 0;

-(NSString *) GetInstanceData: (int) nInstance
                         pnSize: (int *) pnInstanceSize;

  /**
   * Return the pointer to the entire data block for this record. This
   * is an internal copy, and shouldn't be freed by the application.
   */
  @property (NS_NONATOMIC_IOSONLY, readonly) NSString *GetData;

  /** Return the number of bytes in the data block returned by GetData(). */
  @property (NS_NONATOMIC_IOSONLY, readonly) long GetDataSize;

  @property (NS_NONATOMIC_IOSONLY, readonly) int GetRepeatCount;

  /** Fetch the corresponding DDFFieldDefinition. */
  @property (NS_NONATOMIC_IOSONLY, readonly, strong) DDFFieldDefinition *GetFieldDefn;

@end

#endif /* DDFField_h */
