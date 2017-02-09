/************************************************************************/
/*                                                                      */
/*    dpcdecl.h  --    Declarations for shared Adept 2 definitions      */
/*                                                                      */
/************************************************************************/
/*    Author: Joshua Pederson                                           */
/*    Copyright 2007 Digilent Inc.                                      */
/************************************************************************/
/*  File Description:                                                   */
/*                                                                      */
/*      This file contains shared declarations for Adept 2              */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*  05/09/2007(JPederson): Created                                      */
/*  03/18/2008(GeneA): cleaned up formatting and added comments         */
/*  02/10/2010(MichaelA): modified to be cross platform compatible      */
/*  02/24/2010(GeneA): renamed all symbols related to DevName to be     */
/*      ProdName instead.                                               */
/*  01/10/2011(MichaelA): added declaration and definition of transport */
/*      types and protocols                                             */
/*  04/23/2012(MichaelA): modified Linux definition of DPCAPI and       */
/*      DPCPPAPI to no longer include a symbol visibility setting       */
/*  04/19/2013(MichaelA): changed the way that some constants are       */
/*      defined so that they may be used as initializers in C           */
/*      applications                                                    */
/*                                                                      */
/************************************************************************/

#if !defined(DPCDECL_INCLUDED)
#define    DPCDECL_INCLUDED

#if !defined(WIN32)
    #include <stdint.h>
#endif

#if !defined(DPCAPI)

    #if defined(WIN32)
        
        #if defined(__cplusplus)
            #define DPCAPI extern "C" __declspec(dllimport)
        #else
            #define DPCAPI __declspec(dllimport)
        #endif
        
    #else
        
        #if defined(__cplusplus)
            #define DPCAPI extern "C"
        #else
            #define DPCAPI
        #endif
        
    #endif
    
#endif

#if !defined(DPCPPAPI)

    #if defined(WIN32)
        #define DPCPPAPI __declspec(dllimport)
    #else
        #define DPCPPAPI
    #endif
    
#endif

/* ------------------------------------------------------------ */
/*                Miscellaneous Declarations                    */
/* ------------------------------------------------------------ */

#if !defined(MAX_PATH)
    #define MAX_PATH    260 // this is the current windows definition
#endif

#define	LOCAL
#define	GLOBAL

/* ------------------------------------------------------------ */
/*                  Common Type Definitions                     */
/* ------------------------------------------------------------ */

#if defined(__cplusplus)
    const bool fFalse = false;
    const bool fTrue = true;
#else
    #define	fFalse  0
    #define	fTrue   (!fFalse)
#endif

#if defined(WIN32)

    typedef	unsigned char   BYTE;
    typedef	unsigned short  WORD;
    typedef	unsigned long   DWORD;
    typedef	unsigned long   ULONG;
    typedef unsigned short  USHORT;
    typedef int             BOOL;
    
#else

    typedef signed short    INT16;
    typedef unsigned short  UINT16;
    typedef int32_t         INT32;
    typedef uint32_t        UINT32;
    typedef int64_t         INT64;
    typedef uint64_t        UINT64;
    typedef	unsigned char   BYTE;
    typedef	unsigned short  WORD;
    typedef UINT32          DWORD;
    typedef	unsigned long   ULONG;
    typedef unsigned short  USHORT;
    typedef int             BOOL;
    
    typedef char            CHAR;
    typedef unsigned char   UCHAR;
    typedef CHAR*           PCHAR;
    typedef short           SHORT;
    
    typedef DWORD           HANDLE;
    
    typedef char            TCHAR;
    
#endif

/* ------------------------------------------------------------ */
/*                General Type Declarations                     */
/* ------------------------------------------------------------ */

/* These symbols define the maximum allowed length for various
** strings used by the interfaces.
*/
#define cchAliasMax     16  //max length of device table alias string
#define cchUsrNameMax   16  //max length of user settable device name
#define cchProdNameMax  28  //max length of product name string
#define cchSnMax        15  //length of a serial number string
#define cchVersionMax   256 //max length returned for DLL version string
#define cchDvcNameMax   64  //size of name field in DVC structure
#define cchDtpStringMax 16  //maximum length of DTP name string
#define cchErcMax       48  //maximum length of error code symbolic name
#define cchErcMsgMax    128 //maximum length of error message descriptive string

/* The device management capabilities value indicates which device
** management function sets are supported by the device. Device
** management function sets apply to a device as a whole. For example,
** the mgtcapPower capability indicates that the device supports the
** power on/off capability.
*/
typedef DWORD   MGTCAP; // management capabilities 

/* The device interface capabilties value indicates which interface types
** are supported by the device or being requested by the application.
*/
typedef DWORD   DCAP;   //capabilities bitfield

