----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Samuel Lowe adapted from Ryan Kim 
-- 
-- Create Date:    6/11/2015 
-- Module Name:    OledExample - Behavioral 
-- Project Name: 	 Nexys Video XADC demo
-- Tool versions:  Vivado 2015.1
-- Description: Demo for the PmodOLED.  First displays the alphabet for ~4 seconds and then
--				Clears the display, waits for a ~1 second and then displays The analog data found on the XADC header
--
-- Revision: 1.3
-- Revision 0.01 - File Created
-- Revision 1.3 - Ported to Vivado and added writing functionality to digilentscreen
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity OledCon is
    Port ( CLK 	: in  STD_LOGIC; --System CLK
			  RST 	: in	STD_LOGIC; --Synchronous Reset
			 
			  -- bank  : in    std_logic_vector(7 downto 0);
			  
			  EN		: in  STD_LOGIC; --Example block enable pin
			  CS  	: out STD_LOGIC; --SPI Chip Select
			  SDO		: out STD_LOGIC; --SPI Data out
			  SCLK	: out STD_LOGIC; --SPI Clock
			  DC		: out STD_LOGIC; --Data/Command Controller
			  FIN  	: out STD_LOGIC;--Finish flag for example block
			  
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
              bank_dig0          : in STD_LOGIC_VECTOR (7 downto 0);
              bank_dig1         : in STD_LOGIC_VECTOR (7 downto 0)
              );
end OledCon;

architecture Behavioral of OledCon is

--SPI Controller Component
COMPONENT SpiCtrl
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         SPI_EN : IN  std_logic;
         SPI_DATA : IN  std_logic_vector(7 downto 0);
         CS : OUT  std_logic;
         SDO : OUT  std_logic;
         SCLK : OUT  std_logic;
         SPI_FIN : OUT  std_logic
        );
    END COMPONENT;

--Delay Controller Component
COMPONENT Delay
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         DELAY_MS : IN  std_logic_vector(11 downto 0);
         DELAY_EN : IN  std_logic;
         DELAY_FIN : OUT  std_logic
        );
    END COMPONENT;
	 
--Character Library, Latency = 1
COMPONENT charLib
  PORT (
    clka : IN STD_LOGIC; --Attach System Clock to it
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0); --First 8 bits is the ASCII value of the character the last 3 bits are the parts of the char
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) --Data byte out
  );
END COMPONENT;

COMPONENT div_gen_0
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(55 DOWNTO 0)
  );
END COMPONENT;
--states for memory assignment

type mem_states is ( assign_idle,
                        assign_bank,
                        assign_track,
                        assign_bar,
                        assign_play_states);

type progress_states is ( wait_new_max,
                        divide,
                        check,
                        assign_full_character,
                        assign_part_character,
                        --clear_remaining,
                        waitstate);
                     
                     

--States for state machine
type states is (Idle,
				ClearDC,
				SetPage,
				PageNum,
				LeftColumn1,
				LeftColumn2,
				SetDC,
				Alphabet,
				Wait1,
				ClearScreen,
				Wait2,
				DigilentScreen,
				Wait3,
				UpdateScreen,
				SendChar1,
				SendChar2,
				SendChar3,
				SendChar4,
				SendChar5,
				SendChar6,
				SendChar7,
				SendChar8,
				ReadMem,
				ReadMem2,
				Done,
				Transition1,
				Transition2,
				Transition3,
				Transition4,
				Transition5
					);
type OledMem is array(0 to 3, 0 to 15) of std_logic_vector(7 downto 0);

