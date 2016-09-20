`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineers: Ryan Kim
//		      Josh Sackos
//           
// Create Date:    14:00:51 06/12/2012
// Module Name:    PmodOLEDCtrl 
// Project Name: 	 PmodOLED Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: 	 Top level controller that controls the PmodOLED blocks
//
// Revision: 1.1
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module OLEDCtrl(
		CLK100MHZ,
		RST,
		din0,
        din1,
        din2,
        din3,
		SDIN,
		SCLK,
		DC,
		RES,
		VBAT,
		VDD
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
	input CLK100MHZ;
	input RST;
	input [31:0] din0;
	input [31:0] din1;
	input [31:0] din2;
	input [31:0] din3;
//	input [2:0] sw;
	//output CS;
	output SDIN;
	output SCLK;
	output DC;
	output RES;
	output VBAT;
	output VDD;

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
	wire CS, SDIN, SCLK, DC;
	wire VDD, VBAT, RES;
    
	reg [110:0] current_state = "Idle";

	wire init_en;
	wire init_done;
	wire init_cs;
	wire init_sdo;
	wire init_sclk;
	wire init_dc;
	
	wire example_en;
	wire example_cs;
	wire example_sdo;
	wire example_sclk;
	wire example_dc;
	wire example_done;
	// ===========================================================================
	// 										Implementation
	// ===========================================================================
	OledInit Init(
			.CLK(CLK100MHZ),
			.RST(RST),
			.EN(init_en),
			.CS(init_cs),
			.SDO(init_sdo),
			.SCLK(init_sclk),
			.DC(init_dc),
			.RES(RES),
			.VBAT(VBAT),
			.VDD(VDD),
			.FIN(init_done)
//			.sw(sw)
	);
	
	OledEX Example(
			.CLK(CLK100MHZ),
			.RST(RST),
			.din0(din0),
			.din1(din1),
			.din2(din2),
			.din3(din3),
			.EN(example_en),
			.CS(example_cs),
			.SDO(example_sdo),
			.SCLK(example_sclk),
			.DC(example_dc),
			.FIN(example_done)
	);


	//MUXes to indicate which outputs are routed out depending on which block is enabled
	assign CS = (current_state == "OledInitialize") ? init_cs : example_cs;
	assign SDIN = (current_state == "OledInitialize") ? init_sdo : example_sdo;
	assign SCLK = (current_state == "OledInitialize") ? init_sclk : example_sclk;
	assign DC = (current_state == "OledInitialize") ? init_dc : example_dc;
	//END output MUXes

	
	//MUXes that enable blocks when in the proper states
	assign init_en = (current_state == "OledInitialize") ? 1'b1 : 1'b0;
	assign example_en = (current_state == "OledExample") ? 1'b1 : 1'b0;
	//END enable MUXes

	
	//  State Machine
	always @(posedge CLK100MHZ) begin
			if(RST == 1'b1) begin
					current_state <= "Idle";
			end
			else begin
					case(current_state)
						"Idle" : begin
							current_state <= "OledInitialize";
						end
  					   // Go through the initialization sequence
						"OledInitialize" : begin
								if(init_done == 1'b1) begin
										current_state <= "OledExample";
								end
						end
						// Do example and Do nothing when finished
						"OledExample" : begin
								if(example_done == 1'b1) begin
										current_state <= "Done";
								end
						end
						// Do Nothing
						"Done" : begin
							current_state <= "Done";
						end
						
						default : current_state <= "Idle";
					endcase
			end
	end

endmodule
