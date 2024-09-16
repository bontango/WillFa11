-- 'WillFA11' a Williams SYS11 MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 03.2023
-- www.lisy.dev
--
-- v0.01 migration from WillFA7 Cyclone II to DIY EP4CE15 board based on EP4CE6F17C8N
--			spcial vesion for WillFA11_Test board
-- v0.02 first working version
-- v 03 eeprom 2k
-- v 04 added Soundboard
-- v 05 WillFA11 v0.7 PCB
-- v 06 with some flipflops
-- v 061 read the dips
-- v 062 init flipflops
-- v 063 more boot_phases
-- v 064 with solenoids 1..8 via latch 374 & sound_seg
-- v 065 special solenoids and GameOn bug solved
-- v 066 extend cmos ram & eeprom to 8K to support Data East V2 & V3
-- v 067 added DE special solenoid mapping
-- v 068 make solenoids 1..8 work
-- v 069 special solenoids only activated with Game On
-- v070 mapping WPC/De corrected
-- v071 changed flipflop multiplexer for sound
-- v072 another change for flipflop multiplexer for sound ('flipflops_fast' clocked now with 50MhZ)
-- v080 selection Data East for each gamenumber >=32 ( game_select(5) = 0)
-- v081 lamp_strobes / lamp_returns changed at PIA1 ( PA - PB ) was wrong in pinmame s11.c
-- v082 bug: only one sound => clock multiplexer for sound back to 2MHz, flipflop_fast back to v2.0
-- v083 bug with lamp control => lamp_row (returns) output need to be negated
-- v084 busy dmd always 0
-- v085 boot message for alphanumeric
-- v086 start bootmessage early to prevent digit 1  all segments brightly lit at boot
-- v087 prevent display garbage and (short) solenoid&lamp activation at CPU start
-- v088 prevent sounds at CPU start, corrected chars bootmessage, latest flipflops.vhd from WillFA7
-- TODo
-- CPU & Sound switch
-- W7 jumper via options

-- v90 for HW v0.9 & EP4CE6E22C8N
-- v91 adapted 'read the dips' and v099 eeprom with reduced SPI clock
-- renamed to 1.01
-- v102 flipflop_fast v2.2
-- v103
-- v104 spec sol trigger v05
-- v105 set dmd output to flipflop_fast
-- v106 test 
-- v107 corrected dmd 128x32 ( need HW 0.92 or mod )
-- v108 cpu_irq adjusted
-- v109 irq gen to 2ms (test data east )
-- v110 back to 1mS irq
-- v111 IRQ frequency adjustable with option
-- v112 segments now in RAM (williams_seg14.qip & segments14.mif), added bootmessage for 2xalpha + 2xnumeric ( via gamedef.qip & gamedef.mif )

-- TODO
--chec k fast flipflop
--extend boot message
-- mem prot
					  
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
	
entity WillFA11 is
	port(		
	   -- the FPGA board
		clk_50	: in std_logic; 	-- E1
		reset_sw  : in std_logic; 	-- K6
		LED1		: out std_logic; 	-- J6
		
		-- sram
		BUFFER_E_N		: out std_logic; -- 74HC541 buffer control
		--BUFFER_DATA		: out std_logic_vector(7 downto 0); -- data out (for buffer)
		BUFFER_DATA		: buffer std_logic_vector(7 downto 0); -- data out (for buffer)
		
		--SRAM_ADDR	: out std_logic_vector(17 downto 0); -- address 
		SRAM_ADDR	: buffer std_logic_vector(17 downto 0); -- address 
		SRAM_CE_N   : out std_logic; -- chip select					
		SRAM_OE_N   : out std_logic; -- output enable
		--SRAM_WE_N   : out std_logic; -- write enable		
		SRAM_WE_N   : buffer std_logic; -- write enable		
		SRAM_IO     : in std_logic_vector(7 downto 0); -- data in
		
		-- integrated sound
--		SB_Sound		: out std_logic; 	-- Audio out Sound
--		SB_Speech	: out std_logic; 	-- Audio out Speech
--		Audio_Busy	: in std_logic; 	
--		Audio_TX	: in std_logic; 	
--		Audio_RX	: out std_logic; 	

		-- SPI SD card & EEprom
		CS_SDcard	: 	buffer 	std_logic; 
		CS_EEprom	: 	buffer 	std_logic;
		MOSI			: 	out 	std_logic;
		MISO			: 	in 	std_logic;
		SPI_CLK			: 	out 	std_logic;
						
		--displays
		disp_strobe: out 	std_logic_vector(3 downto 0);
		
		--switches
		sw_strobe: buffer 	std_logic_vector(7 downto 0);
		sw_return: in 	std_logic_vector(7 downto 0);

		--lamps & 'plus'
		lamps: buffer 	std_logic_vector(7 downto 0);
		lamp_strobe_sel: out std_logic; 
		lamp_row_sel: out std_logic;
		lamp_plus_sel: buffer std_logic;		--RTH back to out
		
		--solenoids & diag
		solenoids: out		std_logic_vector(7 downto 0); 
		sol_1_8_sel: buffer std_logic;
		sol_9_16_sel: out std_logic;
		sol_diag_sel: out std_logic;
		
		--sound
		sound_seg: out		std_logic_vector(7 downto 0); 
		sound_seg_sel_1: buffer std_logic;
		sound_seg_sel_2: out std_logic;
		sound_seg_sel_3: out std_logic;
		--SB_SST0: in std_logic;
		
		--Alpha Sements
		alpha: out		std_logic_vector(7 downto 0); 
		alpha_sel_1: out std_logic;
		alpha_sel_2: out std_logic;
		alpha_sel_3: out std_logic;

		-- DMD
		dmd_U42_PA:	in  	std_logic_vector(7 downto 0);
		dmd_U41_PB7:	in		std_logic;
		U41_CA1:	in		std_logic;
		U41_CB1:	in		std_logic;
		U42_CA1:	in		std_logic;
		U42_CB1:	in		std_logic;
		
		-- spec solenoids & spec sol triggers
		SPC_Sol: buffer 	std_logic_vector(6 downto 1);
		SPC_Sol_Trig: in 	std_logic_vector(6 downto 1);
		Flipper: buffer std_logic;
		
		--diag
		Mem_prot: in std_logic;
		Advance: in std_logic;
		up_down: in std_logic;				
		-- Sys11 only (with pull up onb board)
		CPU_Diag_SW: in std_logic; 
		Sound_Diag_SW: in std_logic; 				
		
		--dips WillFA7
		Dip_Ret_1: in std_logic;
		Dip_Ret_2: in std_logic;
		
		-- extra
		--WillFA_Diag_SW	: in std_logic; 
		--Diag_LED_EN_N: out std_logic;
		SB_E_N_3V: out std_logic;
		blanking: buffer std_logic:= '1' --( 3V signal)
		
		);
