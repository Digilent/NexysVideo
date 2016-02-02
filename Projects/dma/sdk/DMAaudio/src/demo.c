/******************************************************************************
*
* (c) Copyright 2010-2013 Xilinx, Inc. All rights reserved.
*
* This file contains confidential and proprietary information of Xilinx, Inc.
* and is protected under U.S. and international copyright and other
* intellectual property laws.
*
* DISCLAIMER
* This disclaimer is not a license and does not grant any rights to the
* materials distributed herewith. Except as otherwise provided in a valid
* license issued to you by Xilinx, and to the maximum extent permitted by
* applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
* FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
* IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
* MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
* and (2) Xilinx shall not be liable (whether in contract or tort, including
* negligence, or under any other theory of liability) for any loss or damage
* of any kind or nature related to, arising under or in connection with these
* materials, including for any direct, or any indirect, special, incidental,
* or consequential loss or damage (including loss of data, profits, goodwill,
* or any type of loss or damage suffered as a result of any action brought by
* a third party) even if such damage or loss was reasonably foreseeable or
* Xilinx had been advised of the possibility of the same.
*
* CRITICAL APPLICATIONS
* Xilinx products are not designed or intended to be fail-safe, or for use in
* any application requiring fail-safe performance, such as life-support or
* safety devices or systems, Class III medical devices, nuclear facilities,
* applications related to the deployment of airbags, or any other applications
* that could lead to death, personal injury, or severe property or
* environmental damage (individually and collectively, "Critical
* Applications"). Customer assumes the sole risk and liability of any use of
* Xilinx products in Critical Applications, subject only to applicable laws
* and regulations governing limitations on product liability.
*
* THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
* AT ALL TIMES.
*
******************************************************************************/
/*****************************************************************************/
/**
 *
 * @file xaxidma_example_simple_intr.c
 *
 * This file demonstrates how to use the xaxidma driver on the Xilinx AXI
 * DMA core (AXIDMA) to transfer packets.in interrupt mode when the AXIDMA core
 * is configured in simple mode
 *
 * This code assumes a loopback hardware widget is connected to the AXI DMA
 * core for data packet loopback.
 *
 * To see the debug print, you need a Uart16550 or uartlite in your system,
 * and please set "-DDEBUG" in your compiler options. You need to rebuild your
 * software executable.
 *
 * Make sure that MEMORY_BASE is defined properly as per the HW system. The
 * h/w system built in Area mode has a maximum DDR memory limit of 64MB. In
 * throughput mode, it is 512MB.  These limits are need to ensured for
 * proper operation of this code.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- -------------------------------------------------------
 * 4.00a rkv  02/22/11 New example created for simple DMA, this example is for
 *       	       simple DMA,Added interrupt support for Zynq.
 * 4.00a srt  08/04/11 Changed a typo in the RxIntrHandler, changed
 *		       XAXIDMA_DMA_TO_DEVICE to XAXIDMA_DEVICE_TO_DMA
 * 5.00a srt  03/06/12 Added Flushing and Invalidation of Caches to fix CRs
 *		       648103, 648701.
 *		       Added V7 DDR Base Address to fix CR 649405.
 * 6.00a srt  03/27/12 Changed API calls to support MCDMA driver.
 * 7.00a srt  06/18/12 API calls are reverted back for backward compatibility.
 * 7.01a srt  11/02/12 Buffer sizes (Tx and Rx) are modified to meet maximum
 *		       DDR memory limit of the h/w system built with Area mode
 * 7.02a srt  03/01/13 Updated DDR base address for IPI designs (CR 703656).
 *
 * </pre>
 *
 * ***************************************************************************
 */


#include "demo.h"




#include "audio/audio.h"
#include "dma/dma.h"
#include "intc/intc.h"
#include "userio/userio.h"
#include "iic/iic.h"

/***************************** Include Files *********************************/

#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xiic.h"
#include "xaxidma.h"



#ifdef XPAR_INTC_0_DEVICE_ID
 #include "xintc.h"
#else
 #include "xscugic.h"
#endif

/************************** Constant Definitions *****************************/

/*
 * Device hardware build related constants.
 */

// Audio constants
// Number of seconds to record/playback
#define NR_SEC_TO_REC_PLAY		5

