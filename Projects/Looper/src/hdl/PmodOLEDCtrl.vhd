----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    14:35:33 10/10/2011 
-- Module Name:    PmodOLEDCtrl - Behavioral 
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Top level controller that controls the PmodOLED blocks
--
-- Revision: 1.1
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.all;

entity PmodOLEDCtrl is
	Port ( 
		CLK 	: in  STD_LOGIC;

		CS  	: out STD_LOGIC;
		SDIN	: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		RES	: out STD_LOGIC;
		VBAT	: out STD_LOGIC;
		VDD	: out STD_LOGIC;
		
		set_max           : in STD_LOGIC;
		reset_max         : in STD_LOGIC;
		swap              : in STD_LOGIC;
		tracknum          : in STD_LOGIC;
        active            : in STD_LOGIC_VECTOR (15 downto 0);
		record_reg        : in STD_LOGIC_VECTOR (15 downto 0);
		play_reg          : in STD_LOGIC_VECTOR (15 downto 0);
		max_address       : in STD_LOGIC_VECTOR (21 downto 0);
        current_address   : in STD_LOGIC_VECTOR (21 downto 0);
        current_bank      : in STD_LOGIC_VECTOR (3 downto 0);
        bank_dig0	      : in STD_LOGIC_VECTOR (7 downto 0);
        bank_dig1         : in STD_LOGIC_VECTOR (7 downto 0)		
		);
		
end PmodOLEDCtrl;

architecture Behavioral of PmodOLEDCtrl is

component OledInit is
Port ( CLK 	: in  STD_LOGIC;
		RST 	: in	STD_LOGIC;
		EN		: in  STD_LOGIC;
		CS  	: out STD_LOGIC;
		SDO	: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		RES	: out STD_LOGIC;
		VBAT	: out STD_LOGIC;
		VDD	: out STD_LOGIC;
		FIN  : out STD_LOGIC);
end component;

component OledCon is
    Port ( CLK 	: in  STD_LOGIC;

		RST 	: in	STD_LOGIC;
		EN		: in  STD_LOGIC;
		CS  	: out STD_LOGIC;
		SDO		: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		FIN  : out STD_LOGIC;
		
	  set_max           : in STD_LOGIC;
	  reset_max         : in STD_LOGIC;
      swap              : in STD_LOGIC;
      tracknum          : in STD_LOGIC;
      active            : in STD_LOGIC_VECTOR (15 downto 0);
      record_reg        : in STD_LOGIC_VECTOR (15 downto 0);
      play_reg          : in STD_LOGIC_VECTOR (15 downto 0);
      max_address       : in STD_LOGIC_VECTOR (21 downto 0);
      current_address   : in STD_LOGIC_VECTOR (21 downto 0);
      current_bank   : in STD_LOGIC_VECTOR (3 downto 0);
      bank_dig0          : in STD_LOGIC_VECTOR (7 downto 0);
      bank_dig1         : in STD_LOGIC_VECTOR (7 downto 0));
end component;

type states is (Idle,
					OledInitialize,
					OledExample,
					Done);

signal current_state 	: states := Idle;

signal init_en				: STD_LOGIC := '0';
signal init_done			: STD_LOGIC;
signal init_cs				: STD_LOGIC;
signal init_sdo			: STD_LOGIC;
signal init_sclk			: STD_LOGIC;
signal init_dc				: STD_LOGIC;

signal ex_en			: STD_LOGIC := '0';
signal ex_cs			: STD_LOGIC;
signal ex_sdo		: STD_LOGIC;
signal ex_sclk		: STD_LOGIC;
signal ex_dc			: STD_LOGIC;
signal ex_done		: STD_LOGIC;

signal RST			: STD_LOGIC := '0';

begin

	Init: OledInit port map(CLK, RST, init_en, init_cs, init_sdo, init_sclk, init_dc, RES, VBAT, VDD, init_done);
	Control: OledCon Port map(CLK,RST, ex_en, ex_cs, ex_sdo, ex_sclk, ex_dc, ex_done, set_max, reset_max, swap, tracknum, active, record_reg, play_reg, max_address, current_address, current_bank, bank_dig0, bank_dig1);
	
	--MUXes to indicate which outputs are routed out depending on which block is enabled
	CS <= init_cs when (current_state = OledInitialize) else
			ex_cs;
	SDIN <= init_sdo when (current_state = OledInitialize) else
			ex_sdo;
	SCLK <= init_sclk when (current_state = OledInitialize) else
			ex_sclk;
	DC <= init_dc when (current_state = OledInitialize) else
			ex_dc;
	--END output MUXes
	
	--MUXes that enable blocks when in the proper states
	init_en <= '1' when (current_state = OledInitialize) else
					'0';
	ex_en <= '1' when (current_state = OledExample) else
					'0';
	--END enable MUXes
	

	process(CLK)
	begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				current_state <= Idle;
			else
				case(current_state) is
					when Idle =>
						current_state <= OledInitialize;
					--Go through the initialization sequence
					when OledInitialize =>
						if(init_done = '1') then
							current_state <= OledExample;
						end if;
					--Do example and Do nothing when finished
					when OledExample =>
						if(ex_done = '1') then
							current_state <= OledExample;
						end if;
					--Do Nothing
					when Done =>
						current_state <= Done;
					when others =>
						current_state <= Idle;
				end case;
			end if;
		end if;
	end process;
	
	
end Behavioral;