end;

architecture rtl of WillFA11 is 

signal disp_segments	:  	std_logic_vector(7 downto 0); -- 74HC574 IC18

signal cpu_clk		:  std_logic;  -- 1MHz for Williams
signal shift_clk		:  std_logic;  -- 1MHz shifted for dual mem access (needed?)
signal clk_divider        : std_logic_vector(3 downto 0); -- generate 500KHz for clocking flipflops
signal cpu_clk_div2		:  std_logic;  
signal clk_2		:  std_logic;  -- 2MHz for flipflop sound
signal clk_16		:  std_logic; -- 16MHz from PLL
signal reset_h		: 	std_logic;
signal reset_l	 	: std_logic := '0';
signal boot_phase	: 	std_logic_vector(6 downto 1) := "000000";
signal boot_phase_dig	: 	std_logic_vector(3 downto 0);

signal cpu_addr	: 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	: 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;  --valid memory address
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;

--signal sb_rom_addr	: 	std_logic_vector(15 downto 0);
--signal sb_rom_dout		: 	std_logic_vector(7 downto 0);

-- sram
signal sram_dout	:	std_logic_vector(7 downto 0);
signal sram_cs		:	std_logic;
--signal wr_sram		: 	std_logic;

-- pia
signal pia_irq	:	std_logic;

-- pia0
signal pia0_dout	:	std_logic_vector(7 downto 0);
signal pia0_irq_a	:	std_logic;
signal pia0_irq_b	:	std_logic;
signal pia0_cs		:	std_logic;

-- pia1
signal pia1_dout	:	std_logic_vector(7 downto 0);
signal pia1_irq_a	:	std_logic;
signal pia1_irq_b	:	std_logic;
signal pia1_cs		:	std_logic;
signal lamp_strobes	:	std_logic_vector(7 downto 0);
signal lamp_returns	:	std_logic_vector(7 downto 0);
signal game_lamp_strobes	:	std_logic_vector(7 downto 0);

-- pia2
signal pia2_dout	:	std_logic_vector(7 downto 0);
signal pia2_irq_a	:	std_logic;
signal pia2_irq_b	:	std_logic;
signal pia2_cs		:	std_logic;
signal pia2_ca1		:	std_logic;
signal pia2_cb1		:	std_logic;
signal pia2_pa_o	:	std_logic_vector(7 downto 0);
signal pia2_pb_o	:	std_logic_vector(7 downto 0);

-- pia3 - u41
signal pia3_dout	:	std_logic_vector(7 downto 0);
signal pia3_irq_a	:	std_logic;
signal pia3_irq_b	:	std_logic;
signal pia3_cs		:	std_logic;
signal pia3_pa_o	:	std_logic_vector(7 downto 0);
signal pia3_pb_o	:	std_logic_vector(7 downto 0);

-- pia4
signal pia4_dout	:	std_logic_vector(7 downto 0);
signal pia4_irq_a	:	std_logic;
signal pia4_irq_b	:	std_logic;
signal pia4_cs		:	std_logic;

-- pia5 - u42
signal pia5_dout	:	std_logic_vector(7 downto 0);
signal pia5_irq_a	:	std_logic;
signal pia5_irq_b	:	std_logic;
signal pia5_cs		:	std_logic;
signal pia5_pa_o	:	std_logic_vector(7 downto 0);
signal u42_pb  	:	std_logic_vector(7 downto 0);
signal sound_out  	:	std_logic_vector(7 downto 0);
signal u42_ca2   :	std_logic;
signal u42_cb2   :	std_logic;

-- cmos ram
signal cmos_dout_a	: 	std_logic_vector(7 downto 0);
signal cmos_dout_b	: 	std_logic_vector(7 downto 0);
signal cmos_cs			:	std_logic;
signal cmos_wren			:	std_logic;

--solenoids
signal SPC_Sol_Trig_stable	:	std_logic_vector(6 downto 1); --stable switches spec sol trigger
signal sp_solenoid_trig	:	std_logic_vector(6 downto 1); --6 special solenoids from trigger 
signal sp_sol_DE	:	std_logic_vector(6 downto 1); --6 special solenoids from MPU (DE mapping)
signal sp_solenoid_mapped	:	std_logic_vector(6 downto 1); --6 special solenoid mapping Williams <-> Data East
signal solenoids_1_8	:	std_logic_vector(7 downto 0); 
signal solenoids_9_16	:	std_logic_vector(7 downto 0); 
signal game_solenoids_9_16	:	std_logic_vector(7 downto 0); --solenoid 9-16 signal rom pia
-- diff
signal Enable_N	:	std_logic;
signal GameOn		:	std_logic := '0';
signal gen_irq		:	std_logic;

-- SD card
signal address_sd_card	:  std_logic_vector(16 downto 0);
signal data_sd_card	:  std_logic_vector(7 downto 0);
signal wr_rom			:  std_logic;
signal wr_game_rom			:  std_logic;
signal wr_system_rom			:  std_logic;
signal SDcard_MOSI	:	std_logic; 
signal SDcard_CLK		:	std_logic; 
signal SDcard_error	:	std_logic:='1'; --active low

-- EEprom 
signal address_eeprom	:  std_logic_vector(12 downto 0);
signal data_eeprom	:  std_logic_vector(7 downto 0);
signal wr_ram			:  std_logic;
signal EEprom_MOSI	:	std_logic; 
signal EEprom_CLK		:	std_logic; 
signal eeprom_read_done_l		:	std_logic:='1'; 

