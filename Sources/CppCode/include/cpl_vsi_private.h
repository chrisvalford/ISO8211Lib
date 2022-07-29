/******************************************************************************
 * $Id: cpl_vsi_private.h,v 1.7 2006/03/27 15:24:41 fwarmerdam Exp $
 *
 * Project:  VSI Virtual File System
 * Purpose:  Private declarations for classes related to the virtual filesystem
 */

#ifndef CPL_VSI_VIRTUAL_H_INCLUDED
#define CPL_VSI_VIRTUAL_H_INCLUDED

#include "cpl_vsi.h"

#if defined(WIN32CE)
#  include "cpl_wince.h"
#  include <wce_errno.h>
#  pragma warning(disable:4786) /* Remove annoying warnings in eVC++ and VC++ 6.0 */
#endif

#include <map>
#include <vector>
#include <string>

/************************************************************************/
/*                           VSIVirtualHandle                           */
/************************************************************************/

class VSIVirtualHandle { 
  public:
    virtual int       Seek( vsi_l_offset nOffset, int nWhence ) = 0;
    virtual vsi_l_offset Tell() = 0;
    virtual size_t    Read( void *pBuffer, size_t nSize, size_t nMemb ) = 0;
    virtual size_t    Write( const void *pBuffer, size_t nSize,size_t nMemb)=0;
    virtual int       Eof() = 0;
    virtual int       Flush() {return 0;}
    virtual int       Close() = 0;
    virtual           ~VSIVirtualHandle() { }
};

/************************************************************************/
/*                         VSIFilesystemHandler                         */
/************************************************************************/

class VSIFilesystemHandler {

public:
    virtual VSIVirtualHandle *Open( const char *pszFilename, 
                                    const char *pszAccess) = 0;
    virtual int      Stat( const char *pszFilename, VSIStatBufL *pStatBuf) = 0;
    virtual int      Unlink( const char *pszFilename ) 
        		{ errno=ENOENT; return -1; }
    virtual int      Mkdir( const char *pszDirname, long nMode ) 
        		{ errno=ENOENT; return -1; }
    virtual int      Rmdir( const char *pszDirname ) 
			{ errno=ENOENT; return -1; }
    virtual char   **ReadDir( const char *pszDirname ) 
			{ return NULL; }
    virtual          ~VSIFilesystemHandler() {}
    virtual int      Rename( const char *oldpath, const char *newpath )
        		{ errno=ENOENT; return -1; }
};

/************************************************************************/
/*                            VSIFileManager                            */
/************************************************************************/

class VSIFileManager 
{
private:
    VSIFilesystemHandler         *poDefaultHandler;
    std::map<std::string,VSIFilesystemHandler *>   oHandlers;

    VSIFileManager();

    static VSIFileManager *Get();

public:
    ~VSIFileManager();

    static VSIFilesystemHandler *GetHandler( const char * );
    static void                InstallHandler( std::string osPrefix, 
                                               VSIFilesystemHandler * );
    static void                RemoveHandler( std::string osPrefix );
};

#endif /* ndef CPL_VSI_VIRTUAL_H_INCLUDED */
