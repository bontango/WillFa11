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
--v 2.0 fast setting for 1us pulses
--v 2.1 used LOW level clock when not setting plus wait time for setting
--v 3.0 clk50 and seperate input scan

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity flipflops_fast is        
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
    end flipflops_fast;
    ---------------------------------------------------
    architecture Behavioral of flipflops_fast is
	 	type STATE_T is ( Idle, Set1, Set2, Set3 ); 
		signal state : STATE_T := Idle;    
		signal old_ff1_data : std_logic_vector(7 downto 0);				
		signal old_ff2_data : std_logic_vector(7 downto 0);				
		signal old_ff3_data : std_logic_vector(7 downto 0);	
		signal c_count : integer range 0 to 500;	
		constant WAIT_TIME : integer := 30;	--30x20nS -> 600ns
		
		signal ff1_has_changed : std_logic;
		signal ff2_has_changed : std_logic;
		signal ff3_has_changed : std_logic;
		signal ff1_in_set : std_logic;
		signal ff2_in_set : std_logic;
		signal ff3_in_set : std_logic;
	begin
	
	scan_1: process (clk_in, rst, ff1_data_in, ff1_in_set)
   begin
	 	if rst = '1' then --Reset condidition (reset_h)    
			old_ff1_data <= "00000000";		
			ff1_has_changed <= '0';
		elsif rising_edge(clk_in) then
			if (( ff1_in_set = '0') and (ff1_has_changed = '0')) then -- no scan while setting clk on flipflop
				if ( ff1_data_in /= old_ff1_data) then			
					old_ff1_data <= ff1_data_in;
					ff1_has_changed <= '1';
				end if;
			else --wait for setting new data from main process
				if ( ff1_in_set = '1') then
					ff1_has_changed <= '0';
				end if;
			end if;
		end if;
	end process;
	
	scan_2: process (clk_in, rst, ff2_data_in, ff2_in_set)
   begin
	 	if rst = '1' then --Reset condidition (reset_h)    
			old_ff2_data <= "00000000";		
			ff2_has_changed <= '0';
		elsif rising_edge(clk_in) then
			if (( ff2_in_set = '0') and (ff2_has_changed = '0')) then -- no scan while setting clk on flipflop
				if ( ff2_data_in /= old_ff2_data) then			
					old_ff2_data <= ff2_data_in;
					ff2_has_changed <= '1';
				end if;
			else --wait for setting new data from main process
				if ( ff2_in_set = '1') then
					ff2_has_changed <= '0';
				end if;
			end if;
		end if;
	end process;

	scan_3: process (clk_in, rst, ff3_data_in, ff3_in_set)
   begin
	 	if rst = '1' then --Reset condidition (reset_h)    
			old_ff3_data <= "00000000";		
			ff3_has_changed <= '0';
		elsif rising_edge(clk_in) then
			if (( ff3_in_set = '0') and (ff3_has_changed = '0')) then -- no scan while setting clk on flipflop
				if ( ff3_data_in /= old_ff3_data) then			
					old_ff3_data <= ff3_data_in;
					ff3_has_changed <= '1';
				end if;
			else --wait for setting new data from main process
				if ( ff3_in_set = '1') then
					ff3_has_changed <= '0';
				end if;
			end if;
		end if;
	end process;

	main: process (clk_in, rst, ff1_has_changed, ff2_has_changed, ff3_has_changed)
    begin		
			if rst = '1' then --Reset condidition (reset_h)    
			  state <= Idle;
			  sel1 <= '0';
			  sel2 <= '0';
			  sel3 <= '0'; 
			  ff_data_out <= "00000000";
 			  ff1_in_set <= '0';
			  ff2_in_set <= '0';
			  ff3_in_set <= '0';
			  c_count <= 0;
			elsif rising_edge(clk_in) then
				case state is
					-- Idle state wait for change	-----------------------
					when Idle =>											
						if ( ff1_has_changed = '1') then
							ff_data_out <= old_ff1_data;
							sel1 <= '1'; --push data
							ff1_in_set <= '1';
							state <= Set1;							
						elsif ( ff2_has_changed = '1') then
							ff_data_out <= old_ff2_data;							
							sel2 <= '1'; --push data
							ff2_in_set <= '1';
							state <= Set2;
						elsif ( ff3_has_changed = '1') then
							ff_data_out <= old_ff3_data;
							sel3 <= '1'; --push data
							ff3_in_set <= '1';
							state <= Set3;
						end if;						
					-- set FlipFlop 1	-----------------------
					when  Set1 =>
						if c_count < WAIT_TIME then
							c_count <= c_count +1;
						else							
							c_count <= 0;												
							sel1 <= '0';
							ff1_in_set <= '0';
							state <= Idle;
						end if;					
					-- set FlipFlop 2	-----------------------
					when  Set2 =>
						if c_count < WAIT_TIME then
							c_count <= c_count +1;
						else							
							c_count <= 0;												
							sel2 <= '0';
							ff2_in_set <= '0';
							state <= Idle;
						end if;										
					-- set FlipFlop 3	-----------------------
					when  Set3 =>
						if c_count < WAIT_TIME then
							c_count <= c_count +1;
						else							
							c_count <= 0;												
							sel3 <= '0';
							ff3_in_set <= '0';
							state <= Idle;
						end if;										
				end case;
			end if; --reset				
		end process;
    end Behavioral;