-- init & boot message helper
signal g_dig0					:  character;
signal g_dig1					:  character;
signal o_dig0					:  character;
signal o_dig1					:  character;
--signal b_dig0					:  character;
--signal b_dig1					:  character;

-- dip games select and options 
signal game_select 		:  std_logic_vector(5 downto 0);				
signal game_option		: 	std_logic_vector(6 downto 1);
signal dip_strobe 		:  std_logic_vector(5 downto 0);				

--displays
signal game_disp_strobe :	std_logic_vector(3 downto 0);
signal bm_disp_strobe :	std_logic_vector(3 downto 0);

signal bm_disp_data 	:	std_logic_vector(15 downto 0);
signal game_disp_data_L 	:	std_logic_vector(7 downto 0); -- Display Data (a,b,c,d,e,f,g,com)
signal game_disp_data_H 	:	std_logic_vector(7 downto 0); -- Display Data (h,j,k,m,n,p,r,dot)

signal bm_disp_data2 	:	std_logic_vector(15 downto 0);	
signal game_disp_data_L2 	:	std_logic_vector(7 downto 0); -- Display Data' (a,b,c,d,e,f,g,com) -> also BCD
signal game_disp_data_H2 	:	std_logic_vector(7 downto 0); -- Display Data' (h,j,k,m,n,p,r,dot)
	
signal comma12 	: std_logic;
signal comma34		: std_logic;

-- boot message (bm_) helper
signal dig0					:  std_logic_vector(3 downto 0);
signal dig1					:  std_logic_vector(3 downto 0);
signal dig2					:  std_logic_vector(3 downto 0);

-- internal sound 
--signal sound_select		: std_logic_vector(7 downto 0);
--signal sound_HS		: std_logic;

--flipflops
signal ff_lamps		: std_logic_vector(7 downto 0);
signal ff_solenoids	: std_logic_vector(7 downto 0);
signal ff_sound_seg	: std_logic_vector(7 downto 0);
signal ff_alpha	: std_logic_vector(7 downto 0);

signal latch2200_cs	: std_logic;
		
signal SEG7		: std_logic_vector(3 downto 0);
	
--options
signal opt_nvram_init		: std_logic; 
signal opt_trigger_test 		: std_logic; 
signal opt_w7 		: std_logic; 
signal opt_slow_irq 		: std_logic; -- option(6) 1mS (default) or 2mS IRQ length

-- trigger
--signal credit_sw			: std_logic;

-- SW version
constant SW_MAIN : character := '1';
constant SW_SUB1 : character := '1';
constant SW_SUB2 : character := '2';
		
begin

-- init Testboard
LED1 <= '1';
SEG7 <= boot_phase_dig;
--SB_E_N_3V <= '1'; --sound later RTH
SB_E_N_3V <= not u42_cb2;
--SB_E_N_3V <= not u42_pb(1);
--SB_E_N_3V <= not sound_seg_sel_1;

-- options
opt_nvram_init <= game_option(1); -- 0 if option Dip1 is set 
opt_trigger_test <= game_option(2);
opt_w7 <= not game_option(3); -- language option for some games
opt_slow_irq <= not game_option(6); -- == 1 if DIP is ON


--shared SPI bus; SD card only at start of game
MOSI <= SDcard_MOSI when boot_phase(4) = '0' else EEprom_MOSI;
SPI_CLK <= SDcard_CLK when boot_phase(4) = '0' else EEprom_CLK;

-- prevent solenoids from activating at CPU boot
solenoids_9_16 <= "00000000" when Gameon = '0' else game_solenoids_9_16;
-- prevent lamps from activating at CPU boot
lamp_strobes <= "00000000" when Gameon = '0' else game_lamp_strobes;
-- prevent sound from activating at CPU boot
sound_out <= "00000000" when Gameon = '0' else u42_pb;

-- display boot_messages switch over with Gameon
disp_strobe <= bm_disp_strobe when Gameon = '0' else game_disp_strobe;
--RTH debug
--disp_strobe(2) <= bm_disp_strobe(2) when Gameon = '0' else game_disp_strobe(2);
--disp_strobe(0) <= gen_irq;
--disp_strobe(1) <= cpu_irq;
--disp_strobe(3) <= pia_irq;

pia3_pb_o <= NOT bm_disp_data(7 downto 0) when Gameon = '0' else game_disp_data_L;
pia3_pa_o <= NOT bm_disp_data(15 downto 8) when Gameon = '0' else game_disp_data_H;
pia2_pb_o <= NOT bm_disp_data2(7 downto 0) when Gameon = '0' else game_disp_data_L2;
pia5_pa_o <= NOT bm_disp_data2(15 downto 8) when Gameon = '0' else game_disp_data_H2;

-- testfor dmd
--disp_strobe <= game_disp_strobe;
--pia3_pb_o <= game_disp_data_L;
--pia3_pa_o <= game_disp_data_H;
--pia2_pb_o <= game_disp_data_L2;
--pia5_pa_o <= game_disp_data_H2;

reset_l <= boot_phase(5);
reset_h <= (not reset_l);

----------------
-- boot phases
----------------
-- for boot phase to visiualize
boot_phase_dig <= "0000" when boot_phase="000000" else -- phase 0 - in reset
						"0001" when boot_phase="000001" else -- phase 1 - read dips
						"0010" when boot_phase="000011" else -- phase 2 - blanking startdelay						
						"0011" when boot_phase="000111" else -- phase 3 - read SD card
						"0100" when boot_phase="001111" else -- phase 4 - read EEprom(NVRAM)
						"0101" when boot_phase="011111" else -- phase 5 - game running; displays under game control
						"0110" when boot_phase="111111" else -- phase 6 - we have strobes and eeprom_trigger is set						
						"0111"; -- phase 7 , never reached (Error)

--------------------
-- make sure flipflop output are at low level before activating
------------------
solenoids <= "00000000" when boot_phase(2) = '0' else ff_solenoids;
alpha <= "00000000" when boot_phase(2) = '0' else ff_alpha;
sound_seg <= "00000000" when boot_phase(2) = '0' else ff_sound_seg;

