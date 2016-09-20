`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineers: Ryan Kim
//			  Josh Sackos
//            Arthur Brown
// Create Date:    14:10:08 06/13/2012 
// Module Name:    OledExample - Behavioral 
// Project Name: 	 XADC Demo
// Tool versions:  Vivado 2016.2
// Description: Displays formatted XADC data, updates screen twice per second
//
// Revision: 1.3 - modified for XADC Demo
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module OledEX (
    CLK,
    RST,
    din0,
    din1,
    din2,
    din3,
    EN,
    CS,
    SDO,
    SCLK,
    DC,
    FIN
);

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
    input CLK;
    input RST;
    input EN;
    input [31:0] din0;
    input [31:0] din1;
    input [31:0] din2;
    input [31:0] din3;
    output CS;
    output SDO;
    output SCLK;
    output DC;
    output FIN;

	// ===========================================================================
	// 							  Parameters, Registers, and Wires
	// ===========================================================================
	
	//screen layout task. (page is vertical position, index is horizontal)
	//Ch1: #.###V
	//Ch0: #.###V
	//Ch8: #.###V
	//Ch9: #.###V
	task xadc_screen;
	input [31:0] data0;
	input [31:0] data1;
	input [31:0] data2;
	input [31:0] data3;
	input [1:0] page;
	input [3:0] index;
	output [7:0] char;
	begin
        if (index == 0) 
            char <= 8'd67;//'C'
        else if (index == 1)
            char <= 8'd104;//'h'
        else if (index == 2)
            case (page)
            0: char <= 8'd49;//'1'
            1: char <= 8'd48;//'0'
            2: char <= 8'd56;//'8'
            3: char <= 8'd57;//'9'
            endcase
        else if (index == 3)
            char <= 8'd58;//':'
        else if (index == 5)
            case (page)
            0: char <= data0[31:24];
            1: char <= data1[31:24];
            2: char <= data2[31:24];
            3: char <= data3[31:24];
            endcase
        else if (index == 6)
            char <= 8'd46;//'.';
        else if (index == 7)
            case (page)
            0: char <= data0[23:16];
            1: char <= data1[23:16];
            2: char <= data2[23:16];
            3: char <= data3[23:16];
            endcase
        else if (index == 8)
            case (page)
            0: char <= data0[15:8];
            1: char <= data1[15:8];
            2: char <= data2[15:8];
            3: char <= data3[15:8];
            endcase
        else if (index == 9)
            case (page)
            0: char <= data0[7:0];
            1: char <= data1[7:0];
            2: char <= data2[7:0];
            3: char <= data3[7:0];
            endcase
        else if (index == 10)
            char <= 8'd86;
        else
            char <= 8'd32;
	end
	endtask
	
	wire CS, SDO, SCLK, DC, FIN;

    //Current overall state of the state machine
    reg [4:0] current_state=Idle;
    //State to go to after the SPI transmission is finished
    reg [4:0] after_state;
    //State to go to after the set page sequence
    reg [4:0] after_page_state;
    //State to go to after sending the character sequence
    reg [4:0] after_char_state;
    //State to go to after the UpdateScreen is finished
    reg [4:0] after_update_state;


    integer i = 0;
    integer j = 0;

    //Contains the value to be outputted to DC
    reg temp_dc;
    
    //-------------- Variables used in the Delay Controller Block --------------
    reg [11:0] temp_delay_ms;		//amount of ms to delay
    reg temp_delay_en;				//Enable signal for the delay block
    wire temp_delay_fin;				//Finish signal for the delay block
   
    //-------------- Variables used in the SPI controller block ----------------
    reg temp_spi_en;					//Enable signal for the SPI block
    reg [7:0] temp_spi_data;		//Data to be sent out on SPI
    wire temp_spi_fin;				//Finish signal for the SPI block
    
    reg [7:0] temp_char;				//Contains ASCII value for character
    reg [10:0] temp_addr;			//Contains address to BYTE needed in memory
    wire [7:0] temp_dout;			//Contains byte outputted from memory
    reg [1:0] temp_page;				//Current page
    reg [3:0] temp_index;			//Current character on page

    // ===========================================================================
    //                        State Machine Codes
    // ===========================================================================
    localparam Done         = 0;
    localparam Idle         = 1;
    localparam ClearDC      = 2;
    localparam SetDC        = 3;
    localparam UpdateScreen = 4;
    localparam Wait1        = 5;
    localparam Wait2        = 6;
    localparam SetPage      = 7;
    localparam PageNum      = 8;
    localparam LeftColumn1  = 9;
    localparam LeftColumn2  = 10;
    localparam SendChar     = 11;
    localparam ReadMem      = 12;
    localparam ReadMem2     = 13;
    localparam Transition1  = 14;
    localparam Transition2  = 15;
    localparam Transition3  = 16;
    localparam Transition4  = 17;
    localparam Transition5  = 18;
    
	// ===========================================================================
	// 										Implementation
	// ===========================================================================
    
    assign DC = temp_dc;
    //Example finish flag only high when in done state
    assign FIN = (current_state == Done) ? 1'b1 : 1'b0;

    //Instantiate SPI Block
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

    //Instantiate Delay Block
    Delay DELAY_COMP(
        .CLK(CLK),
        .RST(RST),
        .DELAY_MS(temp_delay_ms),
        .DELAY_EN(temp_delay_en),
        .DELAY_FIN(temp_delay_fin)
    );

    //Instantiate Memory Block for character bitmap lookup
    block_rom #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(10),
        .FILENAME("charLib.dat")
    ) CHAR_LIB_COMP (
        .clk(CLK),
        .addr(temp_addr),
        .dout(temp_dout)
    );
    
    
	reg [2:0] char_cnt;
	//  State Machine
	always @(posedge CLK, posedge RST) begin
        if (RST)
            current_state <= Idle;
        else case(current_state)
			// Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
			Idle : begin
                if(EN == 1'b1) begin
                    current_state <= ClearDC;
                    after_page_state <= UpdateScreen;
                    after_update_state <= Wait1;
                    temp_page <= 2'b00;
                end
			end
			
			Wait1 : begin
                temp_delay_ms <= 12'd500; //500ms
                after_state <= UpdateScreen;
                current_state <= Transition3; // Transition3 = The delay transition states
			end
			
			// Do nothing until EN is deassertted and then current_state is Idle
			Done : begin
					if(EN == 1'b0) begin
						current_state <= Idle;
					end
			end
			
			//UpdateScreen State
			//1. Gets ASCII value from current_screen at the current page and the current spot of the page
			//2. If on the last character of the page transition update the page number, if on the last page(3)
			//			then the updateScreen go to "after_update_state" after
			UpdateScreen : begin

					xadc_screen(din0, din1, din2, din3, temp_page, temp_index, temp_char);

					if(temp_index == 'd15) begin

						temp_index <= 'd0;
						temp_page <= temp_page + 1'b1;
						after_char_state <= ClearDC;

						if(temp_page == 2'b11) begin
							after_page_state <= after_update_state;
						end
						else	begin
							after_page_state <= UpdateScreen;
						end
					end
					else begin

						temp_index <= temp_index + 1'b1;
						after_char_state <= UpdateScreen;

					end
					char_cnt <= 'b0;
					current_state <= SendChar;

			end
			
			//Update Page states
			//1. Sets DC to command mode
			//2. Sends the SetPage Command
			//3. Sends the Page to be set to
			//4. Sets the start pixel to the left column
			//5. Sets DC to data mode
			ClearDC : begin
					temp_dc <= 1'b0;
					current_state <= SetPage;
			end
			
			SetPage : begin
					temp_spi_data <= 8'b00100010;
					after_state <= PageNum;
					current_state <= Transition1;
			end
			
			PageNum : begin
					temp_spi_data <= {6'b000000,temp_page};
					after_state <= LeftColumn1;
					current_state <= Transition1;
			end
			
			LeftColumn1 : begin
					temp_spi_data <= 8'b00000000;
					after_state <= LeftColumn2;
					current_state <= Transition1;
			end
			
			LeftColumn2 : begin
					temp_spi_data <= 8'b00010000;
					after_state <= SetDC;
					current_state <= Transition1;
			end
			
			SetDC : begin
					temp_dc <= 1'b1;
					current_state <= after_page_state;
			end
			
			//Send Character States
			//1. Sets the Address to ASCII value of char with the counter appended to the end
			//2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
			//3. Send the byte of data given by the block Ram
			//4. Repeat 7 more times for the rest of the character bytes
            SendChar : begin
                temp_addr <= {temp_char, char_cnt};
                if (char_cnt == 3'd7)
                    after_state <= after_char_state;
                else
                    after_state <= SendChar;
                char_cnt <= char_cnt + 1'b1;
                current_state <= ReadMem;
            end
			
			ReadMem : begin
					current_state <= ReadMem2;
			end

			ReadMem2 : begin
					temp_spi_data <= temp_dout;
					current_state <= Transition1;
			end
			//  End Send Character States

			// SPI transitions
			// 1. Set SPI_EN to 1
			// 2. Waits for SpiCtrl to finish
			// 3. Goes to clear state (Transition5)
			Transition1 : begin
					temp_spi_en <= 1'b1;
					current_state <= Transition2;
			end

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
			//END SPI transitions
			//END Delay Transitions
			//END Clear transition

			default : current_state <= Idle;

		endcase
	end



endmodule
