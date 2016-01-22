`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Thomas Kappenman
// 
// Create Date:    01:55:33 09/09/2014 
// Design Name: Looper
// Module Name:    looper1_1.v 
// Project Name: Looper Project
// Target Devices: Nexys4 DDR
// Tool versions: Vivado 2015.1
// Description: This project turns your Nexys4 DDR into a guitar/piano/aux input looper. Plug input into XADC3
//
// Dependencies: 
//
// Revision: 
//  0.01 - File Created
//  1.0 - Finished with 8 external buttons on JC, 4 memory banks
//  1.1 - Changed addressing, bug fixes
//  1.2 - Moved to different control scheme using 4 onboard buttons, banks doubled to 8 banks, 3 minutes each
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module looper1_1(

   
    input BTNL,
    input BTNR,
    input BTND,
    input BTNC,
    input BTNU,
//    input JA1,
//    input JA2,
//    input JA3,
//    input JA4,
    
    input CLK100MHZ,
    input rstn,
    input sw,
    //input [3:0]sw,
    
    inout scl,
    inout sda,
    
    output ac_mclk,
    input  ac_adc_sdata,
    output  ac_dac_sdata,
    output ac_bclk,
    output ac_lrclk,
    
    output oled_dc,
    output oled_res,
    output oled_sclk,
    output oled_sdin,
    output oled_vbat,
    output oled_vdd,
    
    
    //memory signals
    output   [14:0] ddr3_addr,
    output   [2:0] ddr3_ba,
    output   ddr3_ras_n,
    output   ddr3_cas_n,
    output   ddr3_reset_n,
    output   ddr3_we_n,
    output   ddr3_ck_p,
    output   ddr3_ck_n,
    output   ddr3_cke,
    output   [1:0] ddr3_dm,
    output   ddr3_odt,
    inout    [15:0] ddr3_dq,
    inout    [1:0] ddr3_dqs_p,
    inout    [1:0] ddr3_dqs_n
);

    wire rst;
    assign rst = ~rstn;
   wire clk50;
    parameter tenhz = 10000000;
    
    // Max_block = 64,000,000 / 8 = 8,000,000 or 0111 1010 0001 0010 0000 0000
    // 22:0
    //8 banks
    
//External buttons (foot pedals) attached to JA 1-4 
//    wire playb;
//    assign playb = BTNC || JA4;
//    wire stopb;
//    assign stopb = BTND || JA2;
//    wire backb;
//    assign backb = BTNL || JA3;
//    wire nextb;
//    assign nextb = BTNR || JA1;
    
//    wire [4:0]buttons_i;
//    assign buttons_i = {BTNU ,nextb, playb, stopb, backb};

    wire [4:0] buttons_i;
    assign buttons_i = {BTNU, BTNR, BTNC, BTND, BTNL};
    
    reg [21:0] max_block=0;
        
    wire set_max;
    wire reset_max;
   
    wire [15:0]r;//Bank is recording
    wire del_mem;//Clear delete flag
    wire delete;//Delete flag
    wire [3:0] delete_bank;//Bank to delete
    wire [3:0] mem_bank;//Bank
    wire write_zero;//Used when deleting
    wire [21:0]current_block;//Block address
    wire [4:0] buttons_db;//Debounced buttons
    wire [15:0] active;//Bank is recorded on
    
    wire [3:0] current_bank;
    
    wire [25:0] mem_a;
    assign mem_a = {current_block,mem_bank}; //Address is block*8 + banknumber
    //So address cycles through 0 - 1 - 2 - 3 - 4 - 5 - 6 - 7, then current block is inremented by 1 and mem_bank goes back to 0: mem_a = 8
    wire [63:0] mem_dq_i;
    wire [63:0] mem_dq_o;
    reg [63:0] mem_dq_o_b;
    wire mem_cen;
    wire mem_oen;
    wire mem_wen;

    wire [15:0] display;
    wire data_flag;
    reg [23:0] sound_dataL;
    reg [23:0] sound_dataR;
    wire data_ready;
    
    wire mix_data;
    wire [21:0] block48KHz;
    
    wire clk_out_100MHZ;
    wire clk_out_200MHZ;
    
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    clk_wiz instantiation and wiring
//////////////////////////////////////////////////////////////////////////////////////////////////////////
    clk_wiz_0 clk_1
    (
        // Clock in ports
        .clk_in1(CLK100MHZ),
        // Clock out ports  
        .clk_out1(clk_out_100MHZ),
        .clk_out2(clk_out_200MHZ),
        .clk_out3(ac_mclk),
        .clk_out4(clk50),
        // Status and control signals        
        .locked()            
    );     

//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Audio Initialization via TWI
////////////////////////////////////////////////////////////////////////////////////////////////////////// 

    audio_init initialize_audio
    (
        .clk(clk50),
        .rst(rst),
        .sda(sda),
        .scl(scl)
    );


    wire[23:0] mixL;
    wire[23:0] mixR;
    wire[15:0] play;//Bank is playing
   //  reg test=16'hFFFF;


//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Max block address set and reset
//////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @ (posedge(clk_out_100MHZ))begin
        if(reset_max == 1)begin
            max_block <= 0;
        end
        else if(set_max == 1)begin
            max_block <= current_block;
        end
    end
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Looper control
////////////////////////////////////////////////////////////////////////////////////////////////////////

    debounce dbuttons(
        .clock(clk_out_100MHZ),
        .reset(rst),
        .button(buttons_i),
        .out(buttons_db)
    );
      wire swap;
      wire tracknum;
      
    loop_ctrl mainControl(
        .clk100(clk_out_100MHZ),
        .rst(rst),
        .sw(sw),
        .btns(buttons_db),
        .playing(play),
        .recording(r),
        .active(active),
        .delete(delete),
        .delete_bank(delete_bank),
        .delete_clear(del_mem),
        .bank(current_bank),
        .current_address(current_block),
        .current_max(max_block),
        .set_max(set_max),
        .display(display),
        .swaplight(swap), 
        .loop(tracknum),
        .reset_max(reset_max)
    );
      
        
      
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Memory instantiation
//////////////////////////////////////////////////////////////////////////////////////////////////////// 

wire read_data_valid;
reg read_data_valid_d1;
reg read_data_valid_d2;
wire read_data_valid_rise;
always @ (posedge(clk_out_100MHZ))begin
    read_data_valid_d1<=read_data_valid;
    read_data_valid_d2<=read_data_valid_d1;
end
assign read_data_valid_rise = read_data_valid_d1 & ~read_data_valid_d2;

    DDRcontrol Ram(
        .clk_200MHz_i          (clk_out_200MHZ),
        .rst_i                 (rst),
        // RAM interface
        .ram_a                 (mem_a),
        .ram_dq_i              (mem_dq_i),
        .ram_dq_o              (mem_dq_o),
        .ram_cen               (mem_cen),
        .ram_oen               (mem_oen),
        .ram_wen               (mem_wen),
        .data_valid            (read_data_valid),
        // ddr3 interface
        .ddr3_addr             (ddr3_addr),
        .ddr3_ba               (ddr3_ba),
        .ddr3_ras_n            (ddr3_ras_n),
        .ddr3_cas_n            (ddr3_cas_n),
        .ddr3_reset_n          (ddr3_reset_n),
        .ddr3_we_n             (ddr3_we_n),
        .ddr3_ck_p             (ddr3_ck_p),
        .ddr3_ck_n             (ddr3_ck_n),
        .ddr3_cke              (ddr3_cke),
        .ddr3_dm               (ddr3_dm),
        .ddr3_odt              (ddr3_odt),
        .ddr3_dq               (ddr3_dq),
        .ddr3_dqs_p            (ddr3_dqs_p),
        .ddr3_dqs_n            (ddr3_dqs_n)
    );
          
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Memory Controller
//////////////////////////////////////////////////////////////////////////////////////////////////////// 
    reg pulse48kHz;
    wire lrclkrise;
    assign lrclkrise = lrclkD1 & ~lrclkD2;
    reg[3:0] lrclkcnt=0;
    
    always@(posedge(clk_out_100MHZ))begin
        if (lrclkcnt==8)begin
            pulse48kHz<=1;
            lrclkcnt<=0;
            end
        else
            pulse48kHz<=0;
            if (lrclkrise)lrclkcnt<=lrclkcnt+1;
    end


    mem_ctrl mem_controller(
        .clk_100MHz(clk_out_100MHZ),
        .rst(rst),
        .pulse(pulse48kHz),
        
        .playing(play),
        .recording(r),
        .read_data_valid(read_data_valid_rise),
        
        .delete(delete),
        .delete_bank(delete_bank),
        .max_block(max_block),
        .delete_clear(del_mem),
        .RamCEn(mem_cen),
        .RamOEn(mem_oen),
        .RamWEn(mem_wen),
        .write_zero(write_zero),
        .get_data(data_flag),
        .data_ready(data_ready),
        .mix_data(mix_data),
        
        .addrblock48khz(block48KHz),
        .mem_block_addr(current_block),
        .mem_bank(mem_bank));
                            
//Data in is assigned the latched data input from sound_data, or .5V (16'h7444) if write zero is on      
    assign mem_dq_i = (write_zero==1) ?  64'h0000000000000000 :  {16'h0000, sound_dataL[23:0], sound_dataR[23:0]};

    always@(posedge(clk_out_100MHZ))begin
        mem_dq_o_b<=mem_dq_o;
    end

////////////////////////////////////////////////////////////////////////////////////////////////////////
// Audio input and Channel mixing
////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    wire [23:0] in_audioL;
    wire [23:0] in_audioR;
    wire [23:0] out_audioL;
    wire [23:0] out_audioR;
    
    mixer mixing(
            .clk(clk_out_100MHZ),
            .rst(rst),
            .playing(play),
            .data_ready(data_ready|read_data_valid_rise),
            .mem_dq_o_b(mem_dq_o_b),
            .mem_bank(mem_bank),
            .auxL(in_audioL),
            .auxR(in_audioR),
            .mix_data(mix_data),
            .mixL(mixL),
            .mixR(mixR)
        );
        
    i2s_ctl audio_inout(
        .CLK_I(clk_out_100MHZ),    //Sys clk
        .RST_I(rst),    //Sys rst
        .EN_TX_I(1),  // Transmit Enable (push sound data into chip)
        .EN_RX_I(1), //Receive enable (pull sound data out of chip)
        .FS_I(4'b0101),     //Sampling rate selector
        .MM_I(0),     //Audio controller Master mode select
        .D_L_I(mixL),    //Left channel data input from mix (mixed audio output)
        .D_R_I(mixR),   //Right channel data input from mix
        .D_L_O(in_audioL),    // Left channel data (input from mic input)
        .D_R_O(in_audioR),    // Right channel data (input from mic input)
        .BCLK_O(ac_bclk),   // serial CLK
        .LRCLK_O(ac_lrclk),  // channel CLK
        .SDATA_O(ac_dac_sdata),  // Output serial data
        .SDATA_I(ac_adc_sdata)   // Input serial data
    ); 
     
    reg lrclkD1=0;
    reg lrclkD2=0;
    
    always@(posedge(clk_out_100MHZ))begin
        lrclkD1<=ac_lrclk;
        lrclkD2<=lrclkD1;
    end
    

////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Data in latch
//////////////////////////////////////////////////////////////////////////////////////////////////////// 

    //Latch audio data input when data_flag goes high
    always@(posedge(clk_out_100MHZ))begin 
        if (data_flag==1)begin
            sound_dataL<=in_audioL;
            sound_dataR<=in_audioR;
        end
    end
 
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    OLED module
////////////////////////////////////////////////////////////////////////////////////////////////////////    


    PmodOLEDCtrl OLED(
        .CLK(clk_out_100MHZ),
        .CS(),
        .SDIN(oled_sdin),
        .SCLK(oled_sclk),
        .DC(oled_dc),
        .RES(oled_res),
        .VBAT(oled_vbat),
        .VDD(oled_vdd),   
        
        .swap(swap),
        .tracknum(tracknum),
        .set_max(set_max),
        .reset_max(reset_max),
        .active(active),
        .record_reg(r),
        .play_reg(display),
        .max_address(max_block),
        .current_address(block48KHz),
        .current_bank(current_bank),
        .bank_dig0(current_bank%10),
        .bank_dig1(current_bank/10)
   );

    
    
    


////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Integrated Logic Analyzer for debugging
////////////////////////////////////////////////////////////////////////////////////////////////////////    

//    ila_0 debugger(
//    .clk(clk_out_100MHZ),
//    .probe0(sound_dataL),
//    .probe1(Channel),
//    .probe2(mixL),
//    .probe3(mem_a),
//    .probe4(mem_dq_o_b),
//    .probe5(play),
//    .probe6(mem_dq_i),
//    .probe7(data_ready),
//    .probe8(data_flag),
//    .probe9(pulse48kHz),
//    .probe10(stateo2)
    
//    );




 
endmodule