-----------------------------------------------
-- activate boot message at boot time
-----------------------------------------------

BM: entity work.boot_message
port map(
	clk		=> clk_50, 	
	-- Control/Data Signals,
   show  => '1', --active at boot time 
	--show error
	is_error => SDcard_error, --active low
	-- input 
	game_select => not game_select,	
	-- output
	strobe	=> bm_disp_strobe,
	disp_data	=> bm_disp_data,
	disp_data2	=> bm_disp_data2,
	-- input (display data) g_dig0 b_dig0 o_dig0
	-- display2	=> ( '1','2','3','4','5','6','7','8'),
	display1	=> ( "WILLFA  "),
	--display2	=> ( 'G', 'A', 'M', 'E',' ',g_dig1, g_dig0, ' '), --game#
	display3	=> ( 'V', 'E', 'R', ' ',SW_MAIN,SW_SUB1,SW_SUB2,' '), -- Version 
	display4	=> ( 'O', 'P', 'T',  ' ', o_dig1, o_dig0, ' ', ' '), -- option setting
	error_disp2 => ( "SD ERR  ")
	);

-----------------------------------------------
-- phase 0: activated by switch on FPGA board	
-----------------------------------------------
META1: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => reset_sw,
	o_Q => boot_phase(1),
   i_Fast_Clk => clk_50
	); 

-----------------------------------------------
-- phase 1: activated by switch on FPGA board	
-- read dips via lamp IOs use as strobes
-----------------------------------------------
RDIPS: entity work.read_the_dips
port map(
	clk_in		=> cpu_clk,
	i_Rst_L  => boot_phase(1),   
	--output 
	game_select	=> game_select,
	game_option	=> game_option,
	-- strobes
	dip_strobe => dip_strobe,
	-- input
	return1 => Dip_Ret_1,
	return2 => Dip_Ret_2,
	-- signal when finished
	done	=> boot_phase(2) -- set to '1' when reading dips is done
	);						
-- use lamp IOs to read dips at start
lamps <= "00" & dip_strobe when boot_phase(2) = '0' else ff_lamps ;

-----------------------------------------------
-- phase 2: activated by init
-- startdelay for init
-- startdelay, give flipflops time to set output low
-- and user to read WillFA bootmessage
-- before activating ( set blanking low)
-----------------------------------------------
WINIT: entity work.willfa_init
port map(
   clk_in => cpu_clk,
	i_Rst_L => boot_phase(2),
	done => boot_phase(3),
   blanking => blanking
	); 

-----------------------------------------------
-- phase 3: activated by 'read_the_dips' after first read
-- read rom data of current game from SD
------------------------------------------------

SD_CARD: entity work.SD_Card
port map(
	i_clk		=> clk_50,	
	-- Control/Data Signals,
   i_Rst_L  => boot_phase(3), -- first dip read finished
	-- PMOD SPI Interface
   o_SPI_Clk  => SDcard_CLK,
   i_SPI_MISO => MISO,
   o_SPI_MOSI => SDcard_MOSI,
   o_SPI_CS_n => CS_SDcard,	
	-- selection
	selection => "00" & not game_select,	
	-- data
	address_sd_card => address_sd_card,
	data_sd_card => data_sd_card,
	wr_rom => wr_rom,
	-- feedback
	SDcard_error => SDcard_error,
	-- control boot phases
	cpu_reset_l => boot_phase(4)
	);	

-----------------------------------------------
-- phase 4: activated by SD card read
-- read eeprom, read/write to ram
----------------------
EEprom: entity work.EEprom
port map(
	i_clk => clk_50,
	address_eeprom	=> address_eeprom,
	data_eeprom	=> data_eeprom,
	wr_ram => wr_ram,
	q_ram => cmos_dout_b,
	-- Control/Data Signals,   
	i_Rst_L  => boot_phase(4),
	-- PMOD SPI Interface
   o_SPI_Clk  => EEprom_CLK,
   i_SPI_MISO => MISO,
   o_SPI_MOSI => EEprom_MOSI,
   o_SPI_CS_n => CS_EEprom,
	-- selection
	selection => game_select(2 downto 0),
	-- write trigger
	w_trigger(4) => '1', --Enter_SW, -- for save within setup sys3
	w_trigger(3) => GameOn, --game is running
	w_trigger(2) => boot_phase(6), -- intial write via ctrl_blanking 5sec after start RTH
	w_trigger(1) => advance,-- for save within setup menue
	w_trigger(0) => opt_trigger_test, -- as trigger for testing
	-- init trigger (no read, RAM will be zero)
	i_init_Flag => opt_nvram_init, -- 0 if option Dip1 is set 
	-- signal when finished
		-- signal when finished
	done	=> boot_phase(5), -- set to '1' when first read of eeprom and write to cmos is done
	o_wr_in_progress => open --eeprom_wr_in_progress
	);	
-----------------------------------------------
-- phase 5: activated by eeprom after first read/write
-- now williams rom take control
-- game starts here
---------------------------------------------------

---------------------
-- count ints
-- indicate game running or not
-- set eeprom trigger via boot_phase(6)
---------------------
COUNT_STROBES: entity work.count_to_zero
port map(   
   Clock => clk_50,
	clear => reset_l,
	d_in => game_disp_strobe(2),
	count_a =>"00011111", -- GAME IS RUNNING (we have strobes) RTHTEST "00001111"
	count_b =>"111111111", -- eeprom trigger	
	d_out_a => GameOn,
	d_out_b => boot_phase(6)
);	


----------------------
-- Diag
----------------------
--sys11 use IRQ with OR
pia2_ca1 <= not ( not advance or not cpu_irq); 
pia2_cb1 <= not ( not up_down or not cpu_irq); 


--DIAGSTABLE: entity work.Cross_Slow_To_Fast_Clock
--port map(
--   i_D => diag,
--	o_Q => diag_stable,
--   i_Fast_Clk => cpu_clk
--	);
--	
--DIAGSW: entity work.one_pulse_only
--port map(
--   sig_in => diag_stable,
--	sig_out => cpu_nmi,
--   clk_in => cpu_clk,
--	rst => reset_l
--	);


