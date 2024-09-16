--v01 with data out '0' if enable = '0'

library ieee;
use ieee.std_logic_1164.all;

entity FlipFlop_74HCT373 is
    generic (
        DATA_WIDTH : natural := 8
    );
    port (
        clk       : in  std_logic;
        enable    : in  std_logic;
        data_in   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        latch     : in  std_logic;
        output_en : in  std_logic
    );
end entity FlipFlop_74HCT373;

architecture Behavioral of FlipFlop_74HCT373 is
    signal internal_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                if latch = '1' then
                    internal_data <= data_in;
                elsif output_en = '1' then
                    data_out <= internal_data;
                end if;
				else
				   data_out <= (others => '0');
            end if;
        end if;
    end process;
end architecture Behavioral;
