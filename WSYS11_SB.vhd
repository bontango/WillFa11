-- Top level file for a Williams compatible Soundboard
-- Type1 and Type2 used in Williams System3 .. System7
-- by bontango www.lisy.dev
-- 
--
-- HW SYS11 
-- Version 0.1 - initial version based on WISOF

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WSYS11_SB is
port(

		clk_50	: in std_logic; 		
		cpu_clk	: in std_logic; 
		
		reset_l	: in std_logic;
		Audio_O	: out std_logic;
		DFP_tx	: out std_logic;
		
		snd_ctl_i :	in 	std_logic_vector(7 downto 0);
		sb_1ms : in std_logic;
		sound_HS : in std_logic;
		
		sb_rom_addr	: 	out std_logic_vector(15 downto 0);
		sb_rom_dout		: 	in std_logic_vector(7 downto 0);

		sb_debug_addr	: 	out std_logic_vector(15 downto 0);
		sb_debug_dout		: 	out std_logic_vector(7 downto 0);
		sb_debug_signals		: 	out std_logic_vector(5 downto 0);
		nmi : in std_logic
		
);
end WSYS11_SB;


architecture rtl of WSYS11_SB is

signal uart_clk	: std_logic; -- 9600 baud clock for uart

signal reset_h		: std_logic;

signal audio		: std_logic_vector(7 downto 0);

signal clk_12		: std_logic;
signal clk55516		: std_logic;
signal dig55516		: std_logic;
signal speech55516		: std_logic_vector(15 downto 0);


signal cpu_addr	: std_logic_vector(15 downto 0);
signal cpu_din		: std_logic_vector(7 downto 0);
signal cpu_dout	: std_logic_vector(7 downto 0);
signal cpu_rw		: std_logic;
signal cpu_vma		: std_logic;
signal cpu_irq		: std_logic;
signal cpu_nmi		: std_logic;

signal soundrom_addr	:  std_logic_vector(10 downto 0);
signal rom_dout	: std_logic_vector(7 downto 0);
signal rom_cs		: std_logic;

signal ram_dout	: std_logic_vector(7 downto 0);
signal ram_cs		: std_logic;
signal ram_we		: std_logic;

signal pia_dout	: std_logic_vector(7 downto 0);
signal pia_cs		: std_logic;
signal pia_irq_a	: std_logic := '1';
signal pia_irq_b	: std_logic := '1';


	-- speech
signal send_flag	:  std_logic:='0';
signal DFcmd_cmd	:  std_logic_vector(7 downto 0);
signal DFcmd_par1	:  std_logic_vector(7 downto 0);
signal DFcmd_par2	:  std_logic_vector(7 downto 0);	
	
signal speech_ctrl :  std_logic_vector(30 downto 0);
	
-- Bank select
signal bank_select			:  std_logic;
signal s11s_bank0			:  std_logic;
signal s11s_bank1 		:  std_logic;
signal U21_cs			:  std_logic;
signal U22_cs			:  std_logic;
signal bank_sel_addr :  std_logic_vector(1 downto 0);	
	-- nmi
signal diag				:	std_logic; 
signal diag_stable	:	std_logic; 

begin

--debug
sb_debug_dout  <= cpu_din when cpu_rw = '1' else cpu_dout; 
--sb_debug_addr <= cpu_addr;
sb_debug_addr <= speech55516;
sb_debug_signals(0) <= clk55516;
sb_debug_signals(1) <= dig55516;
sb_debug_signals(2) <= pia_cs;
sb_debug_signals(3) <= nmi;
--sb_debug_signals(4) <= U21_cs;
--sb_debug_signals(5) <= U22_cs;

reset_h <= not reset_l;
diag <= '1'; -- NMI

----------------
-- boot phases
-- read rom from SD
-- then start CPU
----------------
--META1: entity work.Cross_Slow_To_Fast_Clock
--port map(
--   i_D => reset_sw,
--	o_Q =>  reset_l,
--   i_Fast_Clk => clk_50
--	); 
	
	
-- PIA IRQ outputs both assert CPU IRQ input
cpu_irq <= pia_irq_a or pia_irq_b;