const   DCAP    dcapJtag    = 0x00000001; //this symbol is deprecated
const   DCAP    dcapJtg     = 0x00000001;
const   DCAP    dcapPio     = 0x00000002;
const   DCAP    dcapEpp     = 0x00000004;
const   DCAP    dcapStm     = 0x00000008;
const   DCAP    dcapSpi     = 0x00000010;
const   DCAP    dcapTwi     = 0x00000020;
const   DCAP    dcapAci     = 0x00000040;
const   DCAP    dcapAio     = 0x00000080;
const   DCAP    dcapEmc     = 0x00000100;
const   DCAP    dcapDci     = 0x00000200;
const   DCAP    dcapGio     = 0x00000400;
const   DCAP    dcapPti     = 0x00000800;

const   DCAP    dcapAll     = 0xFFFFFFFF;

/* The port properties values are used by each protocol type to
** indicate details about the features supported by each individual
** port. The type is declared here. The properties values are
** defined in the protocol specific header files.
*/
typedef DWORD DPRP;

/* Device type indicates which physical transport and protocol are used to
** access the device. The lower 16 bits are interpretted as a bitfield that
** is used to specify the type of transport used by the device. The upper
** 16 bits are interpretted as the protocol used to communicate with a
** device of the specified transport type. Please note that specification
** of the protocol is optional and if no protocol is specified then
** communication with all devices of a particular transport type will be
** attempted.
*/
typedef DWORD DTP;

const DTP dtpUSB        = 0x00000001;
const DTP dtpEthernet   = 0x00000002;
const DTP dtpParallel   = 0x00000004;
const DTP dtpSerial     = 0x00000008;

const DTP dtpNone       = 0x00000000;
const DTP dtpAll        = 0xFFFFFFFF;
const DTP dtpNil        = 0;

typedef WORD TPT;

const TPT tptUSB        = 0x0001;
const TPT tptEthernet   = 0x0002;
const TPT tptParallel   = 0x0004;
const TPT tptSerial     = 0x0008;

const TPT tptNone       = 0x0000;
const TPT tptAll        = 0xFFFF;
const TPT tptNil        = 0x0000;

typedef WORD PTC;

const PTC ptcProtocol1  = 0x0001;
const PTC ptcProtocol2  = 0x0002;
const PTC ptcProtocol3  = 0x0004;
const PTC ptcProtocol4  = 0x0008;

const PTC ptcProtocol5  = 0x0010;
const PTC ptcProtocol6  = 0x0020;
const PTC ptcProtocol7  = 0x0040;
const PTC ptcProtocol8  = 0x0080;

const PTC ptcProtocol9  = 0x0100;
const PTC ptcProtocol10 = 0x0200;
const PTC ptcProtocol11 = 0x0400;
const PTC ptcProtocol12 = 0x0800;

const PTC ptcProtocol13 = 0x1000;
const PTC ptcProtocol14 = 0x2000;
const PTC ptcProtocol15 = 0x4000;
const PTC ptcProtocol16 = 0x8000;

const PTC ptcAll        = 0x0000;
const PTC ptcNil        = 0x0000;

#define TptFromDtp(dtp)             ((TPT)(dtp & 0xFFFF))
#define PtcFromDtp(dtp)             ((PTC)((dtp >> 16) & 0xFFFF))
#define DtpFromTptPtc(tpt, ptc)     ((DTP)(tpt) | ((DTP)ptc << 16))

/* Device interface handle.
*/
typedef DWORD HIF;
#define hifInvalid  0

/* These values are used to report various attributes of a device.
*/
typedef DWORD   PDID;       // device product id
typedef WORD    FWTYPE;
typedef WORD    FWVER;      // device firmware version number
typedef BYTE    FWID;       // device firmware identifier

#define ProductFromPdid(pdid)   ((pdid >> 20) & 0xFFF)
#define VariantFromPdid(pdid)   ((pdid >> 8 ) & 0xFFF)
#define FwidFromPdid(pdid)      ((FWID)(pdid & 0xFF))

/* These values are used to retrieve or set various information about
** a device.
*/
typedef DWORD DINFO;

// public
const DINFO dinfoNone       = 0;
const DINFO dinfoAlias      = 1;
const DINFO dinfoUsrName    = 2;
const DINFO dinfoProdName   = 3;
const DINFO dinfoPDID       = 4;
const DINFO dinfoSN         = 5;
const DINFO dinfoIP         = 6;
const DINFO dinfoMAC        = 7;        //Ethernet MAC and SN are the same
const DINFO dinfoDCAP       = 9;
const DINFO dinfoSerParam   = 10;
const DINFO dinfoParAddr    = 11;
const DINFO dinfoUsbPath    = 12;
const DINFO dinfoProdID     = 13;      // the ProductID from PDID
const DINFO dinfoOpenCount  = 14;   // how many times a device is opened
const DINFO dinfoFWVER      = 15;
 
/* Error codes
*/
typedef int ERC ;                           
                            
const   ERC ercNoErc                    = 0;    //  No error occurred
                            
