//
//  CppWrapper.h
//  ISO8211LibTester
//
//  Created by Christopher Alford on 27/7/22.
//

#import <Foundation/Foundation.h>

@interface ISO8211LibWrapper: NSObject
-(instancetype)init;
-(float) addition: (float) num1 : (float) num2;
-(float) subtraction: (float) num1 : (float) num2;
-(float) multiplication: (float) num1 : (float) num2;
-(float) division: (float) num1 : (float) num2;

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;
@end