----------------------
-- Flipper activation
----------------------
Flipper <= GameOn and not Enable_N; --Flipper

----------------------
-- displays
----------------------
game_disp_strobe <= pia2_pa_o(3 downto 0);


-- IRQ signals ( should be '0')

pia_irq <= pia0_irq_a or pia0_irq_b 
			  or pia1_irq_a or pia1_irq_b
			  or pia2_irq_a or pia2_irq_b
			  or pia3_irq_a or pia3_irq_b
			  or pia4_irq_a or pia4_irq_b
			  or pia5_irq_a or pia5_irq_b;			  
cpu_irq <= not pia_irq and gen_irq;			  

------------------
-- address decoding 
------------------
--
--/*---------------------------
--/  Memory map for main CPU
--/----------------------------*/
--static MEMORY_READ_START(s11_readmem)
--  { 0x0000, 0x1fff, MRA_RAM},
--  { 0x2100, 0x2103, pia_r(S11_PIA0) },
--  { 0x2400, 0x2403, pia_r(S11_PIA1) },
--  { 0x2800, 0x2803, pia_r(S11_PIA2) },
--  { 0x2c00, 0x2c03, pia_r(S11_PIA3) },
--  { 0x3000, 0x3003, pia_r(S11_PIA4) },
--  { 0x3400, 0x3403, pia_r(S11_PIA5) },
--  { 0x4000, 0xffff, MRA_ROM },
--MEMORY_END
--
--static MEMORY_WRITE_START(s11_writemem)
--  { 0x0000, 0x1fff, MWA_RAM }, /* CMOS */
--  { 0x2100, 0x2103, pia_w(S11_PIA0) },
--  { 0x2200, 0x2200, latch2200},
--  { 0x2400, 0x2403, pia_w(S11_PIA1) },
--  { 0x2800, 0x2803, pia_w(S11_PIA2) },
--  { 0x2c00, 0x2c03, pia_w(S11_PIA3) },
--  { 0x3000, 0x3003, pia_w(S11_PIA4) },
--  { 0x3400, 0x3403, pia_w(S11_PIA5) },
--  { 0x4000, 0xffff, MWA_ROM },
--MEMORY_END			    

--cmos ram
cmos_cs <= '1' when cpu_addr(15 downto 13) = "000" and cpu_vma='1' else '0'; --0x0000 0x1fff 8K ( 2K Williams, 8K used for DE V2&V3)
--pias
pia0_cs   <= '1' when cpu_addr(15 downto 2) = "00100001000000" and cpu_vma='1' else '0'; --2100 Solenoids 9-16 & Sound
latch2200_cs <= '1' when cpu_addr = x"2200" and cpu_vma='1' else '0'; --2200 Solenoids 1-8
pia1_cs   <= '1' when cpu_addr(15 downto 2) = "00100100000000" and cpu_vma='1' else '0'; --2400 Lamps
pia2_cs   <= '1' when cpu_addr(15 downto 2) = "00101000000000" and cpu_vma='1' else '0'; --2800 BCD & Diag
pia3_cs   <= '1' when cpu_addr(15 downto 2) = "00101100000000" and cpu_vma='1' else '0'; --2C00 Alpha
pia4_cs   <= '1' when cpu_addr(15 downto 2) = "00110000000000" and cpu_vma='1' else '0'; --3000 Switches
pia5_cs   <= '1' when cpu_addr(15 downto 2) = "00110100000000" and cpu_vma='1' else '0'; --3400 Widgets


--write enable - RTH do we need mem_prot?
cmos_wren <= cmos_cs and not cpu_rw; -- and not mem_prot_active;
 

-- Bus control
 cpu_din <=    	
   pia0_dout when pia0_cs = '1' else
	pia1_dout when pia1_cs = '1' else
	pia2_dout when pia2_cs = '1' else
	pia3_dout when pia3_cs = '1' else
	pia4_dout when pia4_cs = '1' else	
	pia5_dout when pia5_cs = '1' else
	cmos_dout_a when cmos_cs = '1' else	
	sram_dout;
	
	
-- for game select to visiualize
CONVG: entity work.byte_to_char
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "11" & game_select,
	dig0 => g_dig0,
	dig1 => g_dig1,
	dig2 => open
	);
-- for willfa option to visiualize
CONVO: entity work.byte_to_char
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "11" & game_option,
	dig0 => o_dig0,
	dig1 => o_dig1,
	dig2 => open
	);
						
--CONVB: entity work.byte_to_char
--port map(
--	clk_in	=> clk_50, 	
--	mybyte	=> "1111" & not boot_phase_dig,
--	dig0 => b_dig0,
--	dig1 => b_dig1,
--	dig2 => open
--	);
		

U9: entity work.cpu68
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
	nmi => '0' --cpu_nmi
);

-- solenoids 1..8 via latch 374
-- we use a 373 as OE is permanently set
U28: entity work.FlipFlop_74HCT373
port map(
	clk			=> clk_50,
	enable  		=> Gameon,
	data_in		=> cpu_dout,
	data_out		=> solenoids_1_8,
	latch			=> latch2200_cs,
	output_en	=> '1'
	);		

-- PIA 0 (2100) Solenoids & Sound
--	 PA0-7 Sound Select Outputs (sound latch)
--	 PB0-7 Solenoid 9-16 
--	 CA1	 
--  CA2   Sound H.S. ?
--	 CB1	 
--  CB2   Enable Special Solenoids
U10: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia0_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia0_dout, 
	irqa => pia0_irq_a,   
	irqb => pia0_irq_b,    
	pa_i => x"00",
	pa_o => open, --sound_select,
	ca1 => '1', 
	ca2_i => '1',
	ca2_o => open, --sound_HS,
	pb_i => x"00", 
	pb_o => game_solenoids_9_16,
	cb1 => '0', 
	cb2_i => '1',
	cb2_o => Enable_N,
	default_pb_level => '0'  -- output level when configured as input
);
-- PIA 1 (2400) Lamps DE:11D
--	 PA0-7 Lamp Matrix Return (rows)
--	 PB0-7 Lamp Matrix Strobe/Drive (columns)
--	 CA1	
--  CA2  WPC:SS6 DE:SS3
--	 CB1	
--  CB2  WPC:SS5 DE:SS5
U54: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia1_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia1_dout, 
	irqa => pia1_irq_a,   
	irqb => pia1_irq_b,    
	pa_i => x"FF",
	pa_o => lamp_returns,
	ca1 => '0',
	ca2_i => '1',
	ca2_o => sp_sol_DE(3), 
	pb_i => x"FF",
	pb_o => game_lamp_strobes,
	cb1 => '0', 
	cb2_i => '1',
	cb2_o => sp_sol_DE(5), 
	default_pb_level => '0'  -- output level when configured as input
);


