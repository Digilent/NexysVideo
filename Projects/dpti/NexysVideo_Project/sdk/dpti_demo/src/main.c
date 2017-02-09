/******************************************************************************
 * @file main.c
 * AXI DPTI DEMO SDK project.
 *
 * @author Sergiu Arpadi
 *
 * @date 2017-Feb-08
 *
 * @copyright
 * (c) 2017 Copyright Digilent Incorporated
 * All Rights Reserved
 *
 * This program is free software; distributed under the terms of BSD 3-clause
 * license ("Revised BSD License", "New BSD License", or "Modified BSD License")
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name(s) of the above-listed copyright holder(s) nor the names
 *    of its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 * @desciption
 * Contains AXI DPTI DEMO SDK project source code.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who            Date         Changes
 * ----- -------------- ------------ -----------------------------------------------
 * 1.00  Sergiu Arpadi  2017-Feb-08  First release
 *
 * </pre>
 *
 *****************************************************************************/
/***************************** Include Files *********************************/


#include <stdio.h>
#include "platform.h"
#include "xaxidma.h"
#include "xparameters.h"
#include "AXI_DPTI.h"

#if defined(XPAR_UARTNS550_0_BASEADDR)
#include "xuartns550_l.h"       /* to use uartns550 */
#endif

/******************** Constant Definitions **********************************/



/* Make sure that the base address for the AXI DPTI IP Core was correctly propagated
 * to "xparameters.h" There is a known bug in certain versions of Vivado.
 * See Xilinx Support answer AR# 66322 (http://www.xilinx.com/support/answers/66322.html).
 *
 * Comment the first two lines from below if the address found in xparameters.h is correct
 */

#undef XPAR_AXI_DPTI_0_AXI4_LITE_BASEADDR
#define XPAR_AXI_DPTI_0_AXI4_LITE_BASEADDR 0x44a00000

#define _AXI_DPTI_BASE_ADDRESS XPAR_AXI_DPTI_0_AXI4_LITE_BASEADDR

//size of DPTI header in bytes
#define _HeaderSize 12
// 8 mega bytes in bytes
#define _8MB 8388607

#define WRITE_OP 2
#define READ_OP 1

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID
#ifdef XPAR_V6DDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR		XPAR_V6DDR_0_S_AXI_BASEADDR
#elif XPAR_S6DDR_0_S0_AXI_BASEADDR
#define DDR_BASE_ADDR		XPAR_S6DDR_0_S0_AXI_BASEADDR
#elif XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR		XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#elif XPAR_MIG7SERIES_0_BASEADDR
#define DDR_BASE_ADDR		XPAR_MIG7SERIES_0_BASEADDR
#endif

#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
		 DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR		0x01000000
#else
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)
#endif

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)

#define MAX_PKT_LEN		0x20
#define TEST_START_VALUE	0xC

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

int AXI_DPTI_DemoTransfers(u16 DeviceId);

/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */

 static XAxiDma AxiDma;

/*****************************************************************************/
/*
* The entry point for this example. It invokes the example function,
* and reports the execution status.
*
* @param	None.
*
* @return
*		- XST_SUCCESS if example finishes successfully
*		- XST_FAILURE if example fails.
*
* @note		None.
*
******************************************************************************/
int main()
{
	int Status;

  	xil_printf("\r\n--- Entering main() --- \r\n");

  	Status = AXI_DPTI_Reg_SelfTest(_AXI_DPTI_BASE_ADDRESS);

	/* Run the poll example for simple transfer */
	Status = AXI_DPTI_DemoTransfers(DMA_DEV_ID);

	if (Status != XST_SUCCESS) {

		xil_printf("AXI_DPTI_DemoTransfers: Failed\r\n");
		return XST_FAILURE;
	}

 	return XST_SUCCESS;

}

