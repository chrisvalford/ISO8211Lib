//
//  ISO8211LibWrapper.h
//  ISO8211LibTester
//
//  Created by Christopher Alford on 27/7/22.
//

#import <Foundation/Foundation.h>

#import "DDFFieldMM.h"
#import "DDFFieldDefinitionMM.h"
#import "DDFRecordMM.h"
#import "DDFSubfieldDefinitionMM.h"

@interface ISO8211LibWrapper: NSObject
-(instancetype)init;
-(instancetype)init: (NSString *) filePath;

-(DDFRecordMM *)readCatalog: (NSString *) filePath;

-(float) addition: (float) num1 : (float) num2;
-(float) subtraction: (float) num1 : (float) num2;
-(float) multiplication: (float) num1 : (float) num2;
-(float) division: (float) num1 : (float) num2;

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;
@end
