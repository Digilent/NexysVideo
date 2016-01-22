`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2015 07:20:54 PM
// Design Name: 
// Module Name: mem_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mem_ctrl(

    input clk_100MHz,
    input rst,
    input pulse,
    
    input [15:0] playing,
    input [15:0] recording,
    
    input read_data_valid,
    
    input delete,
    input [3:0] delete_bank,
    
    input [21:0] max_block,
    
    output reg delete_clear,
    
    output reg RamCEn,
    output reg RamOEn,
    output reg RamWEn,
    output reg write_zero,
    output reg get_data,
    output reg data_ready,
    output reg mix_data,
    
    output reg [21:0] addrblock48khz,
    output [21:0] mem_block_addr,
    output reg [3:0] mem_bank

);    
    initial begin
        delete_clear = 0;
        write_zero = 0;    
        get_data = 0;  
        data_ready = 0;
        mix_data=0;
        mem_bank=0;
        addrblock48khz = 0;
    end
    //Memory controller delays
    //State machine states
    parameter BANK = 4'b0000;
    parameter FLAG = 4'b0001;
    parameter WRITE_ACK = 4'b0010;
    parameter INC_BLOCK = 4'b0011;
    parameter WAIT = 4'b0100;
    parameter DELETE = 4'b0101;
    parameter DELETE_ACK = 4'b0110;
    parameter DELETE_INC = 4'b0111;
    parameter ONECYCLE = 4'b1000;
    parameter ENTERDELETE = 4'b1001;
    parameter LEAVEDELETE = 4'b1010;
    parameter READ_ACK = 4'b1011;
   // parameter MHz48cnt = 2083;
//parameter MHz48cnt = 200;
    wire address_enable;
    assign address_enable = playing || recording;
    reg [12:0] count=0;
    
    reg [4:0]pstate = WAIT;
    reg [3:0] nstate = BANK;
    reg delay_done = 0;
    reg counterEnable=0;
    reg increment=0;
    integer counter = 0;
    reg [21:0] max_delete_block=0;
    reg [21:0] delete_address=0;
    reg WEn_d1=1;

    assign mem_block_addr = (write_zero==0) ? addrblock48khz : delete_address;// Mem_block address is driven to delete_address only if write_zero is on
    
always @ (posedge(clk_100MHz)) begin
    if (rst==1)addrblock48khz<=0;
    else if (address_enable==0)addrblock48khz<=0;
    else if(increment==1)begin
        if(max_block==0 || addrblock48khz < max_block)
            addrblock48khz <= addrblock48khz + 1;
        else
            addrblock48khz <= 0;
    end
end
    
    
always @(posedge(clk_100MHz))begin
    RamWEn<=WEn_d1;
end
    
    
always @ (posedge clk_100MHz)
begin
    if (rst == 1)begin
        pstate <= WAIT;
        counterEnable <= 0;
        write_zero <= 0;
        get_data<=0;
        data_ready<=0;
        mem_bank<=0;
        end
    else begin
    if (pulse==1)nstate<=LEAVEDELETE;
    case (pstate)
        BANK : begin
            if(mem_bank==15)nstate<=INC_BLOCK;//Last mem_bank
            else nstate <= BANK;  
            if(recording[mem_bank] == 1)begin
                get_data <= 1;
                counterEnable <= 1;
                RamCEn<=0;
                RamOEn<=1;
                WEn_d1<=0;
                pstate<=WRITE_ACK;
            end
            else if(playing[mem_bank] == 1)begin
                get_data<=0;
                RamCEn <= 0;
                RamOEn <= 0;
                WEn_d1 <= 1;
                pstate<=READ_ACK;
            end
            else begin
                get_data<=0;
                RamCEn <= 1;
                RamOEn <= 1;
                WEn_d1 <= 1;
                data_ready <= 1;
                pstate <= FLAG;
            end            
        end
        FLAG : begin
            data_ready <= 0;
            if(mem_bank!=15)mem_bank <= mem_bank + 1;//Increment bank by 1 after data_ready pulse
            pstate <= nstate;
        end
        READ_ACK : begin
            if (read_data_valid)begin
                data_ready<=1;
                RamCEn<=1;
                RamOEn<=1;
                WEn_d1<=1;
                pstate <= FLAG;
                counterEnable <= 0;
            end
        end
        
        WRITE_ACK : begin
            get_data<=0;//Turn off get_data pulse
//            if ((r==1 && counter==58) || (r==0 && counter==35))begin //At 55 clock cycles, send data_ready pulse, turn off memory signals
            if (counter==60)begin //At 55 clock cycles, send data_ready pulse, turn off memory signals
                data_ready<=1;
                RamCEn<=1;
                RamOEn<=1;
                WEn_d1<=1;
            end
            else data_ready<=0;//data_ready pulse stays low
            if(delay_done == 1)begin//Delay is done, go to next bank
                pstate <= nstate;
                mem_bank<=mem_bank+1;
                counterEnable <= 0;
             end
        end
        
        INC_BLOCK: begin
            increment <= 1;
            mix_data<=1;
            nstate <= WAIT;
            pstate <= WAIT;
        end
        
    /////////////////////////Wait
        WAIT: begin
            mix_data <= 0;
            increment <= 0;//Stop incrementing addrblock48khz
            mem_bank<=0;
            if(pulse == 1)begin
                pstate <= BANK;
            end
            else if(delete == 1)begin
                pstate <= ENTERDELETE;
            end
            else 
                pstate <= WAIT;
            end
    /////////////////////////Delete Loop
        ENTERDELETE: begin
            if (max_delete_block==0)begin
                if (max_block==0)
                    max_delete_block<=mem_block_addr;
                else
                    max_delete_block<=max_block;
            end
            nstate<=DELETE;
            mem_bank<=delete_bank;//Mem bank to delete_bank
            write_zero <= 1;    //Write a 0 to erase data from memory
            pstate<=DELETE;
        end
        DELETE : begin
            RamCEn <= 0;
            RamOEn <= 1;
            WEn_d1 <= 0; 
            counterEnable <= 1;
            pstate <= DELETE_ACK;
        end
             
        DELETE_ACK : begin
            if(delay_done == 1)begin
                pstate <= DELETE_INC;
                RamCEn <= 1;
                RamOEn <= 1;
                WEn_d1 <= 1;
                counterEnable <= 0;
            end
        end 
         
        DELETE_INC : begin
            if(delete_address < max_delete_block)begin//Not done erasing
                delete_address<=delete_address+1;
                pstate <= nstate;//Will either go to DELETE, or will go to LEAVEDELETE if a pulse was triggered during erasing
            end
            else begin//Done erasing! 
                delete_clear <= 1; //Flag to clear the delete signal
                delete_address<=0;
                write_zero<=0;
                max_delete_block<=0; 
                mem_bank<=0;    
                pstate <= ONECYCLE;  
            end  
        end 
                     
        ONECYCLE: begin //To kill the delete_clear pulse
           delete_clear<=0;
           pstate <=WAIT;
        end
        
        LEAVEDELETE: begin
            mem_bank<=0;
            write_zero<=0;
            counterEnable<=1;
            if(delay_done==1)begin
                counterEnable<=0;
                pstate<=BANK;
            end
        end
    endcase 
     
   end //end resetn
end         
 
 
 
 //delay
 

 

 
 always @(posedge clk_100MHz)begin
    if(counterEnable==0)begin
        counter <= 0;
        delay_done <= 0;
    end
//    else if((r==0 && counter < 60) || (r==1 && counter < 37)) begin
    else if(counter < 62) begin
        counter <= counter + 1;
        delay_done <= 0;
    end
    
    else begin
        counter <= 0;
        delay_done <= 1;
    end
   end     
   
    
endmodule
