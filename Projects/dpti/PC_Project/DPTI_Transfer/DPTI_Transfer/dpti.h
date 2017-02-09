/************************************************************************/
/*                                                                      */
/*  dpti.h  --      Interface Declarations for DPTI.DLL                 */
/*                                                                      */
/************************************************************************/
/*  Author: Michael T. Alexander                                        */
/*  Copyright 2011, Digilent Inc.                                       */
/************************************************************************/
/*  File Description:                                                   */
/*                                                                      */
/*  This header file contains the interface declarations for the API    */
/*  of the DPTI.DLL.  The DPTI DLL provides the implemention for the    */
/*  Digilent Parallel Data Transfer Interface. This interface is used   */
/*  to perform synchronous and asynchronous data transfer between the   */
/*  host and logic connected to the device.                             */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*  10/14/2011(MichaelA): created                                       */
/*  11/01/2011(MichaelA): added DptiSetChunkSize and DptiGetChunkSize   */
/*                                                                      */
/************************************************************************/

#if !defined(DPTI_INCLUDED)
#define      DPTI_INCLUDED

/* ------------------------------------------------------------ */
/*                  Miscellaneous Declarations                  */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*          GIO Port Properties Definitions                     */
/* ------------------------------------------------------------ */

/* Define the port property bits for PTI ports.
*/
const DPRP  dprpPtiAsynchronous     = 0x00000001; // port supports asynchronous parallel interface
const DPRP  dprpPtiSynchronous      = 0x00000002; // port supports synchronous parallel interface

/* ------------------------------------------------------------ */
/*                  General Type Declarations                   */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*                  Object Class Declarations                   */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*                  Variable Declarations                       */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*                  Procedure Declarations                      */
/* ------------------------------------------------------------ */

/* Basic interface functions.
*/
DPCAPI BOOL DptiGetVersion(char * szVersion);
DPCAPI BOOL DptiGetPortCount(HIF hif, INT32 * pcprt);
DPCAPI BOOL DptiGetPortProperties(HIF hif, INT32 prtReq, DWORD * pdprp); 
DPCAPI BOOL DptiEnable(HIF hif);
DPCAPI BOOL DptiEnableEx(HIF hif, INT32 prtReq);
DPCAPI BOOL DptiDisable(HIF hif);

/* Data transfer functions
*/
DPCAPI BOOL DptiIO(HIF hif, BYTE * pbOut, DWORD cbOut, BYTE * pbIn, DWORD cbIn, BOOL fOverlap);

/* Configuration functions
*/
DPCAPI BOOL DptiSetChunkSize(HIF hif, DWORD cbChunkOut, DWORD cbChunkIn);
DPCAPI BOOL DptiGetChunkSize(HIF hif, DWORD * pcbChunkOut, DWORD * pcbChunkIn);

/* ------------------------------------------------------------ */

#endif

/************************************************************************/
