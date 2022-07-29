//
//  DDFRecord.h
//  Lib
//
//  Created by Christopher Alford on 12/5/21.
//

#ifndef DDFRecord_h
#define DDFRecord_h


// Forward declarations
class DDFModule;
class DDFField;
class DDFFieldDefn;

/************************************************************************/
/*                              DDFRecord                               */
/*                                                                      */
/*      Class that contains one DR record from a file.  We read into    */
/*      the same record object repeatedly to ensure that repeated       */
/*      leaders can be easily preserved.                                */
/************************************************************************/

/**
 * Contains instance data from one data record (DR).  The data is contained
 * as a list of DDFField instances partitioning the raw data into fields.
 */


class DDFRecord
{
  public:
                DDFRecord( DDFModule * );
                ~DDFRecord();

    DDFRecord  *Clone();
    DDFRecord  *CloneOn( DDFModule * );
    
    void        Dump( FILE * );

    /** Get the number of DDFFields on this record. */
    int         GetFieldCount() { return nFieldCount; }

    DDFField    *FindField( const char *, int = 0 );
    DDFField    *GetField( int );

    int         GetIntSubfield( const char *, int, const char *, int,
                                int * = NULL );
    double      GetFloatSubfield( const char *, int, const char *, int,
                                  int * = NULL );
    const char *GetStringSubfield( const char *, int, const char *, int,
                                   int * = NULL );

    int         SetIntSubfield( const char *pszField, int iFieldIndex,
                                const char *pszSubfield, int iSubfieldIndex,
                                int nValue );
    int         SetStringSubfield( const char *pszField, int iFieldIndex,
                                   const char *pszSubfield, int iSubfieldIndex,
                                   const char *pszValue, int nValueLength=-1 );
    int         SetFloatSubfield( const char *pszField, int iFieldIndex,
                                  const char *pszSubfield, int iSubfieldIndex,
                                  double dfNewValue );

    /** Fetch size of records raw data (GetData()) in bytes. */
    int         GetDataSize() { return nDataSize; }

    /**
     * Fetch the raw data for this record.  The returned pointer is effectively
     * to the data for the first field of the record, and is of size
     * GetDataSize().
     */
    const char  *GetData() { return pachData; }

    /**
     * Fetch the DDFModule with which this record is associated.
     */

    DDFModule * GetModule() { return poModule; }

    int ResizeField( DDFField *poField, int nNewDataSize );
    int DeleteField( DDFField *poField );
    DDFField* AddField( DDFFieldDefn * );

    int CreateDefaultFieldInstance( DDFField *poField, int iIndexWithinField );

    int SetFieldRaw( DDFField *poField, int iIndexWithinField,
                     const char *pachRawData, int nRawDataSize );
    int UpdateFieldRaw( DDFField *poField, int iIndexWithinField,
                        int nStartOffset, int nOldSize,
                        const char *pachRawData, int nRawDataSize );

    int         Write();
    
    // This is really just for the DDFModule class.
    int         Read();
    void        Clear();
    int         ResetDirectory();
    
  private:

    int         ReadHeader();
    
    DDFModule   *poModule;

    int         nReuseHeader;

    int         nFieldOffset;   // field data area, not dir entries.

    int         _sizeFieldTag;
    int         _sizeFieldPos;
    int         _sizeFieldLength;

    int         nDataSize;      // Whole record except leader with header
    char        *pachData;

    int         nFieldCount;
    DDFField    *paoFields;

    int         bIsClone;
};
#endif /* DDFRecord_h */