/*****************************************************************************/
/* The demo project will use a "while" loop where the actual transfers are performed
 * depending on the header that is received from the PC. The header is composed of three
 * INT variables: Length, Address and Direction (or operation). After reading these
 * values it will then perform a transfer accordingly.
******************************************************************************/
int AXI_DPTI_DemoTransfers(u16 DeviceId)
{
	XAxiDma_Config *CfgPtr;
	int Status;
 	int Index,i ;
	u8 *TxBufferPtr;
	u8 *RxBufferPtr;
	u8 Value;
	u8 DPTI_Status;

 	u8 dyn_header_from_dpti [_HeaderSize];

 	u32 length, address_from_PC, operation_from_PC, length_aux, frame_addr_aux ;

	TxBufferPtr = (u8 *)TX_BUFFER_BASE ;
	RxBufferPtr = (u8 *)RX_BUFFER_BASE;

	/* Initialize the XAxiDma device.
	 */
	CfgPtr = XAxiDma_LookupConfig(DeviceId);
	if (!CfgPtr) {
		xil_printf("No config found for %d\r\n", DeviceId);
		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if(XAxiDma_HasSg(&AxiDma)){
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	/* Disable interrupts, we use polling mode
	 */
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
						XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
						XAXIDMA_DMA_TO_DEVICE);

	Value = TEST_START_VALUE;

	for(Index = 0; Index < MAX_PKT_LEN; Index ++) {
			TxBufferPtr[Index] = Value;

			Value = (Value + 1) & 0xFF;
	}
	/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
	 * is enabled
	 */

	Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, MAX_PKT_LEN);

	while(1)
	{
		// Read header from PC
		xil_printf("\r\n Reading Header from PC \r\n");
		DPTI_Status = DPTI_SimpleTransfer(_AXI_DPTI_BASE_ADDRESS, DPTI_TO_STREAM, _HeaderSize); // Requesting a 12 byte transfer from the PC
		Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)dyn_header_from_dpti, _HeaderSize, XAXIDMA_DEVICE_TO_DMA); // DMA writes header in memory
		if ((Status != XST_SUCCESS) || (DPTI_Status != XST_SUCCESS)){
			return XST_FAILURE;
		}

		while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) // Wait for DMA to finish transfer
		{}

		// Extracting information from header
		for (i = 3; i >= 0; i--){

			length <<= 8;
			length += dyn_header_from_dpti[i];
			address_from_PC <<= 8;
			address_from_PC += dyn_header_from_dpti[i+4];
			operation_from_PC <<= 8;
			operation_from_PC += dyn_header_from_dpti[i+8];

		}

		if (address_from_PC == 0)
		{
			xil_printf("Invalid Address %x \r\n", address_from_PC);
			return XST_FAILURE;
		}

		if (length <= 0)
		{
			xil_printf("Invalid Length %d \r\n", length);
			return XST_FAILURE;
		}

		xil_printf("Received header contents: %d 0x%x %d\r\n", length, address_from_PC, operation_from_PC);

		if (operation_from_PC == READ_OP) //Reading data from PC
		{
			xil_printf("Reading data from PC \r\n");
			// Store transfer length and start address in aux variables
			length_aux = length;
			frame_addr_aux = address_from_PC;

			while(length_aux > _8MB) // For large transfers. This loop will fragment a large transfer into several 8 MB transfers
			{
				xil_printf("%d bytes remaining \r\n", length_aux);
				DPTI_Status = DPTI_SimpleTransfer(_AXI_DPTI_BASE_ADDRESS, DPTI_TO_STREAM, _8MB);
				Status = XAxiDma_SimpleTransfer(&AxiDma, frame_addr_aux, _8MB, XAXIDMA_DEVICE_TO_DMA);

				if ((Status != XST_SUCCESS) || (DPTI_Status != XST_SUCCESS)){
					return XST_FAILURE;
				}

				while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) // Wait for DMA to finish transfer
				{}

				frame_addr_aux += _8MB; // Address is incremented by 8 MB and prepared for next transfer
				length_aux -= _8MB; // Length is decreased by 8 MB
				}

			xil_printf("%d bytes remaining \r\n", length_aux);
			// If the transfer is smaller than 8 MB or, for large transfers, there is data left, the transfer is performed below
			DPTI_Status = DPTI_SimpleTransfer(_AXI_DPTI_BASE_ADDRESS, DPTI_TO_STREAM, length_aux);
			Status = XAxiDma_SimpleTransfer(&AxiDma, frame_addr_aux, length_aux, XAXIDMA_DEVICE_TO_DMA);
			if ((Status != XST_SUCCESS) || (DPTI_Status != XST_SUCCESS)){
				return XST_FAILURE;
			}
			while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) // Wait for DMA to finish transfer
			{}
			xil_printf("DONE Reading data from PC \r\n");
		}

		else

			if (operation_from_PC == WRITE_OP) //Writing data to PC
			{
				xil_printf("Writing data to PC \r\n");
				// Store transfer length and start address in aux variables
				length_aux = length;
				frame_addr_aux = address_from_PC;

				while(length_aux > _8MB) // For large transfers. This loop will fragment a large transfer into several 8 MB transfers
				{
					xil_printf("%d bytes remaining \r\n", length_aux);
					DPTI_Status = DPTI_SimpleTransfer(_AXI_DPTI_BASE_ADDRESS, STREAM_TO_DPTI, _8MB);
					Status = XAxiDma_SimpleTransfer(&AxiDma, frame_addr_aux, _8MB, XAXIDMA_DMA_TO_DEVICE);
					if ((Status != XST_SUCCESS) || (DPTI_Status != XST_SUCCESS)){
						return XST_FAILURE;
					}

					while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {}
					frame_addr_aux += _8MB; // Address is incremented by 8 MB and prepared for next transfer
					length_aux -= _8MB; // Length is decreased by 8 MB
				}

				xil_printf("%d bytes remaining \r\n", length_aux);
				// If the transfer is smaller than 8 MB or, for large transfers, there is data left, the transfer is performed below
				DPTI_Status = DPTI_SimpleTransfer(_AXI_DPTI_BASE_ADDRESS, STREAM_TO_DPTI, length_aux);
				Status = XAxiDma_SimpleTransfer(&AxiDma, frame_addr_aux, length_aux, XAXIDMA_DMA_TO_DEVICE);

				if ((Status != XST_SUCCESS) || (DPTI_Status != XST_SUCCESS)){
					return XST_FAILURE;
				}
				while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) // Wait for DMA to finish transfer
				{}
				xil_printf("DONE Writing data to PC \r\n");
			}
	}
}