-- Address decoding 
ram_cs <= '1' when cpu_addr(15 downto 11) = "00000" and cpu_vma='1' else '0'; --0x0000 0x07ff 2K ( 4K in pinmame?)
pia_cs   <= '1' when cpu_addr(15 downto 2) = "00100000000000" and cpu_vma='1' else '0'; --2000

-- extern via second area of SRAM
-- SB uses bank switching: two roms with 2 banks of 16KByte each 
-- bank selection with d-flipflop at 0x1000 using D0&D1
bank_select <= '1' when cpu_addr = "0001000000000000" and cpu_vma='1' else '0'; --1000 
-- address room for SB CPU
U22_cs   <= '1' when cpu_addr(15 downto 14) = "10" and cpu_vma='1' else '0'; --0x8000, 0xbfff S11S_BANK0
U21_cs   <= '1' when cpu_addr(15 downto 14) = "11" and cpu_vma='1' else '0'; --0xc000, 0xffff S11S_BANK1
-- for SD ram memory map is
-- U21_L 0-16K
-- U21_H 16-32K
-- U22_L 32-48K
-- U22_H 48-64K
bank_sel_addr <= 	"00" when U21_cs='1' and s11s_bank1='0' else
						"01" when U21_cs='1' and s11s_bank1='1' else
						"10" when U22_cs='1' and s11s_bank0='0' else
						"11";

sb_rom_addr <= bank_sel_addr & cpu_addr(13 downto 0);
rom_dout <= sb_rom_dout;	

-- Bus control
cpu_din <= 
	pia_dout when pia_cs = '1' else
	ram_dout when ram_cs = '1' else
	rom_dout;
	

Bank_SEL_1: entity work.RisingEdge_DFlipFlop_AsyncResetLow
port map(
		Q => s11s_bank0, --: out std_logic;    
      Clk => bank_select,
      reset => reset_l,
      D => cpu_dout(0)
);	
Bank_SEL_2: entity work.RisingEdge_DFlipFlop_AsyncResetLow
port map(
		Q => s11s_bank1, --: out std_logic;    
      Clk => bank_select,
      reset => reset_l,
      D => cpu_dout(1)
);	
	
-- speech ctrl
-- speech_ctrl 0 is speech (-> MP3-Player), 1 is 'other'		
-- starting with sound #30 down to sound #0

--speech_ctrl <= "1111111111111000000000000000000";
speech_ctrl <= "1111111111111111111111111111111"; -- no speech
--"0000010000000001011110111110011" when game_sel = "111111" else  --Mars
--"0001000001100011011000110110011" when game_sel = "111110" else --Volcano
--"0000000000111111010111111111011" when game_sel = "111101" else  --Black Hole						
--"0011111110100101101111111111111" when game_sel = "111100" else  --Devils Dare
--"0000000000011111111111111111111" when game_sel = "111011" else  --Rocky
--"1111111111111111111111111111111" when game_sel = "111010" else  --Striker
--"1111111111111111111111111111111" when game_sel = "111001" else  --Q*Bert's Quest
--"1111111111111111111111111111111" when game_sel = "111000" else  --Caveman
---- speech_ctrl <= "0000011111111011111111111111101"; --Caveman
----"0000000000000000000000000000000" when game_sel = "110111" else  --numbers as wav
--"1111111111111111111111111111111"; -- no speech
	
-- prepare date for MP3 Player	      	  
-- Folder selection wav files
DFcmd_cmd <= X"0F"; -- cmd for folder to playback
DFcmd_par1 <= X"40"; -- folder 64 - Test (numbers as wav)
--X"0A" when game_sel = "111111" else  -- folder 10 Mars
--X"0C" when game_sel = "111110" else -- folder 12 Volcano
--X"0E" when game_sel = "111101" else  -- folder 14 Black Hole						
--X"12" when game_sel = "111100" else  -- folder 18 Devils Dare
--X"14" when game_sel = "111011" else  -- folder 20 - Rocky
--X"17" when game_sel = "111010" else  -- folder 23 - Striker
--X"19" when game_sel = "111001" else  -- folder 25 - Q*Bert's Quest
--X"3F" when game_sel = "111000" else  -- folder 63 - Caveman
----X"40" when game_sel = "110111" else  -- folder 64 - Test (numbers as wav)
--X"00"; 
--
-- there is no sound 000 with MP3 Player, so we start with sound 100
DFcmd_par2 <= std_logic_vector (unsigned(snd_ctl_i));
--send_flag <= pia_cb1 and not speech_ctrl(to_integer(unsigned(snd_ctl_i)));
	
	
-- Real hardware uses a 6802 which is a 6800 with internal oscillator and 128 byte RAM
CPU: entity work.cpu68
port map(
	clk => cpu_clk,
	rst => reset_h,
	rw => cpu_rw,
	vma => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold => '0',
	halt => '0',
	irq => cpu_irq,
	nmi => nmi
);

