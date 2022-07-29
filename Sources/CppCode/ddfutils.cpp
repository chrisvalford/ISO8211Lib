/******************************************************************************
 * $Id: ddfutils.cpp,v 1.7 2006/04/04 04:24:07 fwarmerdam Exp $
 *
 * Project:  ISO 8211 Access
 * Purpose:  Various utility functions.
 */

#include "iso8211.hpp"
#include "cpl_conv.h"

//CPL_CVSID("$Id: ddfutils.cpp,v 1.7 2006/04/04 04:24:07 fwarmerdam Exp $");

/************************************************************************/
/*                             DDFScanInt()                             */
/*                                                                      */
/*      Read up to nMaxChars from the passed string, and interpret      */
/*      as an integer.                                                  */
/************************************************************************/

long DDFScanInt( const char * pszString, int nMaxChars )

{
    char        szWorking[33];

    if( nMaxChars > 32 || nMaxChars == 0 )
        nMaxChars = 32;

    memcpy( szWorking, pszString, nMaxChars );
    szWorking[nMaxChars] = '\0';

    return( atoi(szWorking) );
}

/************************************************************************/
/*                          DDFScanVariable()                           */
/*                                                                      */
/*      Establish the length of a variable length string in a           */
/*      record.                                                         */
/************************************************************************/

int DDFScanVariable( const char *pszRecord, int nMaxChars, int nDelimChar )

{
    int         i;
    
    for( i = 0; i < nMaxChars-1 && pszRecord[i] != nDelimChar; i++ ) {}

    return i;
}

/************************************************************************/
/*                          DDFFetchVariable()                          */
/*                                                                      */
/*      Fetch a variable length string from a record, and allocate      */
/*      it as a new string (with CPLStrdup()).                          */
/************************************************************************/

char * DDFFetchVariable( const char *pszRecord, int nMaxChars,
                         int nDelimChar1, int nDelimChar2,
                         int *pnConsumedChars )

{
    int         i;
    char        *pszReturn;

    for( i = 0; i < nMaxChars-1 && pszRecord[i] != nDelimChar1
                                && pszRecord[i] != nDelimChar2; i++ ) {}

    *pnConsumedChars = i;
    if( i < nMaxChars
        && (pszRecord[i] == nDelimChar1 || pszRecord[i] == nDelimChar2) )
        (*pnConsumedChars)++;

    pszReturn = (char *) CPLMalloc(i+1);
    pszReturn[i] = '\0';
    strncpy( pszReturn, pszRecord, i );

    return pszReturn;
}
