-- FPGA projects using VHDL/ VHDL 
-- fpga4student.com
-- VHDL code for D Flip FLop
-- VHDL code for Rising edge D flip flop with Asynchronous Reset low 
Library IEEE;
USE IEEE.Std_logic_1164.all;

entity RisingEdge_DFlipFlop_AsyncResetLow is 
   port(
      Q : out std_logic;    
      Clk :in std_logic;  
      reset: in std_logic;  
      D :in  std_logic    
   );
end RisingEdge_DFlipFlop_AsyncResetLow;
architecture Behavioral of RisingEdge_DFlipFlop_AsyncResetLow is  
begin  
 process(Clk,reset)
 begin 
     if(reset='0') then 
   Q <= '0';
     elsif(rising_edge(Clk)) then
   Q <= D; 
  end if;      
 end process;  
end Behavioral; 