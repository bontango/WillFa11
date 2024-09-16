-- WillFA init
-- bontango 09.2023
--
-- start delay 
-- v 1.0 -- 1MHz input clock


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity willfa_init is        
        port(
         clk_in  : in std_logic;               						
			i_Rst_L : in std_logic;     -- FPGA Reset					   
			--output 
			done		: out std_logic;    -- set to 1 after delay (active high)
			blanking		: out std_logic    -- set to 0 after delay (active low)
            );
    end willfa_init;
    ---------------------------------------------------
    architecture Behavioral of willfa_init is
	 	type STATE_T is ( Start, Stop ); 
		signal state : STATE_T := Start;    
		signal counter  : integer range 0 to 10000000;   -- delay, for 1s use 1.000.000		
	begin
	
	
	 willfa_init: process (clk_in, i_Rst_L)
    begin		
			if i_Rst_L = '0' then --Reset condidition (reset_l)    
			  state <= Start;
			  blanking <= '1';
			  done <= '0';
			  counter <= 0;
			elsif rising_edge(clk_in) then			
				case state is
					when Start =>
					counter <= counter +1;					
					if ( counter = 500000 ) then --500ms 
						state <= Stop;
						counter <= 0;						
					end if;																													
					when Stop =>
						blanking <= '0';
						done <= '1';
				end case;
			end if; -- rising edge			
		end process;
    end Behavioral;