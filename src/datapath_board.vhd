-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use work.datapath_pkg.all;

entity datapath_board is
    port (
		  CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(3 downto 0);
        SW       : in  std_logic_vector(17 downto 0);
        
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        HEX4     : out std_logic_vector(6 downto 0);
        HEX5     : out std_logic_vector(6 downto 0);
        HEX6     : out std_logic_vector(6 downto 0);
        HEX7     : out std_logic_vector(6 downto 0);
        
        LEDG     : out std_logic_vector(4 downto 0);
		  LEDR     : out std_logic_vector(2 downto 0)
    );
end entity datapath_board;

architecture hardware of datapath_board is

    signal s_btn_step_sync: std_logic_vector(2 downto 0) := (others => '0');
	 signal s_rst_sync: std_logic_vector(1 downto 0) := (others => '0');
	 signal s_step_en: std_logic;
    signal s_reset: std_logic;

    signal s_pc: std_logic_vector(15 downto 0);
    signal s_ir: std_logic_vector(15 downto 0);
    signal s_ula_res: std_logic_vector(15 downto 0);
	 signal s_mdr: std_logic_vector(15 downto 0);
    signal s_mux_hex4_7: std_logic_vector(15 downto 0);

begin
    process(CLOCK_50)
	 begin
	 	 if rising_edge(CLOCK_50) then
		 	 s_btn_step_sync <= s_btn_step_sync(1 downto 0) & (not KEY(0));
			 s_rst_sync <= s_rst_sync(0) & (not KEY(1));
	 	 end if;
	 end process;

    s_reset <= s_rst_sync(1);
	 s_step_en <= s_btn_step_sync(1) and not (s_btn_step_sync(2)) and (not s_reset);
	 
    datapath_inst : entity work.datapath
        port map (
            clk             => CLOCK_50,
				step_en			 => s_step_en,
            reset           => s_reset,
            
            pc_current      => s_pc,
            instruction_out => s_ir,
            ula_result      => s_ula_res,
            
				mdr_out => s_mdr, 
				state_out => LEDG, 
		  
            zero            => LEDR(0),
            overflow        => LEDR(1),
            cout            => LEDR(2) 
        );
	 
	 -- SW(17)='1' -> MDR | SW(17)='0' e SW(16)='1' -> IR | ambos '0' -> AluOut
	 s_mux_hex4_7 <= s_mdr     when SW(17) = '1' else
	                 s_ir      when SW(16) = '1' else
	                 s_ula_res;
	 
    disp_inst : display_logic
        port map (
            val_hex0_3 => s_pc,
            val_hex4_7 => s_mux_hex4_7,              
            HEX0    => HEX0,
            HEX1    => HEX1,
            HEX2    => HEX2,
            HEX3    => HEX3,
            HEX4    => HEX4,
            HEX5    => HEX5,
            HEX6    => HEX6,
            HEX7    => HEX7 
        );

end architecture hardware;