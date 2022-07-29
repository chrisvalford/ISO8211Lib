//
//  DDFModule.h
//  Lib
//
//  Created by Christopher Alford on 12/5/21.
//

#ifndef DDFModule_h
#define DDFModule_h

#include "iso8211.hpp"
#include <stdio.h>

// Forward declarations
class DDFRecord;
class DDFFieldDefn;

/************************************************************************/
/*                              DDFModule                               */
/************************************************************************/

/**
  The primary class for reading ISO 8211 files.  This class contains all
  the information read from the DDR record, and is used to read records
  from the file.

*/

class DDFModule
{
  public:
                DDFModule();
                ~DDFModule();
                
    int         Open( const char * pszFilename, int bFailQuietly = false );
    int         Create( const char *pszFilename );
    void        Close();

    int         Initialize( char chInterchangeLevel = '3',
                            char chLeaderIden = 'L',
                            char chCodeExtensionIndicator = 'E',
                            char chVersionNumber = '1',
                            char chAppIndicator = ' ',
                            const char *pszExtendedCharSet = " ! ",
                            int nSizeFieldLength = 3,
                            int nSizeFieldPos = 4,
                            int nSizeFieldTag = 4 );

    void        Dump( FILE * fp );

    DDFRecord   *ReadRecord( void );
    void        Rewind( long nOffset = -1 );

    DDFFieldDefn *FindFieldDefn( const char * );

    /** Fetch the number of defined fields. */

    int         GetFieldCount() { return nFieldDefnCount; }
    DDFFieldDefn *GetField(int);
    void        AddField( DDFFieldDefn *poNewFDefn );
    
    // This is really just for internal use.
    int         GetFieldControlLength() { return _fieldControlLength; }
    void        AddCloneRecord( DDFRecord * );
    void        RemoveCloneRecord( DDFRecord * );
    
    // This is just for DDFRecord.
    FILE        *GetFP() { return fpDDF; }
    
  private:
    FILE        *fpDDF;
    int         bReadOnly;
    long        nFirstRecordOffset;

    char        _interchangeLevel;
    char        _inlineCodeExtensionIndicator;
    char        _versionNumber;
    char        _appIndicator;
    int         _fieldControlLength;
    char        _extendedCharSet[4];

    long _recLength;
    char _leaderIden;
    long _fieldAreaStart;
    long _sizeFieldLength;
    long _sizeFieldPos;
    long _sizeFieldTag;

    // One DirEntry per field.
    int         nFieldDefnCount;
    DDFFieldDefn **papoFieldDefns;

    DDFRecord   *poRecord;

    int         nCloneCount;
    int         nMaxCloneCount;
    DDFRecord   **papoClones;
}; // end of DDFModule

#endif /* DDFModule_h */
