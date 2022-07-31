//
//  DDFSubfieldDefinitionMM.h
//  
//
//  Created by Christopher Alford on 30/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDFSubfieldDefinitionMM: NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *format;
@property (nonatomic) UInt ddfIntValue;
@property (nonatomic) float ddfFloatValue;
@property (nonatomic, retain) NSString *ddfStringValue;
@end

NS_ASSUME_NONNULL_END
