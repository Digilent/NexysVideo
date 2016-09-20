`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dinilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 08/17/2016 02:26:20 PM
// Module Name: top
// Project Name: XADC Demo
// Target Devices: Nexys Video
// Tool Versions: Vivado 2016.2
// Description: Register JXADC data for each channel and display on OLED.
// 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////


module top(
		input CLK100MHZ,
		input RSTN,
		output SDIN,
		output SCLK,
		output DC,
		output RES,
		output VBAT,
		output VDD,
		input [3:0] xa_p,
		input [3:0] xa_n
    );
    wire enable, ready;
    wire [15:0] xadc_data;
    wire [31:0] ascii;
//    reg [3:0] oled_addr;
    reg [6:0] xadc_addr=7'h10;
    reg [31:0] oled_din0, oled_din1, oled_din2, oled_din3;
    
    xadc_wiz_0 XADC (
        .daddr_in(xadc_addr),
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(), 
        .dwe_in(), 
        .busy_out(),                    
        .vauxp0(xa_p[1]),
        .vauxn0(xa_n[1]),
        .vauxp1(xa_p[0]),
        .vauxn1(xa_n[0]),
        .vauxp8(xa_p[2]),
        .vauxn8(xa_n[2]),
        .vauxp9(xa_p[3]),
        .vauxn9(xa_n[3]),                           
        .do_out(xadc_data), 
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );
    OLEDCtrl OLED (
        .CLK100MHZ (CLK100MHZ),
        .RST       (~RSTN),
        .din0      (oled_din0),
        .din1      (oled_din1),
        .din2      (oled_din2),
        .din3      (oled_din3),
        .SDIN      (SDIN),
        .SCLK      (SCLK),
        .DC        (DC),
        .RES       (RES),
        .VBAT      (VBAT),
        .VDD       (VDD)
    );
    
    //12 bit data to 32 bit ascii conversion table
    block_rom #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(32),
        .FILENAME("lut.dat")
    ) str_lut (
        .clk(CLK100MHZ),
        .addr(xadc_data),
        .dout(ascii)
    );
    
    always @ (negedge(ready)) //when data is ready to be read from register
    begin
        ///////////////////////////////////////////////////////////////////
        //binary to decimal conversion
        //////////////////////////////////////////////////////////////////
//        (xadc_data[11:4] * 250000) >> 10) % 10;
        case (xadc_addr[3:0])
            4'h1: oled_din0 = ascii;
            4'h0: oled_din1 = ascii;
            4'h8: oled_din2 = ascii;
            4'h9: oled_din3 = ascii;
        endcase
        
        case(xadc_addr)
            7'h11: xadc_addr = 7'h10;//last address goes out and load new address in
            7'h10: xadc_addr = 7'h18;
            7'h18: xadc_addr = 7'h19;
            7'h19: xadc_addr = 7'h11; 
            default: xadc_addr = 7'h10;
        endcase  
    end
endmodule
