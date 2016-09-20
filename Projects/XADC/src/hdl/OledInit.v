`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineers: Ryan Kim
//				  Josh Sackos
// 
// Create Date:    14:49:54 06/12/2012 
// Module Name:    OledInit 
// Project Name: 	 PmodOLED Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: 	 Runs the initialization sequence for the PmodOLED
//
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module OledInit(
    CLK,
    EN,
    RST,
    CS,
    DC,
    FIN,
    RES,
    SCLK,
    SDO,
    VBAT,
    VDD
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
    input CLK;
    input EN;
    input RST;
    output CS;
    output DC;
    output FIN;
    output RES;
    output SCLK;
    output SDO;
    output VBAT;
    output VDD;

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
	wire DC, RES, VBAT, VDD, FIN;
	wire CS, SCLK, SDO;

	reg [4:0] current_state = Idle;
	reg [4:0] after_state = Idle;

	reg temp_dc = 1'b0;
	reg temp_res = 1'b1;
	reg temp_vbat = 1'b1;
	reg temp_vdd = 1'b1;
	reg temp_fin = 1'b0;
	
	wire [11:0] temp_delay_ms;
	reg temp_delay_en = 1'b0;
	wire temp_delay_fin;
	reg temp_spi_en = 1'b0;
	reg [7:0] temp_spi_data = 8'h00;
	wire temp_spi_fin;
    // ===========================================================================
    //                                      State Machine Codes
    // ===========================================================================    
    
    localparam Idle          = 0;
    localparam VddOn         = 1;
    localparam Wait1         = 2;
    localparam DispOff       = 3;
    localparam ResetOn       = 4;
    localparam Wait2         = 5;
    localparam ResetOff      = 6;
    localparam ChargePump1   = 7;
    localparam ChargePump2   = 8;
    localparam PreCharge1    = 9;
    localparam PreCharge2    = 10;
    localparam VbatOn        = 11;
    localparam Wait3         = 12;
    localparam DispContrast1 = 13;
    localparam DispContrast2 = 14;
    localparam InvertDisp1   = 15;
    localparam InvertDisp2   = 16;
    localparam ComConfig1    = 17;
    localparam ComConfig2    = 18;
    localparam DispOn        = 19;
    localparam FullDisp      = 20;
    localparam Done          = 21;
    localparam Transition1   = 22;
    localparam Transition2   = 23;
    localparam Transition3   = 24;
    localparam Transition4   = 25;
    localparam Transition5   = 26;


	// ===========================================================================
	// 										Implementation
	// ===========================================================================	
	SpiCtrl SPI_COMP(
			.CLK(CLK),
			.RST(RST),
			.SPI_EN(temp_spi_en),
			.SPI_DATA(temp_spi_data),
			.CS(CS),
			.SDO(SDO),
			.SCLK(SCLK),
			.SPI_FIN(temp_spi_fin)
	);
	
	Delay DELAY_COMP(
			.CLK(CLK),
			.RST(RST),
			.DELAY_MS(temp_delay_ms),
			.DELAY_EN(temp_delay_en),
			.DELAY_FIN(temp_delay_fin)
	);

	assign DC = temp_dc;
	assign RES = temp_res;
	assign VBAT = temp_vbat;
	assign VDD = temp_vdd;
	assign FIN = temp_fin;

	// Delay 100 ms after VbatOn
	assign temp_delay_ms = (after_state == DispContrast1) ? 12'h064 : 12'h001;


	// State Machine
	always @(posedge CLK) begin
			if(RST == 1'b1) begin
					current_state <= Idle;
					temp_res <= 1'b0;
			end
			else begin
					temp_res <= 1'b1;
					
					case(current_state)

							// Idle State
							Idle : begin
									if(EN == 1'b1) begin
										temp_dc <= 1'b0;
										current_state <= VddOn;
									end
							end

							// Initialization Sequence
							// This should be done everytime the PmodOLED is started
							VddOn : begin
								temp_vdd <= 1'b0;
								current_state <= Wait1;
							end

							// 3
							Wait1 : begin
								after_state <= DispOff;
								current_state <= Transition3;
							end

							// 4
							DispOff : begin
								temp_spi_data <= 8'hAE; // 0xAE
								after_state <= ResetOn;
								current_state <= Transition1;
							end

							// 5
							ResetOn : begin
								temp_res <= 1'b0;
								current_state <= Wait2;
							end

							// 6							
							Wait2 : begin
								after_state <= ResetOff;
								current_state <= Transition3;
							end

							// 7
							ResetOff : begin
								temp_res <= 1'b1;
								after_state <= ChargePump1;
								current_state <= Transition3;
							end

							// 8
							ChargePump1 : begin
								temp_spi_data <= 8'h8D; //0x8D
								after_state <= ChargePump2;
								current_state <= Transition1;
							end

							// 9
							ChargePump2 : begin
								temp_spi_data <= 8'h14; // 0x14
								after_state <= PreCharge1;
								current_state <= Transition1;
							end

							// 10
							PreCharge1 : begin
								temp_spi_data <= 8'hD9; // 0xD9
								after_state <= PreCharge2;
								current_state <= Transition1;
							end

							// 11
							PreCharge2 : begin
								temp_spi_data <= 8'hF1; // 0xF1
								after_state <= VbatOn;
								current_state <= Transition1;
							end

							// 12
							VbatOn : begin
								temp_vbat <= 1'b0;
								current_state <= Wait3;
							end

							// 13
							Wait3 : begin
								after_state <= DispContrast1;
								current_state <= Transition3;
							end

							// 14
							DispContrast1 : begin
								temp_spi_data <= 8'h81; // 0x81
								after_state <= DispContrast2;
								current_state <= Transition1;
							end

							// 15
							DispContrast2 : begin
								temp_spi_data <= 8'h0F; // 0x0F
								after_state <= InvertDisp1;
								current_state <= Transition1;
							end

							// 16
							InvertDisp1 : begin
								temp_spi_data <= 8'hA0; // 0xA1
								after_state <= InvertDisp2;
								current_state <= Transition1;
							end

							// 17
							InvertDisp2 : begin
								temp_spi_data <= 8'hC0; // 0xC8
								after_state <= ComConfig1;
								current_state <= Transition1;
							end

							// 18
							ComConfig1 : begin
								temp_spi_data <= 8'hDA; // 0xDA
								after_state <= ComConfig2;
								current_state <= Transition1;
							end

							// 19
							ComConfig2 : begin
								temp_spi_data <= 8'h00; // 0x20
								after_state <= DispOn;
								current_state <= Transition1;
							end

							// 20
							DispOn : begin
								temp_spi_data <= 8'hAF; // 0xAF
								after_state <= Done;
								current_state <= Transition1;
							end
						   // ************ END Initialization sequence ************

							// Used for debugging, This command turns the entire screen on regardless of memory
							FullDisp : begin
								temp_spi_data <= 8'hA5; // 0xA5
								after_state <= Done;
								current_state <= Transition1;
							end

						   // Done state
							Done : begin
								if(EN == 1'b0) begin
									temp_fin <= 1'b0;
									current_state <= Idle;
								end
								else begin
									temp_fin <= 1'b1;
								end
							end

							// SPI transitions
							// 1. Set SPI_EN to 1
							// 2. Waits for SpiCtrl to finish
							// 3. Goes to clear state (Transition5)
							Transition1 : begin
								temp_spi_en <= 1'b1;
								current_state <= Transition2;
							end

							// 24
							Transition2 : begin
								if(temp_spi_fin == 1'b1) begin
									current_state <= Transition5;
								end
							end

							// Delay Transitions
							// 1. Set DELAY_EN to 1
							// 2. Waits for Delay to finish
							// 3. Goes to Clear state (Transition5)	
							Transition3 : begin
								temp_delay_en <= 1'b1;
								current_state <= Transition4;
							end

							// 26
							Transition4 : begin
								if(temp_delay_fin == 1'b1) begin
									current_state <= Transition5;
								end
							end

							// Clear transition
							// 1. Sets both DELAY_EN and SPI_EN to 0
							// 2. Go to after state
							Transition5 : begin
								temp_spi_en <= 1'b0;
								temp_delay_en <= 1'b0;
								current_state <= after_state;
							end

							default : current_state <= Idle;

					endcase
			end
	end

endmodule
