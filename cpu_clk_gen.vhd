--
-- generate 1MHz clock for Williams CPU from 16MHz	PLL
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;

	entity cpu_clk_gen is
		port(
                clk_in  : in std_logic;                
                clk_out : out std_logic;
					 shift_clk_out : out std_logic
            );
    end cpu_clk_gen;
	 
   architecture Behavioral of cpu_clk_gen is
	   signal q_cpuClkCount : integer range 0 to 16;		
    begin
		cpu_clk_gen: process (clk_in)
			begin
				if rising_edge(clk_in) then
					if q_cpuClkCount < 15 then		
					--if q_cpuClkCount < 8 then		
						q_cpuClkCount <= q_cpuClkCount + 1;
					else
						q_cpuClkCount <= 0;
					end if;
					
					if q_cpuClkCount < 8 then		
					--if q_cpuClkCount < 4 then		
						clk_out <= '0';
					else
						clk_out <= '1';
					end if;
					
					--280uS shifted clock
					if q_cpuClkCount < 4 or  q_cpuClkCount > 11 then		
					--if q_cpuClkCount < 2 or  q_cpuClkCount > 7 then		
						shift_clk_out <= '0';
					else
						shift_clk_out <= '1';
					end if;
					
				end if;
			end process;
    end Behavioral;				

-- CPU Clock
-- 16 * 70uS
-- CPU frequency 	Counter top 	Counter half-way
-- 894Khz 55 28 (Williams) low 560uS  high 560 -> 1,12uS = 892,8KHz
