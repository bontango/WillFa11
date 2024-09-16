-- special solenoid trigger
-- bontango 12.2022
-- part of WillFA7
--
-- v 0.1
-- 895KHz input clock ( 1,1uS cycle )
-- fix puls time 60ms ( 53 700)
-- fix recycle time 200ms (179 000)
-- v 0.3 set explicit solenoid levels for each state
-- v 0.4 added debouncer
-- v 0.5 adjustable pulsetime

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity spec_sol_trigger is        
        port(
         clk_in  : in std_logic;               						
			i_Rst_L : in std_logic;     -- Game on
			trigger : in std_logic;
			--pulse_cfg : in std_logic_vector(1 downto 0);
			solenoid : out std_logic
            );
    end spec_sol_trigger;
    ---------------------------------------------------
    architecture Behavioral of spec_sol_trigger is
	 	type STATE_T is ( Idle, Debounce, Pulse, Recycle ); 
		signal state : STATE_T := Idle;     
		signal counter : integer range 0 to 200000;
		signal pulse_time : integer range 0 to 200000;
	begin
	
	-- pulse control
	pulse_time <= 53700; --fix at the moment
--	pulse_time <=    	
--		53700 when pulse_cfg = "11" else --60ms
--		45500 when pulse_cfg = "01" else --50ms
--		36400 when pulse_cfg = "10" else --40ms
--		31800; --35ms

	
	 spec_sol_trigger: process (clk_in, i_Rst_L, trigger)
    begin
		if rising_edge(clk_in) then			
			if i_Rst_L = '0' then --Reset condidition (reset_l)    
			  state <= Idle;
			  solenoid <= '0';
			  counter <= 0;
			else
				case state is
					when Idle =>
						counter <= 0;
						solenoid <= '0';
					   if ( trigger = '1') then
							state <= Debounce;							
						end if;					
						
					when Debounce =>
						solenoid <= '0';
					   if ( trigger = '1') then
							counter <= counter +1;						
							if ( counter > 50) then					
								counter <= 0;
								state <= Pulse; -- stable trigger
							end if;
						else
							counter <= 0;
							state <= Idle;	-- trigger not stable
						end if;					
					
					when Pulse =>
					   if ( counter < pulse_time ) then					
							counter <= counter +1;
							solenoid <= '1';
						else
							counter <= 0;
							solenoid <= '0';
							state <= Recycle;
						end if;
						
					when  Recycle =>
						solenoid <= '0';
					   if ( counter < 179000) then					
							counter <= counter +1;							
						else
							counter <= 0;	
							state <= Idle;
						end if;
				end case;
			end if; --reset				
		end if;	--rising edge		
		end process;
    end Behavioral;