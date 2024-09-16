-- byte to char
-- converts input byte
-- to 3 digit char
-- ( 50MHz input clock)

LIBRARY ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

    entity byte_to_char is        
        port(
            clk_in  : in std_logic;               
				mybyte  : in std_logic_vector(7 downto 0);
				dig0	: out character;
				dig1	: out character;
				dig2	: out character
            );
	 FUNCTION convert_dig(S : std_logic_vector(3 downto 0)) RETURN character IS
		BEGIN
			CASE S IS
				WHEN "0000" => RETURN '0';
				WHEN "0001" => RETURN '1';
				WHEN "0010" => RETURN '2';
				WHEN "0011" => RETURN '3';
				WHEN "0100" => RETURN '4';
				WHEN "0101" => RETURN '5';
				WHEN "0110" => RETURN '6';
				WHEN "0111" => RETURN '7';
				WHEN "1000" => RETURN '8';
				WHEN "1001" => RETURN '9';
				WHEN OTHERS => RETURN '0';
			END CASE;
		END convert_dig;				
    end byte_to_char;
    ---------------------------------------------------
    architecture Behavioral of byte_to_char is
		type STATE_T is ( INIT, HUND1, HUND2,TEN1, TEN2, ONE1, ONE2, CONVERT); 
		signal state : STATE_T := INIT;     
		signal bytetoconvert : integer range 0 to 255;
		signal hundreds : integer range 0 to 15;
		signal tens : integer range 0 to 15;
		signal ones : integer range 0 to 15;
		signal h_dig0 : std_logic_vector(3 downto 0);
		signal h_dig1 : std_logic_vector(3 downto 0);
		signal h_dig2 : std_logic_vector(3 downto 0);
	begin
	
	 byte_to_char: process (clk_in, mybyte)
    begin
			if rising_edge(clk_in) then
				case state is
				when INIT =>
					bytetoconvert <= to_integer(unsigned(not mybyte));
					state <= HUND1;
					
				when HUND1 =>
					hundreds <= bytetoconvert / 100;					
					state <= HUND2;
					
				when HUND2 =>						
					bytetoconvert <= bytetoconvert- ( 100 * hundreds);
					state <= TEN1;
				
				when TEN1 =>
					tens <= bytetoconvert / 10;					
					state <= TEN2;

				when TEN2 =>						
					bytetoconvert <= bytetoconvert- ( 10 * tens);
					state <= ONE1;

				when ONE1 =>
					ones <= bytetoconvert;					
					state <= ONE2;
					
				when ONE2 =>
					h_dig0 <= std_logic_vector(to_unsigned(ones, h_dig0'length));
					h_dig1 <= std_logic_vector(to_unsigned(tens, h_dig1'length));
					h_dig2 <= std_logic_vector(to_unsigned(hundreds, h_dig2'length));
					state <= CONVERT;				

				when CONVERT =>
					dig0 <= convert_dig(h_dig0);
					dig1 <= convert_dig(h_dig1);
					dig2 <= convert_dig(h_dig2);					
					state <= INIT;				
					
				end case;	
			end if; --rising edge		
		end process;
    end Behavioral;