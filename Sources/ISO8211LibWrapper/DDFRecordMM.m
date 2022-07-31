//
//  DDFRecordMM.m
//  
//
//  Created by Christopher Alford on 30/7/22.
//

#import <DDFRecordMM.h>

@implementation DDFRecordMM

-(instancetype)init {
    self = [super init];
    if (self) {
        _ddfFields = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
