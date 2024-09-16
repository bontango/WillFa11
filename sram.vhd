--# sram controller for IS61LV2568L 256K x 8 HIGH-SPEED CMOS STATIC RAM
--# combined with a 74HC541 for data in/out
--# 
--# v0.1 based on https://github.com/chkrr00k/sram-controller/blob/master/sram.vhd
--#
--# for use in WillFA11
--# bontango April 2023
-- v0.3 dual port for read


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram is 
	port (
		clock 	: in std_logic; -- clock in
		reset		: in std_logic; -- reset async
		
		address_w	: in std_logic_vector(17 downto 0); -- address for write (256K max)
		data     : in std_logic_vector(7 downto 0); -- data in
		address_a	: in std_logic_vector(15 downto 0); -- address for read (64K) area a
		address_b	: in std_logic_vector(15 downto 0); -- address for read (64K) area b
		q_a		   : out std_logic_vector(7 downto 0); -- data out area a
		q_b		   : out std_logic_vector(7 downto 0); -- data out area b
		wren		: in std_logic; -- write enable
		dual_clk	: in std_logic; -- for dispatch between area a & b
		
		-- hardware
		BUFFER_E_N		: out std_logic; -- 74HC541 buffer control
		BUFFER_DATA		: out std_logic_vector(7 downto 0); -- data out (for buffer)
		
		SRAM_ADDR	: out std_logic_vector(17 downto 0); -- address 
		SRAM_CE_N   : out std_logic; -- chip select					
		SRAM_OE_N   : out std_logic; -- output enable
		SRAM_WE_N   : out std_logic; -- write enable		
		SRAM_IO     : in std_logic_vector(7 downto 0) -- data in
				
	);
end entity;

architecture behav of sram is
	signal S_ACTION : std_logic; -- [0 - read] [1 - write]	
	
begin

	
	RamController : process(clock, reset)
	begin
		if(reset = '0') then -- async reset			
			SRAM_CE_N<='1'; -- disables the chip
		elsif rising_edge(clock) then -- high clock state (do something!)
			SRAM_CE_N <= '0';      -- enables the chip	
			if wren = '0'  then -- READ
				if dual_clk = '0' then
					q_a <= SRAM_IO; -- read the data
					SRAM_ADDR <= "00" & address_a;  -- notify the address
				else
					q_b <= SRAM_IO; -- read the data
					SRAM_ADDR <= "01" & address_b;  -- notify the address			
				end if;
				S_ACTION <= '0'; -- tells the fsm to read
			elsif wren = '1'  then -- WRITE
			   BUFFER_DATA <= data; -- write the data
				SRAM_ADDR <= address_w;  -- notify the address
				S_ACTION <= '1'; -- tells the fsm to write				
			end if;
		end if;
	end process;
	
	FSM : process(S_ACTION)
	begin
		SRAM_OE_N <= '1'; -- output disabled
		SRAM_WE_N <= '1'; -- write disabled
		BUFFER_E_N <= '1'; -- buffer disabled
		if(S_ACTION = '0') then
			--read
			SRAM_OE_N <= '0';
		else
			--write
			SRAM_WE_N <= '0';
			BUFFER_E_N <= '0';
		end if;
	end process;
	
end architecture;

