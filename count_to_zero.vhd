---------------------------------------------------------------
-- count clocks, set output to high if count is zero
-- first counter active low
-- second counter actvive high
--
-- v02 two counters active high
---------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

	entity count_to_zero is
		port(        
					 Clock : in std_logic;	      -- system clock
					 clear  : in std_logic;
					 d_in  : in std_logic;	      -- signal we count rising edges
					 count_a :  std_logic_vector(7 downto 0);
					 count_b :  std_logic_vector(8 downto 0);					 
					 d_out_a : out std_logic;		  -- output indicator a 
					 d_out_b : out std_logic		  -- output indicator b 
            );
    end count_to_zero;

  architecture Behavioral of count_to_zero is
	signal reg1 :std_logic;
   signal reg2 :std_logic;
	signal int_count_a :  std_logic_vector(7 downto 0);
	signal int_count_b :  std_logic_vector(8 downto 0);
    
	begin
	 process ( Clock, clear, count_a, count_b )
		begin
		if (clear = '0') then
			int_count_a <= count_a;
			int_count_b <= count_b;
			d_out_a <= '0';
			d_out_b <= '0';
		elsif rising_edge(Clock) then
			reg1  <= d_in;
			reg2  <= reg1;
			if (reg1 and (not reg2)) = '1' then
				-- counter a
				if ( int_count_a > 0) then
					int_count_a <= int_count_a - 1;
					d_out_a <= '0';
				else 
					d_out_a <= '1';	 
				end if;
				-- counter b
				if ( int_count_b > 0) then
					int_count_b <= int_count_b - 1;
					d_out_b <= '0';
				else 
					d_out_b <= '1';	 
				end if;				
			end if;	
		end if;
	end process;
  end Behavioral;				
		