-- PIA 2 (2800) BCD & Diag DE:11B
--	 PA0-3 Digit Select 1-16
--	 PA4 Diagnostic LED
--	 PA5-6 NC
--	 PA7 (I) Jumper W7
--	 PB0-7 Digit BCD
--	 CA1	(I) Diagnostic Advance
--  CA2  Comma 3+4
--	 CB1	(I) Diagnostic Up/dn
--  CB2  Comma 1+2
U51: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia2_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia2_dout, 
	irqa => pia2_irq_a,   
	irqb => pia2_irq_b,    
	pa_i => opt_w7 & "0000000",
	pa_o => pia2_pa_o,
	ca1 => pia2_ca1,
	ca2_i => '1',
	ca2_o => comma34,
	pb_i => x"FF",
	pb_o => game_disp_data_L2,
	cb1 => pia2_cb1,
	cb2_i => '1',
	cb2_o => comma12,
	default_pb_level => '0'  -- output level when configured as input
);

-- PIA 3 U41 (2c00) Alpha Display DE:9B 
--	 PA0-7 Display Data (h,j,k,m,n,p,r,dot), DMD data
--	 PB0-7 Display Data (a,b,c,d,e,f,g,com)  DMD ctrl (strobe, reset, busy(I))
--	 CA1	Widget I/O LCA1 *
--  CA2  WPC:SS2 DE:SS6
--	 CB1	Widget I/O LCB1
--  CB2  WPC:SS3 DE:SS2
U41: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia3_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia3_dout, 
	irqa => pia3_irq_a,   
	irqb => pia3_irq_b,    
	pa_i => x"FF",
	pa_o => game_disp_data_H,
	ca1 => not U41_CA1, -- dmd
	ca2_i => '1',
	ca2_o => sp_sol_DE(6), 
	pb_i => not dmd_U41_PB7 & not dmd_U42_PA(6 downto 3) & "000", --Data East DMD: PB7:busy & DMD stat of 128x32
	pb_o => game_disp_data_L,
	cb1 => not U41_CB1, -- dmd
	cb2_i => '1',
	cb2_o => sp_sol_DE(2),
	default_pb_level => '0'  -- output level when configured as input
);

-- PIA 4 (3000) Switches DE:8H
--	 PA0-7 Switch Input (row)
--  PB0-7 Switch Drivers (column)
--	 CA1	 GND
--  CA2   WPC:SS1 DE:SS4
--	 CB1	 GND
--  CB2   WPC:SS4 DE:SS1
U38: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia4_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia4_dout, 
	irqa => pia4_irq_a,   
	irqb => pia4_irq_b,    
	pa_i => sw_return,
	pa_o => open,
	ca1 => '0',
	ca2_i => '1',
	ca2_o => sp_sol_DE(4),
	pb_i => x"FF",
	pb_o => sw_strobe,	
	cb1 => '0',
	cb2_i => '1',
	cb2_o => sp_sol_DE(1),
	default_pb_level => '0'  -- output level when configured as input
);

-- PIA 5 - U42 (3400) Display Widget DE:7B 
--	 PA0-7 Display Data' (h,j,k ,m,n,p,r,dot), DMD status(input)
--  PB0-7 Widget I/O MD0-MD7
--	 CA1	 Widget I/O MCA1 -> input!
--  CA2   Widget I/O MCA2 -> input!
--	 CB1	 Widget I/O MCB1
--  CB2   Widget I/O MCB2
U42: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia5_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia5_dout, 
	irqa => pia5_irq_a,   
	irqb => pia5_irq_b,    
	pa_i => not dmd_U42_PA, -- fix for 128x32 ?
	pa_o => game_disp_data_H2,
	ca1 => not u42_ca1, --dmd
	ca2_i => '1',
	ca2_o => u42_ca2,
	pb_i => x"FF", -- u42_pb in/out ? RTH x"FF",
	pb_o => u42_pb,
	cb1 => not u42_cb1, -- dmd
	cb2_i => '1',
	cb2_o => u42_cb2,
	default_pb_level => '0'  -- output level when configured as input
);


	 

-- PLL takes 50MHz clock on mini board and puts out 16MHz	
PLL: entity work.williams_pll
port map(
	inclk0 => clk_50,
	c0 => clk_16,
	c1 => clk_2
	);
	
clock_gen: entity work.cpu_clk_gen
port map(   
	clk_in => clk_16,
	clk_out	=> cpu_clk,
	shift_clk_out	=> shift_clk
);

p_clk_divider: process(cpu_clk)
begin
	if(rising_edge(cpu_clk)) then
	 clk_divider   <= clk_divider + 1;
	end if;
end process p_clk_divider;
cpu_clk_div2 <= clk_divider(0);


irq_gen: entity work.irq_generator
port map(   
	clk => not cpu_clk,	-- phi2	
	cpu_irq => cpu_irq,
	gen_irq => gen_irq,
	slow_irq => opt_slow_irq
);

----------------------
-- cmos ram 2K (dual port)
----------------------
U25: entity work.cmos
	port map(
		address_a	=> cpu_addr(12 downto 0),
		address_b   => address_eeprom,
		clock		=> clk_50,
		data_a		=> cpu_dout,
		data_b		=> data_eeprom,
		wren_a 		=> cmos_wren,
		wren_b 		=> wr_ram,
		q_a			=> cmos_dout_a,
		q_b			=> cmos_dout_b
);


