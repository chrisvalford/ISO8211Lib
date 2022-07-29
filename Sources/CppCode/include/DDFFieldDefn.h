//
//  DDFFieldDefn.h
//  Lib
//
//  Created by Christopher Alford on 12/5/21.
//

#ifndef DDFFieldDefn_h
#define DDFFieldDefn_h

//#include "DDFSubfieldDefn.h"
//#include "DDFModule.h"
//#include "DDFSubfieldDefn.h"
#include "iso8211.hpp"

// Forward declarations
class DDFModule;
class DDFSubfieldDefn;

/************************************************************************/
/*                             DDFFieldDefn                             */
/************************************************************************/

  typedef enum { dsc_elementary, dsc_vector, dsc_array, dsc_concatenated } DDF_data_struct_code;
  typedef enum { dtc_char_string,
                 dtc_implicit_point,
                 dtc_explicit_point,
                 dtc_explicit_point_scaled,
                 dtc_char_bit_string,
                 dtc_bit_string,
                 dtc_mixed_data_type } DDF_data_type_code;

/**
 * Information from the DDR defining one field.  Note that just because
 * a field is defined for a DDFModule doesn't mean that it actually occurs
 * on any records in the module.  DDFFieldDefns are normally just significant
 * as containers of the DDFSubfieldDefns.
 */

class DDFFieldDefn
{
  public:
                DDFFieldDefn();
                ~DDFFieldDefn();

    int         Create( const char *pszTag, const char *pszFieldName,
                        const char *pszDescription,
                        DDF_data_struct_code eDataStructCode,
                        DDF_data_type_code   eDataTypeCode,
                        const char *pszFormat = NULL );
    void        AddSubfield( DDFSubfieldDefn *poNewSFDefn,
                             int bDontAddToFormat = false );
    void        AddSubfield( const char *pszName, const char *pszFormat );
    int         GenerateDDREntry( char **ppachData, int *pnLength );
                            
    int         Initialize( DDFModule * poModule, const char *pszTag,
                            int nSize, const char * pachRecord );
    
    void        Dump( FILE * fp );

    /** Fetch a pointer to the field name (tag).
     * @return this is an internal copy and shouldn't be freed.
     */
    const char  *GetName() { return pszTag; }

    /** Fetch a longer descriptio of this field.
     * @return this is an internal copy and shouldn't be freed.
     */
    const char  *GetDescription() { return _fieldName; }

    /** Get the number of subfields. */
    int         GetSubfieldCount() { return nSubfieldCount; }
    
    DDFSubfieldDefn *GetSubfield( int i );
    DDFSubfieldDefn *FindSubfieldDefn( const char * );

    /**
     * Get the width of this field.  This function isn't normally used
     * by applications.
     *
     * @return The width of the field in bytes, or zero if the field is not
     * apparently of a fixed width.
     */
    int         GetFixedWidth() { return nFixedWidth; }

    /**
     * Fetch repeating flag.
     * @see DDFField::GetRepeatCount()
     * @return TRUE if the field is marked as repeating.
     */
    int         IsRepeating() { return bRepeatingSubfields; }

    static char       *ExpandFormat( const char * );

    /** this is just for an S-57 hack for swedish data */
    void SetRepeatingFlag( int n ) { bRepeatingSubfields = n; }

    char        *GetDefaultValue( int *pnSize );
    
  private:

    static char       *ExtractSubstring( const char * );

    DDFModule * poModule;
    char *      pszTag;

    char *      _fieldName;
    char *      _arrayDescr;
    char *      _formatControls;

    int         bRepeatingSubfields;
    int         nFixedWidth;    // zero if variable.

    int         BuildSubfields();
    int         ApplyFormats();

    DDF_data_struct_code _data_struct_code;

    DDF_data_type_code   _data_type_code;

    int         nSubfieldCount;
    DDFSubfieldDefn **papoSubfields;
};

#endif /* DDFFieldDefn_h */
