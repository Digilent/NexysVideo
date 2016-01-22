`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2015 01:14:42 PM
// Design Name: 
// Module Name: mixer
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


module mixer(
    input clk,
    input rst,
    input [15:0] playing,
    input data_ready,
    input [63:0] mem_dq_o_b,
    input [3:0]mem_bank,
    input [23:0]auxL,
    input [23:0]auxR,
    input mix_data,
    
    output reg [23:0] mixL,
    output reg [23:0] mixR
    );

   
    integer aux_inL=0;
    integer aux_inR=0;
    
    integer CH0L=0;
    integer CH1L=0;
    integer CH2L=0;
    integer CH3L=0;
    integer CH4L=0;
    integer CH5L=0;
    integer CH6L=0;
    integer CH7L=0;
    integer CH8L=0;
    integer CH9L=0;
    integer CH10L=0;
    integer CH11L=0;
    integer CH12L=0;
    integer CH13L=0;
    integer CH14L=0;
    integer CH15L=0;
    
    integer CH0R=0;
    integer CH1R=0;
    integer CH2R=0;
    integer CH3R=0;
    integer CH4R=0;
    integer CH5R=0;
    integer CH6R=0;
    integer CH7R=0;
    integer CH8R=0;
    integer CH9R=0;
    integer CH10R=0;
    integer CH11R=0;
    integer CH12R=0;
    integer CH13R=0;
    integer CH14R=0;
    integer CH15R=0;
    
    integer mixerL=0;
    integer mixerR=0;
    
    reg[23:0] Lbuffer=0;
    reg[23:0] Rbuffer=0;
    reg[1:0] mixer_state=0;
    
    
    parameter WAIT = 1'b0;
    parameter ASSIGN = 1'b1;
    
    reg state=WAIT;
    
    
    
    always@(posedge(clk))begin
        if (rst==1)begin
            CH0L<=0;
            CH1L<=0;
            CH2L<=0;
            CH3L<=0;
            CH4L<=0;
            CH5L<=0;
            CH6L<=0;
            CH7L<=0;
            CH8L<=0;
            CH9L<=0;
            CH10L<=0;
            CH11L<=0;
            CH12L<=0;
            CH13L<=0;
            CH14L<=0;
            CH15L<=0;
            
            CH0R<=0;
            CH1R<=0;
            CH2R<=0;
            CH3R<=0;
            CH4R<=0;
            CH5R<=0;
            CH6R<=0;
            CH7R<=0;
            CH8R<=0;
            CH9R<=0;
            CH10R<=0;
            CH11R<=0;
            CH12R<=0;
            CH13R<=0;
            CH14R<=0;
            CH15R<=0;
            state<=0;
            mixerL<=0;
            mixerR<=0;
            mixer_state<=0;
            end
        else begin
        case (state)
            WAIT:begin 
                if(data_ready==1) state<=ASSIGN;
            end
            ASSIGN:begin
                state<=WAIT;
                case(mem_bank)
                    0: begin
                        if (playing[0])begin
                            CH0L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH0R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]};
                        end
                        else begin
                            CH0L<=0;
                            CH0R<=0;
                        end
                    end
                    1: begin
                        if (playing[1])begin
                            CH1L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH1R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH1L<=0;
                            CH1R<=0;
                        end
                    end
                    2: begin
                        if (playing[2])begin
                            CH2L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH2R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH2L<=0;
                            CH2R<=0;
                        end
                    end
                    3: begin
                        if (playing[3])begin
                            CH3L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH3R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH3L<=0;
                            CH3R<=0;
                        end
                    end
                    4: begin
                        if (playing[4])begin
                            CH4L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH4R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH4L<=0;
                            CH4R<=0;
                        end
                    end
                    5: begin
                        if (playing[5])begin
                            CH5L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH5R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH5L<=0;
                            CH5R<=0;
                        end
                    end
                    6: begin
                        if (playing[6])begin
                            CH6L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH6R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH6L<=0;
                            CH6R<=0;
                        end
                    end
                    7: begin
                        if (playing[7])begin
                            CH7L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH7R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH7L<=0;
                            CH7R<=0;
                        end
                    end
                    8: begin
                        if (playing[8])begin
                            CH8L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH8R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH8L<=0;
                            CH8R<=0;
                        end
                    end
                    9: begin
                        if (playing[9])begin
                            CH9L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH9R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH9L<=0;
                            CH9R<=0;
                        end
                    end
                    10: begin
                        if (playing[10])begin
                            CH10L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH10R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH10L<=0;
                            CH10R<=0;
                        end
                    end
                    11: begin
                        if (playing[11])begin
                            CH11L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH11R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH11L<=0;
                            CH11R<=0;
                        end
                    end
                    12: begin
                        if (playing[12])begin
                            CH12L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH12R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH12L<=0;
                            CH12R<=0;
                        end
                    end
                    13: begin
                        if (playing[13])begin
                            CH13L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH13R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH13L<=0;
                            CH13R<=0;
                        end
                    end
                    14: begin
                        if (playing[14])begin
                            CH14L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH14R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH14L<=0;
                            CH14R<=0;
                        end
                    end
                    15: begin
                        if (playing[15])begin
                            CH15L<={{8{mem_dq_o_b[47]}},mem_dq_o_b[47:24]};
                            CH15R<={{8{mem_dq_o_b[23]}},mem_dq_o_b[23:0]}; 
                        end
                        else begin
                            CH15L<=0;
                            CH15R<=0;
                        end
                    end
                endcase//End case membank
            end //End assign state
        endcase //End state machine
        
        case(mixer_state)
                    //Idle state
            0: begin
                if (mix_data==1)begin
                    mixer_state<=1;
                    aux_inL<={{8{auxL[23]}},auxL[23:0]};
                    aux_inR<={{8{auxR[23]}},auxR[23:0]};
                end
            end
            1: begin
                mixerL<=CH0L+CH1L+CH2L+CH3L+CH4L+CH5L+CH6L+CH7L+CH8L+CH9L+CH10L+CH11L+CH12L+CH13L+CH14L+CH15L+aux_inL;
                mixerR<=CH0R+CH1R+CH2R+CH3R+CH4R+CH5R+CH6R+CH7R+CH8R+CH9R+CH10R+CH11R+CH12R+CH13R+CH14R+CH15R+aux_inR;
                mixer_state<=2;
            end
            2: begin
                mixL<={mixerL[31],mixerL[22:0]};
                mixR<={mixerR[31], mixerR[22:0]};
                mixer_state<=0;
            end
        endcase
        end //end else reset
    end


    
    
endmodule
