//
//  DDFFieldDefinitionMM.m
//  
//
//  Created by Christopher Alford on 30/7/22.
//

#import <DDFFieldDefinitionMM.h>

@implementation DDFFieldDefinitionMM

-(instancetype)init {
    self = [super init];
    if (self) {
        _subfields = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
