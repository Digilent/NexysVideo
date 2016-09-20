`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Samuel Lowe
// 
// Create Date: 6/11/2015 
// Design Name: Nexys Video XADC demo 
// Module Name: XADCdemo 
// Target Devices: Digilent Nexys Video rev.A
// Tool Versions: Vivado 2015.1
// Description: Demo that will display all 4 differential XADC header inputs onto the 
//              onboard OLED display
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: One issue is that for reliable results on the OLED, it may be 
//               neccesary to cycle power on the board  before reprogramming
// 
//////////////////////////////////////////////////////////////////////////////////
 

module XADCdemo(
    input CLK100MHZ,
    input [3:0] xa_n,
    input [7:0] sw,
    input [3:0] xa_p, 
    output oled_dc,
    output oled_res,
    output oled_sclk,
    output oled_sdin,
    output oled_vbat,
    output oled_vdd,
    output reg [7:0] led
);
   
   //XADC signals
   wire enable;                     //enable into the xadc to continuosly get data out
   reg [6:0] Address_in = 7'h10;    //Adress of register in XADC drp corresponding to data
   reg [7:0] AddressToOLED = 0;     //Address sent to OLED 
   wire ready;                      //XADC port that declares when data is ready to be taken
   wire [15:0] data;                //XADC data
   reg [15:0] dataToOLED;           //Used to latch data when ready pulses
  
   
   
   reg [32:0] decimal;              //Shifted data to convert to digits
   //Decimal digits
   reg [7:0] dig0 = 0;
   reg [7:0] dig1 = 0;
   reg [7:0] dig2 = 0;
   reg [7:0] dig3 = 0;
   reg [7:0] dig4 = 0;
   reg [7:0] dig5 = 0;
   reg [7:0] dig6 = 0;  
   
   ///////////////////////////////////////////////////////////////////
   //XADC Instantiation
   //////////////////////////////////////////////////////////////////
   
    xadc_wiz_0  XLXI_7 (
        .daddr_in(Address_in), 
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
        .do_out(data), 
        
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );
                     
        
    always @ (negedge(ready)) //when data is ready to be read from register
    begin
        ///////////////////////////////////////////////////////////////////
        //binary to decimal conversion
        //////////////////////////////////////////////////////////////////
        
        //latch current data out
        dataToOLED = data >> 4;
        
        decimal <= dataToOLED;
        //it looks nicer if our max value is 1V instead of .999755
        if(decimal >= 4093) begin
            dig0 = 0;
            dig1 = 0;
            dig2 = 0;
            dig3 = 0;
            dig4 = 0;
            dig5 = 0;
            dig6 = 1;
        end else begin
            // use %10 to get current digit, then divide by 10 to access the next digit
            decimal = decimal * 250000;
            decimal = decimal >> 10;
            
            dig0 = decimal % 10;
            decimal = decimal / 10;
            
            dig1 = decimal % 10;
            decimal = decimal / 10;
            
            dig2 = decimal % 10;
            decimal = decimal / 10;
            
            dig3 = decimal % 10;
            decimal = decimal / 10;
            
            dig4 = decimal % 10;
            decimal = decimal / 10;
            
            dig5 = decimal % 10;
            decimal = decimal / 10; 
            
            dig6 = decimal % 10;
            decimal = decimal / 10; 
        end
        if (Address_in[3:0] == sw[3:0])
            led <= dataToOLED[7:0];
        ///////////////////////////////////////////////////////////////////
        //Address Handleing
        //////////////////////////////////////////////////////////////////      
              
        AddressToOLED <= Address_in[3:0];
        case(Address_in)
        8'h11: Address_in <= 8'h10;//last address goes out and load new address in
        8'h10: Address_in <= 8'h18;
        8'h18: Address_in <= 8'h19;
        8'h19: Address_in <= 8'h11; 
        default: Address_in <= 8'h10;
        endcase  
    end
    
    PmodOLEDCtrl OLED(
        .CLK(CLK100MHZ),
        .Dig6(dig6),
        .Dig5(dig5),
        .Dig4(dig4),
        .Dig3(dig3),
        .Channel(AddressToOLED),
        .CS(),
        .SDIN(oled_sdin),
        .SCLK(oled_sclk),
        .DC(oled_dc),
        .RES(oled_res),
        .VBAT(oled_vbat),
        .VDD(oled_vdd)   
    );
       
endmodule
