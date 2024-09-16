-- scan up to three 8bit inputs
-- and set flip flop accordently
-- part of  WillFA7
-- bontango 12.2022
--
-- v 1.0
-- 895KHz input clock
-- v1.01 init of ff_data_out
-- v1.1 no check of changed data, we just put data in to out
-- v1.2 used high level clock when not setting
-- v1.3 used LOW level clock when not setting plus 'double length' clock impuls
-- v1.4 clk divider external

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;

    entity flipflops is        
        port(
            clk_in  : in std_logic;               						
				rst		: in std_logic;   
				--output 
				sel1			: out std_logic;
				sel2			: out std_logic;
				sel3			: out std_logic;				
				ff_data_out		: out std_logic_vector(7 downto 0);				
				-- input
				ff1_data_in		: in std_logic_vector(7 downto 0);				
				ff2_data_in		: in std_logic_vector(7 downto 0);				
				ff3_data_in		: in std_logic_vector(7 downto 0)				
            );
    end flipflops;
    ---------------------------------------------------
    architecture Behavioral of flipflops is
	 	type STATE_T is ( Start, S_setFF_1, S_setFF_2, S_setFF_3, 
					UnSet1, UnSet2, UnSet3,
					Set1, Set2, Set3 ); 
		signal state : STATE_T := Start;    
	begin
	 flipflops: process (clk_in, rst, ff1_data_in, ff2_data_in, ff3_data_in)
    begin
		if rising_edge(clk_in) then			
			if rst = '1' then --Reset condidition (reset_h)    
			  state <= Start;
			  sel1 <= '0';
			  sel2 <= '0';
			  sel3 <= '0'; 
			  ff_data_out <= "00000000";
			else
				case state is
					when Start =>
						sel1 <= '0';
						sel2 <= '0';
						sel3 <= '0'; 
						ff_data_out <= "00000000";					   
						state <= S_setFF_1;						
					-- set FlipFlop 1	-----------------------
					when S_setFF_1 =>						
						ff_data_out <= ff1_data_in;
						state <= Set1;
					when  Set1 =>
						sel1 <= '1';-- push data to FlipFlop					
						state <= UnSet1;												
					when  UnSet1 =>
						sel1 <= '0'; 
						state <= S_setFF_2;						
					-- set FlipFlop 2	-----------------------
					when S_setFF_2 =>						
						ff_data_out <= ff2_data_in;
						state <= Set2;
					when  Set2 =>
						sel2 <= '1';-- push data to FlipFlop					
						state <= UnSet2;						
					when  UnSet2 =>
						sel2 <= '0'; 
						state <= S_setFF_3;												
					-- set FlipFlop 3	-----------------------
					when S_setFF_3 =>						
						ff_data_out <= ff3_data_in;
						state <= Set3;
					when  Set3 =>
						sel3 <= '1';-- push data to FlipFlop
						state <= UnSet3;						
					when  UnSet3 =>
						sel3 <= '0'; 
						state <= S_setFF_1;												
				end case;
			end if; --reset				
		end if;	--rising edge		
		end process;
    end Behavioral;