// ADC/DAC sampling rate in Hz
//#define AUDIO_SAMPLING_RATE		1000
#define AUDIO_SAMPLING_RATE	  96000

// Number of samples to record/playback
#define NR_AUDIO_SAMPLES		(NR_SEC_TO_REC_PLAY*AUDIO_SAMPLING_RATE)

/* Timeout loop counter for reset
 */
#define RESET_TIMEOUT_COUNTER	10000

#define TEST_START_VALUE	0x0


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/
#if (!defined(DEBUG))
extern void xil_printf(const char *format, ...);
#endif


/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */

static XIic sIic;
static XAxiDma sAxiDma;		/* Instance of the XAxiDma */
static XIntc sIntc;
static XGpio sUserIO;


//
// Interrupt vector table
const ivt_t ivt[] = {
	//IIC
	{XPAR_MICROBLAZE_0_AXI_INTC_AXI_IIC_0_IIC2INTC_IRPT_INTR, (XInterruptHandler)XIic_InterruptHandler, &sIic},
	//DMA Stream to MemoryMap Interrupt handler
	{XPAR_MICROBLAZE_0_AXI_INTC_AXI_DMA_0_S2MM_INTROUT_INTR, (XInterruptHandler)fnS2MMInterruptHandler, &sAxiDma},
	//DMA MemoryMap to Stream Interrupt handler
	{XPAR_MICROBLAZE_0_AXI_INTC_AXI_DMA_0_MM2S_INTROUT_INTR, (XInterruptHandler)fnMM2SInterruptHandler, &sAxiDma},
	//User I/O (buttons, switches, LEDs)
	{XPAR_MICROBLAZE_0_AXI_INTC_AXI_GPIO_0_IP2INTC_IRPT_INTR, (XInterruptHandler)fnUserIOIsr, &sUserIO}
};



