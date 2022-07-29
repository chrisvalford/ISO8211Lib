//
//  DDFSubfieldDefn.h
//  Lib
//
//  Created by Christopher Alford on 12/5/21.
//

#ifndef DDFSubfieldDefn_h
#define DDFSubfieldDefn_h

#include "iso8211.hpp"

/**
  General data type
    */
typedef enum {
    DDFInt,
    DDFFloat,
    DDFString,
    DDFBinaryString
} DDFDataType;

/************************************************************************/
/*      DDFSubfieldDefn     */
/*  Information from the DDR record for one subfield of a   */
/*  particular field.   */
/************************************************************************/

/**
 * Information from the DDR record describing one subfield of a DDFFieldDefn.
 * All subfields of a field will occur in each occurance of that field
 * (as a DDFField) in a DDFRecord.  Subfield's actually contain formatted
 * data (as instances within a record).
 */

class DDFSubfieldDefn
{
public:

                DDFSubfieldDefn();
                ~DDFSubfieldDefn();

    void        SetName( const char * pszName );

    /** Get pointer to subfield name. */
    const char  *GetName() { return pszName; }
    
    /** Get pointer to subfield format string */
    const char  *GetFormat() { return pszFormatString; }
    int         SetFormat( const char * pszFormat );

    /**
     * Get the general type of the subfield.  This can be used to
     * determine which of ExtractFloatData(), ExtractIntData() or
     * ExtractStringData() should be used.
     * @return The subfield type.  One of DDFInt, DDFFloat, DDFString or
     * DDFBinaryString.
     */
      
    DDFDataType GetType() { return eType; }

    double      ExtractFloatData( const char *pachData, int nMaxBytes,
                                  int * pnConsumedBytes );
    int         ExtractIntData( const char *pachData, int nMaxBytes,
                                int * pnConsumedBytes );
    const char  *ExtractStringData( const char *pachData, int nMaxBytes,
                                    int * pnConsumedBytes );
    int         GetDataLength( const char *, int, int * );
    void        DumpData( const char *pachData, int nMaxBytes, FILE * fp );

    int         FormatStringValue( char *pachData, int nBytesAvailable,
                                   int *pnBytesUsed, const char *pszValue,
                                   int nValueLength = -1 );

    int         FormatIntValue( char *pachData, int nBytesAvailable,
                                int *pnBytesUsed, int nNewValue );

    int         FormatFloatValue( char *pachData, int nBytesAvailable,
                                  int *pnBytesUsed, double dfNewValue );

    /** Get the subfield width (zero for variable). */
    int         GetWidth() { return nFormatWidth; } // zero for variable.

    int         GetDefaultValue( char *pachData, int nBytesAvailable,
                                 int *pnBytesUsed );
    
    void        Dump( FILE * fp );

/**
  Binary format: this is the digit immediately following the B or b for
  binary formats.
  */
typedef enum {
    NotBinary=0,
    UInt=1,
    SInt=2,
    FPReal=3,
    FloatReal=4,
    FloatComplex=5
} DDFBinaryFormat;

    DDFBinaryFormat GetBinaryFormat(void) const { return eBinaryFormat; }
    

private:

  char      *pszName;   // a.k.a. subfield mnemonic
  char      *pszFormatString;

  DDFDataType           eType;
  DDFBinaryFormat       eBinaryFormat;

/* -------------------------------------------------------------------- */
/*      bIsVariable determines whether we using the                     */
/*      chFormatDelimeter (TRUE), or the fixed width (FALSE).           */
/* -------------------------------------------------------------------- */
  int        bIsVariable;
  
  char       chFormatDelimeter;
  int        nFormatWidth;

/* -------------------------------------------------------------------- */
/*      Fetched string cache.  This is where we hold the values         */
/*      returned from ExtractStringData().                              */
/* -------------------------------------------------------------------- */
  int        nMaxBufChars;
  char       *pachBuffer;
};

#endif /* DDFSubfieldDefn_h */