------------------
-- special solenoids
-- mapping for Data East needed
-- option(6) (OFF=='1') means Williams  ; (ON == '0') means Data East
------------------
--Hardware is wired DE stile
-- Sol1 Pin3
-- Sol2 Pin4
-- Sol3 Pin6 
-- Sol4 Pin7
-- Sol5 Pin8
-- Sol6 Pin9
-- additional HW mapping needed for WPC stile
-- Sol1 Pin7
-- Sol2 Pin4
-- Sol3 Pin3
-- Sol4 Pin6
-- Sol5 Pin8
-- Sol6 Pin9
----------------------------------
--WPC:SS1(Pin7) - activated by sp_sol_DE(4) -> DE_Sol 4 OK
--WPC:SS2(Pin4) - activated by sp_sol_DE(6) -> map to DE_Sol 2
--WPC:SS3(Pin3) - activated by sp_sol_DE(2) -> map to DE_Sol 1
--WPC:SS4(Pin6) -activated by sp_sol_DE(1) -> map to DE_Sol 3
--WPC:SS5(Pin8) -activated by sp_sol_DE(5) -> DE_Sol 5 OK
--WPC:SS6(Pin9) -activated by sp_sol_DE(3) -> map to DE_Sol 6
--
-- WE ALSO NEED to combine this with SW mapping
sp_solenoid_mapped(1) <= sp_sol_DE(1) when game_select(5) = '0' else sp_sol_DE(2);  
sp_solenoid_mapped(2) <= sp_sol_DE(2) when game_select(5) = '0' else sp_sol_DE(6);  
sp_solenoid_mapped(3) <= sp_sol_DE(3) when game_select(5) = '0' else sp_sol_DE(1); 
sp_solenoid_mapped(4) <= sp_sol_DE(4); --OK
sp_solenoid_mapped(5) <= sp_sol_DE(5); --OK
sp_solenoid_mapped(6) <= sp_sol_DE(6) when game_select(5) = '0' else sp_sol_DE(3);

SPC_Sol(1) <= ( sp_solenoid_trig(1) or not sp_solenoid_mapped(1) ) and Flipper;
SPC_Sol(2) <= ( sp_solenoid_trig(2) or not sp_solenoid_mapped(2) ) and Flipper;
SPC_Sol(3) <= ( sp_solenoid_trig(3) or not sp_solenoid_mapped(3) ) and Flipper;
SPC_Sol(4) <= ( sp_solenoid_trig(4) or not sp_solenoid_mapped(4) ) and Flipper;
SPC_Sol(5) <= ( sp_solenoid_trig(5) or not sp_solenoid_mapped(5) ) and Flipper;
SPC_Sol(6) <= ( sp_solenoid_trig(6) or not sp_solenoid_mapped(6) ) and Flipper;
------------------
META_SPECIAL1: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(1),
	o_Q => SPC_Sol_Trig_stable(1),
   i_Fast_Clk => clk_50
	); 
SPECIAL1: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(1),
	solenoid => sp_solenoid_trig(1)
	); 

META_SPECIAL2: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(2),
	o_Q => SPC_Sol_Trig_stable(2),
   i_Fast_Clk => clk_50
	); 	
SPECIAL2: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(2),
	solenoid => sp_solenoid_trig(2)
	); 
	
META_SPECIAL3: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(3),
	o_Q => SPC_Sol_Trig_stable(3),
   i_Fast_Clk => clk_50
	); 	
SPECIAL3: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(3),
	solenoid => sp_solenoid_trig(3)
	); 
	
META_SPECIAL4: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(4),
	o_Q => SPC_Sol_Trig_stable(4),
   i_Fast_Clk => clk_50
	); 	
SPECIAL4: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(4),
	solenoid => sp_solenoid_trig(4)
	); 
	
META_SPECIAL5: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(5),
	o_Q => SPC_Sol_Trig_stable(5),
   i_Fast_Clk => clk_50
	); 	
SPECIAL5: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(5),
	solenoid => sp_solenoid_trig(5)
	); 

META_SPECIAL6: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => SPC_Sol_Trig(6),
	o_Q => SPC_Sol_Trig_stable(6),
   i_Fast_Clk => clk_50
	); 	
SPECIAL6: entity work.spec_sol_trigger
port map(
   clk_in => cpu_clk,
	i_Rst_L => GameOn,
   trigger => SPC_Sol_Trig_stable(6),
	solenoid => sp_solenoid_trig(6)
	); 
	
--	
-- SRAM controller 128Kbit
SRAM: entity work.sram
port map(
	clock => clk_50,
   reset => boot_phase(1), --needed at SD read
	address_w => "0" & address_sd_card,
	address_a => cpu_addr,
	address_b => x"0000", --sb_rom_addr,
	data => data_sd_card,
	wren => wr_rom,
	q_a	=> sram_dout,
	q_b	=> open, --sb_rom_dout,
	dual_clk => shift_clk,			
	
	-- hardware
	BUFFER_E_N => BUFFER_E_N,
	BUFFER_DATA => BUFFER_DATA,
		
	SRAM_ADDR => SRAM_ADDR,
	SRAM_CE_N => SRAM_CE_N,
	SRAM_OE_N => SRAM_OE_N,
	SRAM_WE_N => SRAM_WE_N,
	SRAM_IO => SRAM_IO
	);
	

--SOUNDBOARD: entity work.WSYS11_SB
--port map(
--		clk_50 => clk_50,
--		cpu_clk => not cpu_clk,		-- SB has shifted clock
--		reset_l	=> reset_l,
--		Audio_O	=> open, --Audio_O,
--		DFP_tx	=> open, --DFP_tx,
--		
--		snd_ctl_i => sound_select,
--		sb_1ms => gen_irq,
--		sound_HS => sound_HS,
--		
--		sb_rom_addr => sb_rom_addr,
--		sb_rom_dout => sb_rom_dout,
--		
--		sb_debug_addr => open, --debug_addr,
--		sb_debug_dout => open, --debug_data,
----		sb_debug_signals(0) => debug_signal(2),
----		sb_debug_signals(1) => debug_signal(3),
----		sb_debug_signals(2) => debug_signal(4),
----		sb_debug_signals(3) => debug_signal(5),
----		sb_debug_signals(4) => debug_signal(6),
----		sb_debug_signals(5) => debug_signal(7),
--		nmi => cpu_nmi --test
--); 