/*****************************************************************************/
/**
*
* Main function
*
* This function is the main entry of the interrupt test. It does the following:
*	Initialize the interrupt controller
*	Initialize the IIC controller
*	Initialize the User I/O driver
*	Initialize the DMA engine
*	Initialize the Audio I2S controller
*	Enable the interrupts
*	Wait for a button event then start selected task
*	Wait for task to complete
*
* @param	None
*
* @return
*		- XST_SUCCESS if example finishes successfully
*		- XST_FAILURE if example fails.
*
* @note		None.
*
******************************************************************************/
int main(void)
{
	int Status;

	Demo.u8Verbose = 0;


	xil_printf("\r\n--- Entering main() --- \r\n");


	//
	//Initialize the interrupt controller

	Status = fnInitInterruptController(&sIntc);
	if(Status != XST_SUCCESS) {
		xil_printf("Error initializing interrupts");
		return XST_FAILURE;
	}


	// Initialize IIC controller
	Status = fnInitIic(&sIic);
	if(Status != XST_SUCCESS) {
		xil_printf("Error initializing I2C controller");
		return XST_FAILURE;
	}

    // Initialize User I/O driver
    Status = fnInitUserIO(&sUserIO);
    if(Status != XST_SUCCESS) {
    	xil_printf("User I/O ERROR");
    	return XST_FAILURE;
    }


	//Initialize DMA
	Status = fnConfigDma(&sAxiDma);
	if(Status != XST_SUCCESS) {
		xil_printf("DMA configuration ERROR");
		return XST_FAILURE;
	}


	//Initialize Audio I2S
	Status = fnInitAudio();
	if(Status != XST_SUCCESS) {
		xil_printf("Audio initializing ERROR");
		return XST_FAILURE;
	}


	// Enable all interrupts in our interrupt vector table
	// Make sure all driver instances using interrupts are initialized first
	fnEnableInterrupts(&sIntc, &ivt[0], sizeof(ivt)/sizeof(ivt[0]));



    xil_printf("DONE\r\n");

    //main loop

    while(1) {


    	xil_printf("----------------------------------------------------------\r\n");
		xil_printf("Nexys Video DMA Audio Demo\r\n");
		xil_printf("----------------------------------------------------------\r\n");



    	// Checking the DMA S2MM event flag
    			if (Demo.fDmaS2MMEvent)
    			{
    				xil_printf("\r\nRecording Done...");

    				// Disable Stream function to send data (S2MM)
    				Xil_Out32(I2S_STREAM_CONTROL_REG, 0x00000000);
    				Xil_Out32(I2S_TRANSFER_CONTROL_REG, 0x00000000);
    				//Flush cache
    				microblaze_flush_dcache();
    				microblaze_invalidate_dcache();
    				// Reset S2MM event and record flag
    				Demo.fDmaS2MMEvent = 0;
    				Demo.fAudioRecord = 0;
    			}

    			// Checking the DMA MM2S event flag
    			if (Demo.fDmaMM2SEvent)
    			{
    				xil_printf("\r\nPlayback Done...");

    				// Disable Stream function to send data (S2MM)
    				Xil_Out32(I2S_STREAM_CONTROL_REG, 0x00000000);
    				Xil_Out32(I2S_TRANSFER_CONTROL_REG, 0x00000000);
    				//Flush cache
    				microblaze_flush_dcache();
    				microblaze_invalidate_dcache();
    				// Reset MM2S event and playback flag
    				Demo.fDmaMM2SEvent = 0;
    				Demo.fAudioPlayback = 0;
    			}

    			// Checking the DMA Error event flag
    			if (Demo.fDmaError)
    			{
    				xil_printf("\r\nDma Error...");
    				xil_printf("\r\nDma Reset...");


    				Demo.fDmaError = 0;
    				Demo.fAudioPlayback = 0;
    				Demo.fAudioRecord = 0;
    			}

    			// Checking the btn change event
    			if(Demo.fUserIOEvent) {

    				switch(Demo.chBtn) {
    					case 'u':
    						if (!Demo.fAudioRecord && !Demo.fAudioPlayback)
    						{
    							xil_printf("\r\nStart Recording...");
    							fnSetMicInput();
    							fnAudioRecord(sAxiDma,NR_AUDIO_SAMPLES);
    							Demo.fAudioRecord = 1;
    						}
    						else
    						{
    							if (Demo.fAudioRecord)
    							{
    								xil_printf("\r\nStill Recording...");
    							}
    							else
    							{
    								xil_printf("\r\nStill Playing back...");
    							}
    						}
    						break;
    					case 'd':
    						if (!Demo.fAudioRecord && !Demo.fAudioPlayback)
    						{
    							xil_printf("\r\nStart Playback...");
    							fnSetHpOutput();
    							fnAudioPlay(sAxiDma,NR_AUDIO_SAMPLES);
    							Demo.fAudioPlayback = 1;
    						}
    						else
    						{
    							if (Demo.fAudioRecord)
    							{
    								xil_printf("\r\nStill Recording...");
    							}
    							else
    							{
    								xil_printf("\r\nStill Playing back...");
    							}
    						}
    						break;
    					case 'r':
    						if (!Demo.fAudioRecord && !Demo.fAudioPlayback)
    						{
    							xil_printf("\r\nStart Recording...");
    							fnSetLineInput();
    							fnAudioRecord(sAxiDma,NR_AUDIO_SAMPLES);
    							Demo.fAudioRecord = 1;
    						}
    						else
    						{
    							if (Demo.fAudioRecord)
    							{
    								xil_printf("\r\nStill Recording...");
    							}
    							else
    							{
    								xil_printf("\r\nStill Playing back...");
    							}
    						}
    						break;
    					case 'l':
    						if (!Demo.fAudioRecord && !Demo.fAudioPlayback)
    						{
    							xil_printf("\r\nStart Playback...");
    							fnSetLineOutput();
    							fnAudioPlay(sAxiDma,NR_AUDIO_SAMPLES);
    							Demo.fAudioPlayback = 1;
    						}
    						else
    						{
    							if (Demo.fAudioRecord)
    							{
    								xil_printf("\r\nStill Recording...");
    							}
    							else
    							{
    								xil_printf("\r\nStill Playing back...");
    							}
    						}
    						break;
    					default:
    						break;
    				}

    				// Reset the user I/O flag
    				Demo.chBtn = 0;
    				Demo.fUserIOEvent = 0;
    			}

    	MB_Sleep(20);
    }

	xil_printf("\r\n--- Exiting main() --- \r\n");


	return XST_SUCCESS;

}









