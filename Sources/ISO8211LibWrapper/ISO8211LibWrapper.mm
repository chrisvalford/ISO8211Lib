//
//  ISO8211LibWrapper.mm
//  ISO8211Lib
//
//  Created by Christopher Alford on 27/7/22.
//

#import "ISO8211LibWrapper.h"
#import "CppCode.hpp"

CppClass cppObj;

@implementation ISO8211LibWrapper

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
