//
//  Header.h
//  
//
//  Created by Christopher Alford on 30/7/22.
//

#import <Foundation/Foundation.h>
#import "DDFFieldDefinitionMM.h"

@interface DDFFieldMM: NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) DDFFieldDefinitionMM *fieldDefinition;
@property (nonatomic, retain) NSMutableArray *subfields;
@end