--------------------
-- Flip Flop Solenoids 1..16 & Diag
-- IC4, IC1, IC5
------------------
FF_SOLS: entity work.flipflops
port map(
	clk_in => cpu_clk_div2, 
	rst => '0', --blanking,
	sel1 => sol_1_8_sel,
	sel2 => sol_9_16_sel,
	sel3 => sol_diag_sel,		
	ff_data_out	=> ff_solenoids,
	ff1_data_in => solenoids_1_8,	
	ff2_data_in => solenoids_9_16,
	ff3_data_in => pia2_pb_o
);

--enable IC22
--Diag_LED_EN_N <= '0'; permanent enabled with HW09
--------------------
-- Flip Flop Lamps & Diag LEDs
-- IC14, IC19, IC22
------------------
FF_LAMPSS: entity work.flipflops
-- FF_LAMPSS: entity work.flipflops_fast
port map(
	clk_in => cpu_clk_div2,
	rst => '0', --blanking,
	sel1 => lamp_strobe_sel,
	sel2 => lamp_row_sel,
	sel3 => lamp_plus_sel,		
	ff_data_out	=> ff_lamps,
	ff1_data_in => lamp_strobes,
	ff2_data_in => not lamp_returns,
	ff3_data_in(0) => comma12,
	ff3_data_in(1) => comma34,
	ff3_data_in(2) => SEG7(1),
	ff3_data_in(3) => SEG7(2),
	ff3_data_in(4) => SEG7(3),
	ff3_data_in(5) => SEG7(0),
	ff3_data_in(6) => not SDcard_error, --activ low 
	ff3_data_in(7) => pia2_pa_o(4) --diag LED 
);


--------------------
-- Flip Flop alpha segments
-- IC11, IC13, IC16
------------------
--FF_ALPHAS: entity work.flipflops
FF_ALPHAS: entity work.flipflops_fast
port map(
	clk_in => clk_50, --cpu_clk_div2,
	rst => '0', --blanking,
	sel1 => alpha_sel_1,
	sel2 => alpha_sel_2,
	sel3 => alpha_sel_3,		
	ff_data_out	=> ff_alpha,
	ff1_data_in(0) => pia3_pb_o(7), --PB0-7 Display Data (a,b,c,d,e,f,g,com)
	ff1_data_in(1) => pia3_pb_o(6),
	ff1_data_in(2) => pia3_pb_o(5),
	ff1_data_in(3) => pia3_pb_o(4),
	ff1_data_in(4) => pia3_pb_o(3),
	ff1_data_in(5) => pia3_pb_o(2),
	ff1_data_in(6) => pia3_pb_o(1), 
	ff1_data_in(7) => pia3_pb_o(0),
	ff2_data_in(0) => pia3_pa_o(7), --PA0-7 Display Data (h,j,k,m,n,p,r,dot)
	ff2_data_in(1) => pia3_pa_o(6),
	ff2_data_in(2) => pia3_pa_o(5),
	ff2_data_in(3) => pia3_pa_o(4),
	ff2_data_in(4) => pia3_pa_o(3),
	ff2_data_in(5) => pia3_pa_o(2),
	ff2_data_in(6) => pia3_pa_o(1),
	ff2_data_in(7) => pia3_pa_o(0),
	ff3_data_in(0) => pia5_pa_o(7), --Display Data' (h,j,k ,m,n,p,r,dot)
	ff3_data_in(1) => pia5_pa_o(6),
	ff3_data_in(2) => pia5_pa_o(5),
	ff3_data_in(3) => pia5_pa_o(4),
	ff3_data_in(4) => pia5_pa_o(3),
	ff3_data_in(5) => pia5_pa_o(2),
	ff3_data_in(6) => pia5_pa_o(1),
	ff3_data_in(7) => pia5_pa_o(0)
);

--------------------
-- Flip Flop Sound ( Widget I/O ) & display bcd
-- IC8, IC10, IC18
------------------
FF_SOUNDS: entity work.flipflops_fast
port map(
	clk_in => clk_50, 
	rst => '0', -- needed at boot time
	sel1 => sound_seg_sel_1,
	sel2 => sound_seg_sel_2,
	sel3 => sound_seg_sel_3,		
	ff_data_out	=> ff_sound_seg,	
   ff1_data_in(0) => u42_ca2, --will reset Soundboard 1J21-18
	ff1_data_in(1) => '0', -- cpu_rw,
	ff1_data_in(2) => '0', --u42_ca1,
	ff1_data_in(3) => '0', --u41_ca1,
	ff1_data_in(4) => reset_l,
	ff1_data_in(5) => u42_cb2, --SB strobe
	ff1_data_in(6) => '0', --u42_cb1,
	ff1_data_in(7) => '0', --u41_cb1,
	ff2_data_in(0) => sound_out(7),
	ff2_data_in(1) => sound_out(6),
	ff2_data_in(2) => sound_out(5),
	ff2_data_in(3) => sound_out(4),
	ff2_data_in(4) => sound_out(3),
	ff2_data_in(5) => sound_out(2),
	ff2_data_in(6) => sound_out(1),
	ff2_data_in(7) => sound_out(0),
	ff3_data_in(0) => pia2_pb_o(7), -- bcd & Display Data' (a,b,c,d,e,f,g,com)
	ff3_data_in(1) => pia2_pb_o(6),
	ff3_data_in(2) => pia2_pb_o(5),
	ff3_data_in(3) => pia2_pb_o(4),
	ff3_data_in(4) => pia2_pb_o(3),
	ff3_data_in(5) => pia2_pb_o(2),
	ff3_data_in(6) => pia2_pb_o(1),
	ff3_data_in(7) => pia2_pb_o(0)
);
	
end rtl;
		