--Variable that contains what the screen will be after the next UpdateScreen state
signal current_screen : OledMem; 
--Constant that says This is Digilents Nexys Video
signal digilent_init : OledMem := ((X"42",X"61",X"6E",X"6B",X"3A",X"20",X"20",X"20",X"20",X"2D",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"54",X"72",X"61",X"63",X"6B",X"3A",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"09",X"0A",X"09",X"0A",X"09",X"0A",X"09",X"0A",X"09",X"0A",X"09",X"0A",X"09",X"0A",X"09",X"0A"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
--Constant that fills the screen with blank (spaces) entries
signal clear_screen : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
--array that says Channel X: (voltage) V												
signal digilent_screen : OledMem:=             ((X"42",X"61",X"6E",X"6B",X"3A",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"54",X"72",X"61",X"63",X"6B",X"3A",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"8A",X"89"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));





--Current overall state of the assignment state machine
signal assignment_state : mem_states := assign_idle;                                                
signal progress_state : progress_states:= wait_new_max;
--Current overall state of the state machine
signal current_state : states := Idle;
--State to go to after the SPI transmission is finished
signal after_state : states;
--State to go to after the set page sequence
signal after_page_state : states;
--State to go to after sending the character sequence
signal after_char_state : states;
--State to go to after the UpdateScreen is finished
signal after_update_state : states;

--Contains the value to be outputted to DC
signal temp_dc : STD_LOGIC := '0';

--Variables used in the Delay Controller Block
signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0); --amount of ms to delay
signal temp_delay_en : STD_LOGIC := '0'; --Enable signal for the delay block
signal temp_delay_fin : STD_LOGIC; --Finish signal for the delay block

--Variables used in the SPI controller block
signal temp_spi_en : STD_LOGIC := '0'; --Enable signal for the SPI block
signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Data to be sent out on SPI
signal temp_spi_fin : STD_LOGIC; --Finish signal for the SPI block
 
signal temp_char : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Contains ASCII value for character
signal temp_addr : STD_LOGIC_VECTOR (10 downto 0) := (others => '0'); --Contains address to BYTE needed in memory
signal temp_dout : STD_LOGIC_VECTOR (7 downto 0); --Contains byte outputted from memory
signal temp_page : STD_LOGIC_VECTOR (1 downto 0) := (others => '0'); --Current page
signal temp_index : integer range 0 to 15 := 0; --Current character on page

signal index : integer range 0 to 15 := 0; --Current character;
signal temp_chan : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --contians the last address sent in

signal screen_ready : STD_LOGIC := '0'; -- high when all the digits have been pushed to the Digilent screen Used for simulation debugging

signal current_address_reg : STD_LOGIC_VECTOR(28 downto 0);
signal input_valid : STD_LOGIC;
signal output_valid : STD_LOGIC;
signal quotient : STD_LOGIC_VECTOR(55 downto 0);
signal quotient_reg : STD_LOGIC_VECTOR(7 downto 0);

begin

Divider: div_gen_0 PORT MAP (
          aclk => CLK,
          s_axis_divisor_tvalid => input_valid,
          s_axis_divisor_tdata => "00"&max_address,
          s_axis_dividend_tvalid => input_valid,
          s_axis_dividend_tdata => "000"&current_address_reg,
          m_axis_dout_tvalid => output_valid,
          m_axis_dout_tdata => quotient
        );
             
process (CLK, set_max, RST, reset_max)
variable character_number : integer range 0 to 15 := 0;
begin
    if rising_edge(CLK) then
        if (RST='1' or reset_max='1')then
            input_valid<='0';
            progress_state<= wait_new_max;
            character_number:=0;
            quotient_reg<="00000000";
        else
            case progress_state is
                when wait_new_max =>
                    digilent_screen(3, 0) <=X"0";
                    digilent_screen(3, 1) <=X"0";
                    digilent_screen(3, 2) <=X"0";
                    digilent_screen(3, 3) <=X"0";
                    digilent_screen(3, 4) <=X"0";
                    digilent_screen(3, 5) <=X"0";
                    digilent_screen(3, 6) <=X"0";
                    digilent_screen(3, 7) <=X"0";
                    digilent_screen(3, 8) <=X"0";
                    digilent_screen(3, 9) <=X"0";
                    digilent_screen(3, 10) <=X"0";
                    digilent_screen(3, 11) <=X"0";
                    digilent_screen(3, 12) <=X"0";
                    digilent_screen(3, 13) <=X"0";
                    digilent_screen(3, 14) <=X"0";
                    digilent_screen(3, 15) <=X"0";
                    if set_max='1' then
                        progress_state <= divide;
                        current_address_reg<= (others=>'0');
                        character_number:=0;
                   end if;
                when divide =>--Divide state
                    input_valid<='1';
                    if output_valid='1' then
                        quotient_reg <= quotient(31 downto 24); --Get Quotient result
                        input_valid<='0';
                        progress_state <= check;
                    end if;
                when check =>
                    if quotient_reg >= 8 then
                        quotient_reg<=quotient_reg-8;
                        progress_state<=assign_full_character;
                    else
                        progress_state<=assign_part_character;
                    end if;
                when assign_full_character=>
                    digilent_screen(3, character_number) <=X"8";
                    character_number:=character_number+1;
                    progress_state<=check;
                when assign_part_character=>
                    case quotient_reg is
                        when X"0" => digilent_screen(3, character_number) <= X"0";
                        when X"1" => digilent_screen(3, character_number) <= X"1";
                        when X"2" => digilent_screen(3, character_number) <= X"2";
                        when X"3" => digilent_screen(3, character_number) <= X"3";
                        when X"4" => digilent_screen(3, character_number) <= X"4";
                        when X"5" => digilent_screen(3, character_number) <= X"5";
                        when X"6" => digilent_screen(3, character_number) <= X"6";
                        when others => digilent_screen(3, character_number) <= X"7";
                    end case;
                    progress_state<=waitstate;
                    character_number:=0;
                    quotient_reg<="00000000";
                when waitstate =>
                    if (current_address = "0000000000000000000000") then
                        digilent_screen(3, 0) <=X"0";
                        digilent_screen(3, 1) <=X"0";
                        digilent_screen(3, 2) <=X"0";
                        digilent_screen(3, 3) <=X"0";
                        digilent_screen(3, 4) <=X"0";
                        digilent_screen(3, 5) <=X"0";
                        digilent_screen(3, 6) <=X"0";
                        digilent_screen(3, 7) <=X"0";
                        digilent_screen(3, 8) <=X"0";
                        digilent_screen(3, 9) <=X"0";
                        digilent_screen(3, 10) <=X"0";
                        digilent_screen(3, 11) <=X"0";
                        digilent_screen(3, 12) <=X"0";
                        digilent_screen(3, 13) <=X"0";
                        digilent_screen(3, 14) <=X"0";
                        digilent_screen(3, 15) <=X"0";
                        progress_state<=waitstate;
                    elsif (current_address(7) /= current_address_reg(14)) then
                        current_address_reg <= current_address&"0000000";
                        progress_state<=divide;
                    end if;
            end case;
            
            
        end if;
    end if;
end process;

                          
 --Sequentially assign members to their respective places in memory
process (CLK)
begin
    if rising_edge(CLK) then
        case assignment_state is
            -- Check to see if a new channel has come in
            when assign_idle => 
                    assignment_state<=assign_bank;
                    screen_ready <= '0';
            -- assign which row in the digilentscreen array to write to                         
            when assign_bank => 
                    digilent_screen (0, 7) <= Bank_dig0 + 48;
                    digilent_screen (0, 6) <= Bank_dig1 + 48;
                    
                    assignment_state <= assign_track;
              -- write the channel number to the display
              when  assign_track  => 
                    if swap='1' then
                        digilent_screen(0, 9) <= X"11";
                        digilent_screen(0, 10) <= X"12";
                        digilent_screen(1, 9) <= X"13";
                        digilent_screen(1, 10) <= X"14";
                    else
                        digilent_screen(0, 9) <= X"0";
                        digilent_screen(0, 10) <= X"0";
                        digilent_screen(1, 9) <= X"0";
                        digilent_screen(1, 10) <= X"0";
                    end if;
                    digilent_screen (1,7) <= "0000000" & tracknum + 48;
                    assignment_state <= assign_play_states;
                 
              when  assign_play_states  => 
                            for K in 0 to 14 loop
                                if (current_bank/=K)then
                                  if record_reg(K)='1' then
                                  digilent_screen(2,K) <= X"B";
                                  elsif active(K)='0' then
                                  digilent_screen(2,K) <= X"C";
                                  elsif play_reg(K)='1' then
                                  digilent_screen(2,K) <= X"A";
                                  else
                                  digilent_screen(2,K) <= X"9";
                                  end if;
                                else
                                  if record_reg(K)='1' then
                                  digilent_screen(2,K) <= X"F";
                                  elsif active(K)='0' then
                                  digilent_screen(2,K) <= X"10";
                                  elsif play_reg(K)='1' then
                                  digilent_screen(2,K) <= X"E";
                                  else
                                  digilent_screen(2,K) <= X"D";
                                  end if;
                              end if;
                              end loop;
                              if (current_bank/=15)then
                                if record_reg(15)='1' then
                                digilent_screen(2,15) <= X"17";
                                elsif active(15)='0' then
                                digilent_screen(2,15) <= X"18";
                                elsif play_reg(15)='1' then
                                digilent_screen(2,15) <= X"16";
                                else
                                digilent_screen(2,15) <= X"15";
                                end if;
                              else
                                if record_reg(15)='1' then
                                digilent_screen(2,15) <= X"1B";
                                elsif active(15)='0' then
                                digilent_screen(2,15) <= X"1C";
                                elsif play_reg(15)='1' then
                                digilent_screen(2,15) <= X"1A";
                                else
                                digilent_screen(2,15) <= X"19";
                                end if;
                            end if;
                     assignment_state <= assign_idle;
                     screen_ready <= '1';

              when  others  =>      
                                    assignment_state <= assign_idle;
                                    screen_ready <= '0';
        end case;
    end if;
end process;




DC <= temp_dc;
--Example finish flag only high when in done state
FIN <= '1' when (current_state = Done) else
					'0';
--Instantiate SPI Block
 SPI_COMP: SpiCtrl PORT MAP (
          CLK => CLK,
          RST => RST,
          SPI_EN => temp_spi_en,
          SPI_DATA => temp_spi_data,
          CS => CS,
          SDO => SDO,
          SCLK => SCLK,
          SPI_FIN => temp_spi_fin
        );
--Instantiate Delay Block
   DELAY_COMP: Delay PORT MAP (
          CLK => CLK,
          RST => RST,
          DELAY_MS => temp_delay_ms,
          DELAY_EN => temp_delay_en,
          DELAY_FIN => temp_delay_fin
        );
--Instantiate Memory Block
	CHAR_LIB_COMP : charLib
  PORT MAP (
    clka => CLK,
    addra => temp_addr,
    douta => temp_dout
  );
	process (CLK)
	begin
		if(rising_edge(CLK)) then
			case(current_state) is
				--Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
				when Idle => 
					if(EN = '1') then
						current_state <= ClearDC;
						after_page_state <= DigilentScreen;
						temp_page <= "00";
					end if;
				--Set current_screen to constant digilent_init and update the screen.  Go to state Wait1 afterwards
				when Alphabet => 
					current_screen <= digilent_init;
					current_state <= UpdateScreen;
					after_update_state <= Wait1;
				--Wait 4ms and go to ClearScreen
				when Wait1 => 
					temp_delay_ms <= "111111111111"; --4000
					after_state <= ClearScreen;
					current_state <= Transition3; --Transition3 = The delay transition states
				--set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
				when ClearScreen => 
					current_screen <= clear_screen;
					after_update_state <= Wait2;
					current_state <= UpdateScreen;
				--Wait 1ms and go to DigilentScreen
				when Wait2 =>
					temp_delay_ms <= "000000000111"; --1000
					after_state <= DigilentScreen;
					current_state <= Transition3; --Transition3 = The delay transition states
				--Set currentScreen to constant digilent_screen and update the screen. Go to state Done afterwards
				when DigilentScreen =>
					current_screen <= digilent_screen;
					after_update_state <= DigilentScreen;
					--wait for screen_ready then update screen
					if(screen_ready = '0') then
					   current_state <= Wait3;
					else
					   current_state <= UpdateScreen;
			        end if;			        
			    when Wait3 =>
                    temp_delay_ms <= "000000000110"; --1000
                    after_state <= DigilentScreen;
                    current_state <= Transition3; --Transition3 = The delay transition states
                --Set currentScreen to constant digilent_screen and update the screen. Go to state Done afterwards
				--Do nothing until EN is deassertted and then current_state is Idle
				when Done			=>
					if(EN = '0') then
						current_state <= Idle;
				    else
				        current_state <= Wait2;
					end if;
					
				--UpdateScreen State
				--1. Gets ASCII value from current_screen at the current page and the current spot of the page
				--2. If on the last character of the page transition update the page number, if on the last page(3)
				--			then the updateScreen go to "after_update_state" after 
				when UpdateScreen =>
					temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
					if(temp_index = 15) then	
						temp_index <= 0;
						temp_page <= temp_page + 1;
						after_char_state <= ClearDC;
						if(temp_page = "11") then
							after_page_state <= after_update_state;
						else	
							after_page_state <= UpdateScreen;
						end if;
					else
						temp_index <= temp_index + 1;
						after_char_state <= UpdateScreen;
					end if;
					current_state <= SendChar1;
				
				--Update Page states
				--1. Sets DC to command mode
				--2. Sends the SetPage Command
				--3. Sends the Page to be set to
				--4. Sets the start pixel to the left column
				--5. Sets DC to data mode
				when ClearDC =>
					temp_dc <= '0';
					current_state <= SetPage;
				when SetPage =>
					temp_spi_data <= "00100010";
					after_state <= PageNum;
					current_state <= Transition1;
				when PageNum =>
					temp_spi_data <= "000000" & temp_page;
					after_state <= LeftColumn1;
					current_state <= Transition1;
				when LeftColumn1 =>
					temp_spi_data <= "00000000";
					after_state <= LeftColumn2;
					current_state <= Transition1;
				when LeftColumn2 =>
					temp_spi_data <= "00010000";
					after_state <= SetDC;
					current_state <= Transition1;
				when SetDC =>
					temp_dc <= '1';
					current_state <= after_page_state;
				--End Update Page States

				--Send Character States
				--1. Sets the Address to ASCII value of char with the counter appended to the end
				--2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
				--3. Send the byte of data given by the block Ram
				--4. Repeat 7 more times for the rest of the character bytes
				when SendChar1 =>
					temp_addr <= temp_char & "000";
					after_state <= SendChar2;
					current_state <= ReadMem;
				when SendChar2 =>
					temp_addr <= temp_char & "001";
					after_state <= SendChar3;
					current_state <= ReadMem;
				when SendChar3 =>
					temp_addr <= temp_char & "010";
					after_state <= SendChar4;
					current_state <= ReadMem;
				when SendChar4 =>
					temp_addr <= temp_char & "011";
					after_state <= SendChar5;
					current_state <= ReadMem;
				when SendChar5 =>
					temp_addr <= temp_char & "100";
					after_state <= SendChar6;
					current_state <= ReadMem;
				when SendChar6 =>
					temp_addr <= temp_char & "101";
					after_state <= SendChar7;
					current_state <= ReadMem;
				when SendChar7 =>
					temp_addr <= temp_char & "110";
					after_state <= SendChar8;
					current_state <= ReadMem;
				when SendChar8 =>
					temp_addr <= temp_char & "111";
					after_state <= after_char_state;
					current_state <= ReadMem;
				when ReadMem =>
					current_state <= ReadMem2;
				when ReadMem2 =>
					temp_spi_data <= temp_dout;
					current_state <= Transition1;
				--End Send Character States
					
				--SPI transitions
				--1. Set SPI_EN to 1
				--2. Waits for SpiCtrl to finish
				--3. Goes to clear state (Transition5)
				when Transition1 =>
					temp_spi_en <= '1';
					current_state <= Transition2;
				when Transition2 =>
					if(temp_spi_fin = '1') then
						current_state <= Transition5;
					end if;
					
				--Delay Transitions
				--1. Set DELAY_EN to 1
				--2. Waits for Delay to finish
				--3. Goes to Clear state (Transition5)
				when Transition3 =>
					temp_delay_en <= '1';
					current_state <= Transition4;
				when Transition4 =>
					if(temp_delay_fin = '1') then
						current_state <= Transition5;
					end if;
				
				--Clear transition
				--1. Sets both DELAY_EN and SPI_EN to 0
				--2. Go to after state
				when Transition5 =>
					temp_spi_en <= '0';
					temp_delay_en <= '0';
					current_state <= after_state;
				--END SPI transitions
				--END Delay Transitions
				--END Clear transition
			
				when others 		=>
					current_state <= Idle;
			end case;
		end if;
	end process;
	
end Behavioral;