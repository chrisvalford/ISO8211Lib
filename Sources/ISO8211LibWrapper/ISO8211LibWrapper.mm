//
//  ISO8211LibWrapper.mm
//  ISO8211Lib
//
//  Created by Christopher Alford on 27/7/22.
//

#import "ISO8211LibWrapper.h"
#import "CppCode.hpp"
#import "iso8211.hpp"

CppClass cppObj;
DDFModule moduleObj;

@interface ISO8211LibWrapper()
@property (nonatomic) NSString *filePath;
@end

@implementation ISO8211LibWrapper

-(instancetype)init {
    self = [super init];
    if(self) {
        return self;
    }
}

-(instancetype)init: (NSString *) filePath {
    self = [super init];
    if(self) {
        self.filePath = filePath;
        return self;
    }
}

-(BOOL)readCatalog: (NSString *) filePath {
    if (!moduleObj.Open([filePath UTF8String])) {
        return false;
    }
    // Loop reading records till there are none left.
    DDFRecord *poRecord;
    int iRecord = 0;
    
    while((poRecord = moduleObj.ReadRecord()) != NULL) {
        printf( "Record %d (%d bytes)\n", ++iRecord, poRecord->GetDataSize() );
        // Loop over each field in this particular record.
        for(int iField = 0; iField < poRecord->GetFieldCount(); iField++) {
            DDFField *poField = poRecord->GetField(iField);
            ViewRecordField(poField);
        }
    }
    return true;
}

/* **********************************************************************/
/*                          ViewRecordField()                           */
/*                                                                      */
/*      Dump the contents of a field instance in a record.              */
/* **********************************************************************/

static void ViewRecordField(DDFField * poField) {
    int         nBytesRemaining;
    const char  *pachFieldData;
    DDFFieldDefn *poFieldDefn = poField->GetFieldDefn();

    // Report general information about the field.
    printf( "    Field %s: %s\n",
            poFieldDefn->GetName(), poFieldDefn->GetDescription() );

    // Get pointer to this fields raw data.  We will move through
    // it consuming data as we report subfield values.

    pachFieldData = poField->GetData();
    nBytesRemaining = poField->GetDataSize();

    /* -------------------------------------------------------- */
    /*      Loop over the repeat count for this fields          */
    /*      subfields.  The repeat count will almost            */
    /*      always be one.                                      */
    /* -------------------------------------------------------- */
    int iRepeat;

    for(iRepeat = 0; iRepeat < poField->GetRepeatCount(); iRepeat++) {

        /* -------------------------------------------------------- */
        /*   Loop over all the subfields of this field, advancing   */
        /*   the data pointer as we consume data.                   */
        /* -------------------------------------------------------- */
        int iSF;
        for(iSF = 0; iSF < poFieldDefn->GetSubfieldCount(); iSF++) {
            DDFSubfieldDefn *poSFDefn = poFieldDefn->GetSubfield(iSF);
            int nBytesConsumed;
            nBytesConsumed = ViewSubfield(poSFDefn, pachFieldData, nBytesRemaining);
            nBytesRemaining -= nBytesConsumed;
            pachFieldData += nBytesConsumed;
        }
    }
}

/* **********************************************************************/
/*                            ViewSubfield()                            */
/* **********************************************************************/

static int ViewSubfield(DDFSubfieldDefn *poSFDefn,
                         const char * pachFieldData,
                         int nBytesRemaining) {
    int nBytesConsumed = 0;

    switch(poSFDefn->GetType()) {
      case DDFInt:
            if(poSFDefn->GetBinaryFormat() == DDFSubfieldDefn::UInt) {
                printf("        %s = %u\n",
                       poSFDefn->GetName(),
                       poSFDefn->ExtractIntData(pachFieldData, nBytesRemaining,
                                                &nBytesConsumed));
            } else {
                printf("        %s = %d\n",
                       poSFDefn->GetName(),
                       poSFDefn->ExtractIntData(pachFieldData, nBytesRemaining,
                                                &nBytesConsumed));
            }
        break;

      case DDFFloat:
        printf("        %s = %f\n",
                poSFDefn->GetName(),
                poSFDefn->ExtractFloatData(pachFieldData, nBytesRemaining,
                                            &nBytesConsumed));
        break;

      case DDFString:
        printf("        %s = `%s'\n",
                poSFDefn->GetName(),
                poSFDefn->ExtractStringData(pachFieldData, nBytesRemaining,
                                             &nBytesConsumed));
        break;

      case DDFBinaryString:
      {
          int i;
          //rjensen 19-Feb-2002 5 integer variables to decode NAME and LNAM
          int vrid_rcnm=0;
          int vrid_rcid=0;
          int foid_agen=0;
          int foid_find=0;
          int foid_fids=0;

          GByte *pabyBString = (GByte *) poSFDefn->ExtractStringData(pachFieldData, nBytesRemaining,
                                           &nBytesConsumed);

          printf("        %s = 0x", poSFDefn->GetName());
          for(i = 0; i < MIN(nBytesConsumed,24); i++) {
              printf("%02X", pabyBString[i]);
          }

          if(nBytesConsumed > 24) {
              printf("%s", "...");
          }

          // rjensen 19-Feb-2002 S57 quick hack. decode NAME and LNAM bitfields
          if (EQUAL(poSFDefn->GetName(),"NAME")) {
              vrid_rcnm=pabyBString[0];
              vrid_rcid=pabyBString[1] + (pabyBString[2]*256)+
                  (pabyBString[3]*65536)+ (pabyBString[4]*16777216);
              printf("\tVRID RCNM = %d,RCID = %u",vrid_rcnm,vrid_rcid);
          } else if (EQUAL(poSFDefn->GetName(),"LNAM")) {
              foid_agen=pabyBString[0] + (pabyBString[1]*256);
              foid_find=pabyBString[2] + (pabyBString[3]*256)+
                  (pabyBString[4]*65536)+ (pabyBString[5]*16777216);
              foid_fids=pabyBString[6] + (pabyBString[7]*256);
              printf("\tFOID AGEN = %u,FIDN = %u,FIDS = %u",
                     foid_agen,foid_find,foid_fids);
          }
          printf("\n");
      }
      break;
    }
    return nBytesConsumed;
}


-(float) addition: (float) num1 : (float) num2 {
    return cppObj.addition(num1, num2);
}

-(float) subtraction: (float) num1 : (float) num2 {
    return cppObj.subtraction(num1, num2);
}

-(float) multiplication: (float) num1 : (float) num2 {
    return cppObj.multiplication(num1, num2);
}

-(float) division: (float) num1 : (float) num2 {
    if (num2 == 0) {
        [NSException raise:@"Invalid value" format:@"You cannot divide by zero"];
    }
    return cppObj.division(num1, num2);
}

// TODO: Is this the correct way of converting OBJC exceptions?
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