-- 2K RAM for SB
RAM: entity work.SB_RAM
port map(
	address => cpu_addr(10 downto 0),
	clock => cpu_clk,
	data => cpu_dout,
	wren => not cpu_rw,
	q => ram_dout
	);

	
--/* PIA 0 (sound 2000) S11 */
-- /* subType 0 and 4 for S9 and S11S */
-- /* in  : A/B,CA/B1,CA/B2 */ soundlatch_r, 0, PIA_UNUSED_VAL(0), 0, 0, 0,
-- /* out : A/B,CA/B2       */ 0, DAC_0_data_w, hc55516_0_clock_w, hc55516_0_digit_w,
-- /* irq : A/B             */ s11s_piaIrq, s11s_piaIrq
PIA: entity work.pia6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_dout, 
	irqa => pia_irq_a,   
	irqb => pia_irq_b,    
	pa_i => snd_ctl_i, -- /* PA0 - PA7 (I) Sound Select Input (soundlatch) */
	pa_o => open,    
	ca1 => sound_HS,    -- /* CA1       (I) Sound H.S */
	ca2_i => '1',    
	ca2_o => clk55516, --sb_debug_signals(4), --open,  -- /* CA2       55516 Clk */  
	pb_i => x"00",   
	pb_o => audio,    -- /* PB0 - PB7 DAC */
	cb1 => sb_1ms,   -- /* CB1       (I) 1ms */ 
	cb2_i => '0',  
	cb2_o => dig55516, --sb_debug_signals(5), --open, -- /* CB2       55516 Dig */
	default_pb_level => '0'  -- output level when configured as input   
);



DFP_send: entity work.DFPlayer_Mini_CMD 
port map(   
			DFcmd_cmd => DFcmd_cmd,
			DFcmd_par1 => DFcmd_par1,
			DFcmd_par2 => DFcmd_par2,
         send_flag => send_flag,
         clk => uart_clk,
         rst => reset_l,
         txd => DFP_tx			
);

-- 9600 baud send clock
uart_gen: entity work.uart_clk_gen 
port map(   
	clk_in => clk_50,
	uart_clk_out	=> uart_clk
);

DIAGSTABLE: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => diag,
	o_Q => diag_stable,
   i_Fast_Clk => cpu_clk
	);
	
--DIAGSW: entity work.one_pulse_only
--port map(
--   sig_in => diag_stable,
--	--sig_out => cpu_nmi,
--	sig_out => pia_cb1,
--   clk_in => cpu_clk,
--	rst => reset_l
--	);
	
	

-- Delta Sigma DAC
HC55564_1: entity work.hc55564
port map(
   clk   	=> clk_12,
   cen 	=> clk55516,
   bit_in   	=> dig55516,
   sample_out   	=> speech55516
	);
	

-- Delta Sigma DAC
--Audio_DAC: entity work.dac
--port map(
--   clk_i   	=> clk_50,
--   res_n_i 	=> reset_l,
--   dac_i   	=> audio,
--   dac_o   	=> audio_o
--	);

-- Delta Sigma DAC
Speech_DAC: entity work.dac
generic map (
	msbi_g	=> 15
)
port map(
   clk_i   	=> clk_50,
   res_n_i 	=> reset_l,
   dac_i   	=> speech55516,
   dac_o   	=> audio_o
	);

-- PLL takes 50MHz clock on mini board and puts out 12MHz	
PLL: entity work.williams_sb_pll
port map(
	inclk0 => clk_50,
	c0 => clk_12
	);
	
end rtl;
		