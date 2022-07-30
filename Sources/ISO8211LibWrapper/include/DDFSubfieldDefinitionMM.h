//
//  NSObject+DDFSubfieldDefinitionMM.h
//  
//
//  Created by Christopher Alford on 30/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDFSubfieldDefinitionMM: NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *format;
@property (nonatomic) UInt ddfIntValue;
@property (nonatomic) float ddfFloatValue;
@property (nonatomic) NSString *ddfStringValue;
@end

NS_ASSUME_NONNULL_END
