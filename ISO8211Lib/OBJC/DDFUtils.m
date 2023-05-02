//
//  DDFUtils.m
//  Lib
//
//  Created by Christopher Alford on 9/4/23.
//

#import <Foundation/Foundation.h>
#import "DDFUtils.h"

@implementation DDFUtils

+(long) DDFScanInt: (const char *) pszString
         nMaxChars: (int) nMaxChars {
    char szWorking[33];

    if(nMaxChars > 32 || nMaxChars == 0) {
        nMaxChars = 32;
    }

    memcpy(szWorking, pszString, nMaxChars);
    szWorking[nMaxChars] = '\0';
    return(atoi(szWorking));
}

+(int) DDFScanVariable: (const char *) pszRecord
             nMaxChars: (int) nMaxChars
            nDelimChar: (int) nDelimChar {
    int i;
    
    for(i = 0; i < nMaxChars-1 && pszRecord[i] != nDelimChar; i++ ) {}
    return i;
}

+(NSString *) DDFFetchVariable: (const char *)pszRecord
                 nMaxChars: (int) nMaxChars
               nDelimChar1: (int) nDelimChar1
               nDelimChar2: (int) nDelimChar2
           pnConsumedChars: (int *)pnConsumedChars {
    int i;
    char *pszReturn;

    for(i = 0; i < nMaxChars-1 && pszRecord[i] != nDelimChar1 && pszRecord[i] != nDelimChar2; i++ ) {}

    *pnConsumedChars = i;
    if(i < nMaxChars
        && (pszRecord[i] == nDelimChar1 || pszRecord[i] == nDelimChar2) )
        (*pnConsumedChars)++;

    pszReturn = (char *) malloc(i+1);
    pszReturn[i] = '\0';
    strncpy(pszReturn, pszRecord, i);
    return [NSString stringWithCString: pszReturn encoding: NSUTF8StringEncoding];
}

@end
