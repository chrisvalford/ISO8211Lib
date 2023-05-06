//
//  ISO8211.h
//  ISO8211Lib
//
//  Created by Christopher Alford on 9/4/23.
//

#ifndef ISO8211_h
#define ISO8211_h

#import "DDFField.h"
#import "DDFModule.h"
#import "DDFRecord.h"
#import "DDFSubfieldDefinition.h"

#define DDF_FIELD_TERMINATOR    30
#define DDF_UNIT_TERMINATOR     31

static const int nLeaderSize = 24;

#if UINT_MAX == 65535
typedef long            GInt32;
typedef unsigned long   GUInt32;
#else
typedef int             GInt32;
typedef unsigned int    GUInt32;
#endif

typedef short           GInt16;
typedef unsigned short  GUInt16;
typedef unsigned char   GByte;
typedef int             GBool;

#endif /* ISO8211_h */
