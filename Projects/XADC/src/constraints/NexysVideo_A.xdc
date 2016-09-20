### This file is a general .xdc for the Nexys Video Rev. A
### To use it in a project:
### - uncomment the lines corresponding to used pins
### - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


#Clock Signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
set_property -dict { PACKAGE_PIN G4  IOSTANDARD LVCMOS12 } [get_ports { RSTN }]; #IO_L12N_T1_MRCC_35 Sch=cpu_resetn

##LEDs
#set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { led[0] }]; #IO_L15P_T2_DQS_13 Sch=led[0]
#set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { led[1] }]; #IO_L15N_T2_DQS_13 Sch=led[1]
#set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { led[2] }]; #IO_L17P_T2_13 Sch=led[2]
#set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { led[3] }]; #IO_L17N_T2_13 Sch=led[3]
#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS25 } [get_ports { led[4] }]; #IO_L14N_T2_SRCC_13 Sch=led[4]
#set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS25 } [get_ports { led[5] }]; #IO_L16N_T2_13 Sch=led[5]
#set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS25 } [get_ports { led[6] }]; #IO_L16P_T2_13 Sch=led[6]
#set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS25 } [get_ports { led[7] }]; #IO_L5P_T0_13 Sch=led[7]

##Switches
#set_property -dict { PACKAGE_PIN E22  IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L22P_T3_16 Sch=sw[0]
#set_property -dict { PACKAGE_PIN F21  IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_25_16 Sch=sw[1]
#set_property -dict { PACKAGE_PIN G21  IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L24P_T3_16 Sch=sw[2]
#set_property -dict { PACKAGE_PIN G22  IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L24N_T3_16 Sch=sw[3]
#set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports { sw[4] }]; #IO_L6P_T0_15 Sch=sw[4]
#set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS33 } [get_ports { sw[5] }]; #IO_0_15 Sch=sw[5]
#set_property -dict { PACKAGE_PIN K13  IOSTANDARD LVCMOS33 } [get_ports { sw[6] }]; #IO_L19P_T3_A22_15 Sch=sw[6]
#set_property -dict { PACKAGE_PIN M17  IOSTANDARD LVCMOS33 } [get_ports { sw[7] }]; #IO_25_15 Sch=sw[7]


#OLED Display
set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33 } [get_ports { DC }]; #IO_L7N_T1_D10_14 Sch=oled_dc
set_property -dict { PACKAGE_PIN U21   IOSTANDARD LVCMOS33 } [get_ports { RES }]; #IO_L4N_T0_D05_14 Sch=oled_res
set_property -dict { PACKAGE_PIN W21   IOSTANDARD LVCMOS33 } [get_ports { SCLK }]; #IO_L7P_T1_D09_14 Sch=oled_sclk
set_property -dict { PACKAGE_PIN Y22   IOSTANDARD LVCMOS33 } [get_ports { SDIN }]; #IO_L9N_T1_DQS_D13_14 Sch=oled_sdin
set_property -dict { PACKAGE_PIN P20   IOSTANDARD LVCMOS33 } [get_ports { VBAT }]; #IO_0_14 Sch=oled_vbat
set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVCMOS33 } [get_ports { VDD }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=oled_vdd

#XADC Header
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33     } [get_ports { xa_n[0] }]; #IO_L3N_T0_DQS_AD1N_15 Sch=xa_n[1]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33     } [get_ports { xa_p[0] }]; #IO_L3P_T0_DQS_AD1P_15 Sch=xa_p[1]
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33     } [get_ports { xa_n[1] }]; #IO_L1N_T0_AD0N_15 Sch=xa_n[2]
set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33     } [get_ports { xa_p[1] }]; #IO_L1P_T0_AD0P_15 Sch=xa_p[2]
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33     } [get_ports { xa_n[2] }]; #IO_L2N_T0_AD8N_15 Sch=xa_n[3]
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33     } [get_ports { xa_p[2] }]; #IO_L2P_T0_AD8P_15 Sch=xa_p[3]
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33     } [get_ports { xa_n[3] }]; #IO_L5N_T0_AD9N_15 Sch=xa_n[4]
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33     } [get_ports { xa_p[3] }]; #IO_L5P_T0_AD9P_15 Sch=xa_p[4]