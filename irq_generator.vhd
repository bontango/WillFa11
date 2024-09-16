-- generate IRQ
-- based on counter IC 4020
--
--for use in WillFA
--bontango 01.2023
--
-- v02 slow/fast switch


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity irq_generator is
    Port ( 
			clk : in  STD_LOGIC;
			cpu_irq : in  STD_LOGIC;
			gen_irq : out  STD_LOGIC;
			slow_irq : in  STD_LOGIC
			 );
end irq_generator;


architecture Behavioral of irq_generator is
signal MR	: STD_LOGIC; -- Master reset
signal Q5	: STD_LOGIC;
signal Q7	: STD_LOGIC;
signal Q8	: STD_LOGIC;
signal Q9	: STD_LOGIC;
signal Q10	: STD_LOGIC;
signal counter : STD_LOGIC_VECTOR(13 downto 0) := (others => '0');


begin

Q5 <= counter(5);
Q7 <= counter(7);
Q8 <= counter(8);
Q9 <= counter(9);
Q10 <= counter(10);

count_process: process(clk, cpu_irq, MR, slow_irq)
 begin
	if MR = '1' then --Reset condidition (reset_h)  async reset  
		counter <= (others => '0');
	elsif falling_edge(CLK) then
		counter <= counter + 1;
  end if;
 end process;

--MR <= not(  not cpu_irq or (not Q5));
MR <= cpu_irq and Q5 and clk;
gen_irq <= ( Q7 and Q8 and Q9) when slow_irq = '0' else ( Q10 and Q8 and Q9); --with W15 it is Q10 instead of Q7

end Behavioral;