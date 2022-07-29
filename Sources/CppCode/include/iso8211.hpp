/*
 * Project:  ISO 8211 Access
 * Purpose:  Main declarations for ISO 8211.
 */



#ifndef _ISO8211_H_INCLUDED
#define _ISO8211_H_INCLUDED

#include "DDFModule.h"
#include "DDFRecord.h"
#include "DDFField.h"
#include "DDFFieldDefn.h"
#include "DDFSubfieldDefn.h"

#include "cpl_port.h"

  
/************************************************************************/
/*      These should really be private to the library ... they are      */
/*      mostly conveniences.                                            */
/************************************************************************/

long CPL_ODLL DDFScanInt( const char *pszString, int nMaxChars );
int  CPL_ODLL DDFScanVariable( const char * pszString, int nMaxChars, int nDelimChar );
char CPL_ODLL *DDFFetchVariable( const char *pszString, int nMaxChars,
                        int nDelimChar1, int nDelimChar2,
                        int *pnConsumedChars );

#define DDF_FIELD_TERMINATOR    30
#define DDF_UNIT_TERMINATOR     31

#endif /* ndef _ISO8211_H_INCLUDED */
