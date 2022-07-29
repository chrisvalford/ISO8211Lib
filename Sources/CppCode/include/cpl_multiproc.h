/**********************************************************************
 * $Id: cpl_multiproc.h,v 1.10 2006/01/25 19:52:25 fwarmerdam Exp $
 *
 * Project:  CPL - Common Portability Library
 * Purpose:  CPL Multi-Threading, and process handling portability functions.
*/

#ifndef _CPL_MULTIPROC_H_INCLUDED_
#define _CPL_MULTIPROC_H_INCLUDED_

#include "cpl_port.h"

// There are three primary implementations of the multi-process support
// controlled by one of CPL_MULTIPROC_WIN32, CPL_MULTIPROC_PTHREAD or
// CPL_MULTIPROC_STUB being defined.  If none are defined, the stub
// implementation will be used.

#if defined(WIN32) && !defined(CPL_MULTIPROC_STUB)
#  define CPL_MULTIPROC_WIN32
#endif

#if !defined(CPL_MULTIPROC_WIN32) && !defined(CPL_MULTIPROC_PTHREAD) \
 && !defined(CPL_MULTIPROC_STUB) && !defined(CPL_MULTIPROC_NONE)
#  define CPL_MULTIPROC_STUB
#endif

CPL_C_START

typedef void (*CPLThreadFunc)(void *);

void CPL_DLL *CPLLockFile( const char *pszPath, double dfWaitInSeconds );
void  CPL_DLL CPLUnlockFile( void *hLock );

void CPL_DLL *CPLCreateMutex();
int   CPL_DLL CPLCreateOrAcquireMutex( void **, double dfWaitInSeconds );
int   CPL_DLL CPLAcquireMutex( void *hMutex, double dfWaitInSeconds );
void  CPL_DLL CPLReleaseMutex( void *hMutex );
void  CPL_DLL CPLDestroyMutex( void *hMutex );

int   CPL_DLL CPLGetPID();
int   CPL_DLL CPLCreateThread( CPLThreadFunc pfnMain, void *pArg );
void  CPL_DLL CPLSleep( double dfWaitInSeconds );

const char CPL_DLL *CPLGetThreadingModel();

CPL_C_END

#ifdef __cplusplus

#define CPLMutexHolderD(x)  CPLMutexHolder oHolder(x,1000.0,__FILE__,__LINE__);

class CPLMutexHolder
{
  private:
    void       *hMutex;
    const char *pszFile;
    int         nLine;

  public:

    CPLMutexHolder( void **phMutex, double dfWaitInSeconds = 1000.0,
                    const char *pszFile = __FILE__,
                    int nLine = __LINE__ );
    ~CPLMutexHolder();
};
#endif /* def __cplusplus */

/* -------------------------------------------------------------------- */
/*      Thread local storage.                                           */
/* -------------------------------------------------------------------- */

#define CTLS_RLBUFFERINFO     		1         /* cpl_conv.cpp */
#define CTLS_DECDMSBUFFER               2	  /* cpl_conv.cpp */
#define CTLS_CSVTABLEPTR                3         /* cpl_csv.cpp */
#define CTLS_CSVDEFAULTFILENAME         4         /* cpl_csv.cpp */
#define CTLS_ERRORCONTEXT               5         /* cpl_error.cpp */
#define CTLS_FINDERINFO                 6         /* cpl_finder.cpp */
#define CTLS_PATHBUF                    7         /* cpl_path.cpp */
#define CTLS_SPRINTFBUF                 8         /* cpl_string.cpp */

#define CTLS_MAX                       32         

CPL_C_START
void CPL_DLL * CPLGetTLS( int nIndex );
void CPL_DLL CPLSetTLS( int nIndex, void *pData, int bFreeOnExit );
void CPL_DLL CPLCleanupTLS();
CPL_C_END

#endif /* _CPL_MULTIPROC_H_INCLUDED_ */