// The following error codes can be directly mapped to the device error codes.
const   ERC ercNotSupported             = 1;    //  Capability or function not supported by the device
const   ERC ercTransferCancelled        = 2;    //  The transfer was cancelled or timeout occured
const   ERC ercCapabilityConflict       = 3;    //  Tried to enable capabilities that use shared resources, check device datasheet
const   ERC ercCapabilityNotEnabled     = 4;    //  The protocol is not enabled
const   ERC ercEppAddressTimeout        = 5;    //  EPP Address strobe timeout
const   ERC ercEppDataTimeout           = 6;    //  EPP Data strobe timeout
const   ERC ercDataSndLess              = 7;    //  Data send failed or peripheral did not received all the sent data
const   ERC ercDataRcvLess              = 8;    //  Data receive failed or peripheral sent less data
const   ERC ercDataRcvMore              = 9;    //  Peripheral sent more data
const   ERC ercDataSndLessRcvLess       = 10;   //  Two errors: ercDataSndLess and ercDataRcvLess
const   ERC ercDataSndLessRcvMore       = 11;   //  Two errors: ercDataSndLess and ercDataSndFailRcvMore
const   ERC ercInvalidPort              = 12;   //  Attempt to enable port when another port is already enabled
const   ERC ercBadParameter             = 13;   //  Command parameter out of range

// ACI error codes, directly mapped to device error codes.
const   ERC ercAciFifoFull              = 0x20; //  Transmit FIFO overflow

// TWI error codes, directly mapped to device error codes.
const   ERC ercTwiBadBatchCmd           = 0x20; //  Bad command in TWI batch buffer
const   ERC ercTwiBusBusy               = 0x21; //  Timed out waiting for TWI bus
const   ERC ercTwiAdrNak                = 0x22; //  TWI address not ack'd
const   ERC ercTwiDataNak               = 0x23; //  TWI data not ack'd
const   ERC ercTwiSmbPecError           = 0x24; //  Packet error when using packet error checking

// Most likely the user did something wrong.
const   ERC ercAlreadyOpened            = 1024; //  Device already opened
const   ERC ercInvalidHif               = 1025; //  Invalid interface handle provided, fist call DmgrOpen(Ex)
const   ERC ercInvalidParameter         = 1026; //  Invalid parameter sent in API call
const   ERC ercTransferPending          = 1031; //  The last API called in overlapped mode was not finished. Use DmgrGetTransStat or DmgrCancelTrans
const   ERC ercApiLockTimeout           = 1032; //  API waiting on pending API timed out
const   ERC ercPortConflict             = 1033; //  Attempt to enable port when another port is already enabled

// Not the user's fault.
const   ERC ercConnectionFailed         = 3072; //  Unknown fail of connection
const   ERC ercControlTransferFailed    = 3075; //  Control transfer failed
const   ERC ercCmdSendFailed            = 3076; //  Command sending failed
const   ERC ercStsReceiveFailed         = 3077; //  Status receiving failed
const   ERC ercInsufficientResources    = 3078; //  Memory allocation failed, insufficient system resources
const   ERC ercInvalidTFP               = 3079; //  Internal protocol error, DVT rejected the transfer strcuture sent by public API
const   ERC ercInternalError            = 3080; //  Internal error
const   ERC ercTooManyOpenedDevices     = 3081; //  Internal error
const   ERC ercConfigFileError          = 3082; //  Processing of configuration file failed
const   ERC ercDeviceNotConnected       = 3083; //  Device not connected

const   ERC ercEnumNotFree              = 3084; //  Device Enumeration failed because another enumeration is still running.
const   ERC ercEnumFreeFail             = 3085; //  Device Enumeration list could not be freed

const   ERC ercInvalidDevice            = 3086; //  OEM ID check failed

const   ERC ercDeviceBusy               = 3087; //  The device is currently claimed by another process.

const   ERC ercCorruptInstallation      = 3088; //  One or more critical file is missing from the system.

//ENUM errors

//DVTBL errors

/* ------------------------------------------------------------ */
/*                  Data Structure Declarations                 */
/* ------------------------------------------------------------ */

#pragma pack(16)
typedef struct tagDVC{
    
    char        szName[cchDvcNameMax];
            //in dvctable:  Alias
            //not in dvctable:  user assigned name in device
            //not in dvctable, no user defined name:  device type with identifier

    char        szConn[MAX_PATH+1];
            //in dvctable:  connection string in dvctable
            //not in dvctable:  USB:   PATHNAME
            //                  Eth:    IP:192.168.1.1
            //                  Ser:    COM1:9600,N,8,1
            //                  EPP:    EPP:0x378
    DTP     dtp;

} DVC;
#pragma pack()

/* ------------------------------------------------------------ */
/*                  Variable Declarations                       */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*                  Procedure Declarations                      */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */

#endif

/************************************************************************/
