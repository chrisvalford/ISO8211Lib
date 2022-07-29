//
//  DDFField.h
//  Lib
//
//  Created by Christopher Alford on 12/5/21.
//

#ifndef DDFField_h
#define DDFField_h

#include "DDFFieldDefn.h"
#include "DDFSubfieldDefn.h"

// Forward declarations
class DDFFieldDefn;

/************************************************************************/
/*                               DDFField                               */
/*                                                                      */
/*      This object represents one field in a DDFRecord.                */
/************************************************************************/

/**
 * This object represents one field in a DDFRecord.  This
 * models an instance of the fields data, rather than it's data definition
 * which is handled by the DDFFieldDefn class.  Note that a DDFField
 * doesn't have DDFSubfield children as you would expect.  To extract
 * subfield values use GetSubfieldData() to find the right data pointer and
 * then use ExtractIntData(), ExtractFloatData() or ExtractStringData().
 */

class DDFField
{
  public:
    void                Initialize( DDFFieldDefn *, const char *pszData,
                                    long nSize );

    void                Dump( FILE * fp );

    const char         *GetSubfieldData( DDFSubfieldDefn *,
                                         int * = NULL, int = 0 );

    const char         *GetInstanceData( int nInstance, int *pnSize );

    /**
     * Return the pointer to the entire data block for this record. This
     * is an internal copy, and shouldn't be freed by the application.
     */
    const char         *GetData() { return pachData; }

    /** Return the number of bytes in the data block returned by GetData(). */
    long                GetDataSize() { return nDataSize; }

    int                 GetRepeatCount();

    /** Fetch the corresponding DDFFieldDefn. */
    DDFFieldDefn        *GetFieldDefn() { return poDefn; }
    
  private:
    DDFFieldDefn        *poDefn;

    long                nDataSize;

    const char          *pachData;
};

#endif /* DDFField_h */
