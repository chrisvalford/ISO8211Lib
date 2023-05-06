//
//  DDFUtils.h
//  ISO8211Lib
//
//  Created by Christopher Alford on 9/4/23.
//

#ifndef DDFUtils_h
#define DDFUtils_h

#import <Foundation/Foundation.h>

@interface DDFUtils: NSObject

/**
 *      Read up to nMaxChars from the passed string, and interpret
 *      as an integer.
 *
 *  - Parameters:
 *      - pszString: The string containing the int.
 *      - nMaxChars: The maximum number of characters to read.
 *  - Returns: The int value
 */
+(long) DDFScanInt: (const char *) pszString
         nMaxChars: (int) nMaxChars;

/**
*      Establish the length of a variable length string in a record.
 * - Parameters:
 *      - pszRecord: The record containing the variable.
 *      - nMaxChars: The maximum number of characters to read.
 *      - nDelimChar: The delimiter character.
 *  - Returns: The variables length
*/
+(int) DDFScanVariable: (const char *) pszRecord
             nMaxChars: (int) nMaxChars
            nDelimChar: (int) nDelimChar;

/**
 * Fetch a variable length string from a record, and allocate
 * it as a new string (with CPLStrdup()).
 *
 * - Parameters:
 *      - pszRecord: The record containing the variable.
 *      - nMaxChars: The maximum number of characters to read.
 *      - nDelimChar1: The first delimiter character.
 *      - nDelimChar2: The second delimiter character.
 *      - pnConsumedChars: The number of characters tested
 *  - Returns: A string
 */

+(NSString *) DDFFetchVariable: (const char *)pszRecord
                 nMaxChars: (int) nMaxChars
               nDelimChar1: (int) nDelimChar1
               nDelimChar2: (int) nDelimChar2
           pnConsumedChars: (int *)pnConsumedChars;

@end

#endif /* DDFUtils_h */
