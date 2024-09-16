-- boot message on Williams Display
-- part of  WillFA11
-- bontango 01.2024
--
-- v 1.4

LIBRARY ieee;
USE ieee.std_logic_1164.all;

package instruction_buffer_type is
	type DISPLAY_T is array (0 to 7) of character;	
end package instruction_buffer_type;

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.instruction_buffer_type.all;

    entity boot_message is        
        port(
            clk  : in std_logic;             
				show   : in  std_logic;		
				is_error  : in  std_logic;		--active low
				-- input
				game_select : in std_logic_vector(5 downto 0);
				-- display data
			   display1			: in  DISPLAY_T;
				--display2			: in  DISPLAY_T;
				display3			: in  DISPLAY_T;
				display4			: in  DISPLAY_T;
				error_disp2		: in  DISPLAY_T;
				--output (display control)
				strobe: out 	std_logic_vector(3 downto 0);
				disp_data: out 	std_logic_vector(15 downto 0);
				disp_data2: out 	std_logic_vector(15 downto 0)
            );   	
	end boot_message;	
    ---------------------------------------------------	 
    architecture Behavioral of boot_message is
		  signal count : integer range 0 to 50001 := 0;
		  signal digit : integer range 0 to 15 := 0;
		  signal phase : integer range 0 to 23 := 0;
		  signal address_a : std_logic_vector(6 downto 0);
		  signal address_b : std_logic_vector(6 downto 0);
		  signal addr_def_a : std_logic_vector(9 downto 0);
		  signal addr_def_b : std_logic_vector(6 downto 0);
		  
		  signal alpha_line1 : std_logic_vector(15 downto 0);
		  signal alpha_line2 : std_logic_vector(15 downto 0);
		  signal numeric_line2 : std_logic_vector(7 downto 0);
		  
		  type num_segment_def_t is array (0 to 15) of std_logic_vector(7 downto 0); --quartus wants 16 elements not 10 ???
		  -- segment definition 0..9
		  signal num_segment_def : num_segment_def_t := ( x"3F", x"06", x"5B", x"4F", x"66",x"6D",x"7D",x"07",x"7F",x"6F"
																		 ,x"00",x"00",x"00",x"00",x"00",x"00");
		  signal display_type : std_logic_vector(7 downto 0);
		  signal disptype_pos: integer range 0 to 1023;		  
		  signal game_name : std_logic_vector(63 downto 0);
		  signal game_name_pos: integer range 0 to 255;

	 begin
	 disp_data <= alpha_line1 when display_type = "00" else not alpha_line1;
	 disp_data2 <= alpha_line2 when display_type = "00" else "00000000" & (not numeric_line2);
	 disptype_pos <= 16 * to_integer(unsigned(game_select));									 
	 addr_def_a <= std_logic_vector(to_unsigned(disptype_pos, 10));
	 game_name_pos <= ( 2 * to_integer(unsigned(game_select)) +1 );									 
	 addr_def_b <= std_logic_vector(to_unsigned(game_name_pos, 7));
	 
  boot_message: process (clk, show, is_error)
    variable ascii : integer range 0 to 127;
    begin
			if ( show = '0') then  -- Asynchronous reset
				--   output and variable initialisation
				strobe <= "0000";
				count <= 0;
				digit <= 0;
				phase <= 0;
				address_a <= (others => '1'); -- last seg definiton is "00000"
				address_b <= (others => '1');
			elsif rising_edge(clk) then
				-- inc count for next round
				-- 50MHz input we have a clk each 20ns
				-- phases are 56uS which is a count of 2800
				-- first phase bcd 0xff (anti flicker)
				-- then 19 phases with digit 
				-- results in 1,1mS per digit strobe
				count <= count +1;
				if ( count = 2800) then 					     
					phase <= phase +1;
					count <= 0;
				end if;	
				if ( phase > 19 ) then
					strobe <= std_logic_vector( to_unsigned((digit +1),4));
					phase <= 0;
					-- overflow?
					if ( digit = 15) then
						digit <= 0;
						strobe <= "0000";
					else
						digit <= digit +1;
					end if;	
				end if;

				if ( phase = 0) then
					address_a <= (others => '1'); -- last seg definiton is "00000"
					address_b <= (others => '1');		
				else		
				 case display_type(1 downto 0) is
					-------------------------------------------------------------------------------------------
					-- 2x16 alphanumeric
					-------------------------------------------------------------------------------------------									 
				  when  "00" => 
					case digit is 		
					when 0 to 7 => 		
								address_a <= std_logic_vector( to_unsigned(character'pos(display1(digit)),7));
								address_b <= std_logic_vector( to_unsigned(character'pos(display3(digit)),7));
					when 8 to 15 => 		
								if ( is_error = '0' ) then			
									address_a <= std_logic_vector( to_unsigned(character'pos(error_disp2(digit)),7));												
								else
									address_a <= game_name((((digit-8) * 8)+6) downto ((digit-8) * 8));			
									--address_a <= std_logic_vector( to_unsigned(character'pos(display2(digit)),7));
								end if;	
								address_b <= std_logic_vector( to_unsigned(character'pos(display4(digit)),7));
					when OTHERS =>
						address_a <= (others => '1');						
						address_b <= (others => '1');		
					end case; --case digit
					-------------------------------------------------------------------------------------------
					-- 2x7 alphanumeric plus 2x7 numeric
					-------------------------------------------------------------------------------------------					
				 when  "01" => 
					case digit is 						 
					when 1 to 7 => 		
								address_a <= std_logic_vector( to_unsigned(character'pos(display1(digit)),7));
								ascii := to_integer( to_unsigned(character'pos(display3(digit)),7));
								if ((ascii > 47 ) and ( ascii < 58) ) then
									numeric_line2 <= num_segment_def(ascii-48);
								else
									numeric_line2 <= "00000000";
								end if;
								--numeric_line2 <= num_segment_def( to_integer( to_unsigned(character'pos(display3(digit)),7)) - 48);
					when 9 to 15 => 		
								if ( is_error = '0' ) then											
									address_a <= std_logic_vector( to_unsigned(character'pos(error_disp2(digit)),7));			
								else
									address_a <= game_name((((digit-8) * 8)+6) downto ((digit-8) * 8));			
									--address_a <= std_logic_vector( to_unsigned(character'pos(display2(digit)),7));
								end if;	
								ascii := to_integer( to_unsigned(character'pos(display4(digit)),7));
								if ((ascii > 47 ) and ( ascii < 58) ) then
									numeric_line2 <= num_segment_def(ascii-48);
								else
									numeric_line2 <= "00000000";
								end if;								
								--numeric_line2 <= num_segment_def( to_integer( to_unsigned(character'pos(display4(digit)),7)) - 48);								
					when OTHERS =>
						address_a <= (others => '1');						
						address_b <= (others => '1');		
						numeric_line2 <= (others => '1');		
					end case; --case digit				 
				 when OTHERS =>
				  end case; --case display type
				end if; --phase	
			end if; --rising edge		
		end process;
		
----------------------
-- segment definition in rom
-- load via segment14.mif file
----------------------
SEGMENTS: entity work.williams_seg14
	port map(
		address_a	=> address_a,
		address_b	=> address_b,
		clock		=> clk,
		q_a			=> alpha_line1,
		q_b			=> alpha_line2
);

----------------------
-- game definition in rom
-- load via gamedef.mif file
-- 16 bytes each per game
-- first byte is display type
-- bytes 16..31 is game name to view
----------------------
GAMEDEF: entity work.gamedef
	port map(
		address_a	=> addr_def_a,
		address_b	=> addr_def_b,
		clock		=> clk,
		q_a			=> display_type,
		q_b			=> game_name
);
		
    end Behavioral;