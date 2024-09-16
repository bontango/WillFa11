-- detect switch
-- input: strobe and return of matrix
-- output: is_closed
-- Williams version
-- bontango 03.01.2023

Library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity detect_sw is 
   port(	   
		sw_strobe : in std_logic; -- strobe line of switch (active high)
		sw_return : in std_logic; -- return line of switch (active high)
		is_closed :out  std_logic    -- will go high if switch is closed
   );
end detect_sw;
architecture Behavioral of detect_sw is  
begin  
 process(sw_strobe, sw_return)
		begin
			if sw_strobe = '1' then 
				if ( sw_return = '1') then
					is_closed <= '1';
				else	
					is_closed <= '0';					
				end if;
			end if;			
		end process;
    end Behavioral;				
