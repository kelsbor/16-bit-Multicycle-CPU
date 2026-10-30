-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ula_pkg.all;

entity datapath is
    port (
        clk  : in  std_logic;
        reg_write : in std_logic;
        reset : in std_logic;
        
        pc_current : out std_logic_vector(31 downto 0);
        instruction_out : out std_logic_vector(31 downto 0);
        ula_result : out std_logic_vector(15 downto 0);

        zero : out std_logic;
        overflow : out std_logic;
        cout : out std_logic
    );
end entity datapath;

architecture datapath_behaviour of datapath is 
    
    signal s_pc_current, s_pc_next : std_logic_vector(31 downto 0);

    signal s_instruction : std_logic_vector(31 downto 0);

    signal s_read_data1, s_read_data2 : std_logic_vector(31 downto 0);
    signal s_write_data : std_logic_vector(31 downto 0);

    signal s_ula_result : std_logic_vector(31 downto 0);
    signal s_zero, s_overflow, s_cout : std_logic;

    signal pc_next_16 : std_logic_vector(15 downto 0);
    signal const_4_16: std_logic_vector(15 downto 0) := x"0004";

    signal ula_result_16 : std_logic_vector(15 downto 0);
    signal ula_zero : std_logic;
    signal ula_of : std_logic;
    signal ula_cout : std_logic;

begin   

    inst_pc : entity work.pc 
      port map (
        clk => clk,
        reset => reset,
        pc_in => s_pc_next,
        pc_out => s_pc_current
      );

    ula_pc_inst : ula
      port map (
        A => s_pc_current(15 downto 0),
        B => const_4_16,
        ULACtl => "010",
        R => pc_next_16,
        Zero => open,
        Overflow => open,
        Cout => open
      );

    s_pc_next <= x"0000" & pc_next_16;

    inst_imem : entity work.instruction_memory
      port map (
        pc_out => s_pc_current,
        instruction_out => s_instruction
      );

    inst_regbank : entity work.register_bank
      port map (
        clk => clk,
        reset => reset,
        reg_write => reg_write,
        read_reg1 => s_instruction(25 downto 21),
        read_reg2 => s_instruction(20 downto 16),
        write_reg => s_instruction(15 downto 11),
        write_data => s_write_data,
        read_data1 => s_read_data1,
        read_data2 => s_read_data2
      );

    ula_main_inst : ula
      port map (
        A => s_read_data1 (15 downto 0),
        B => s_read_data2 (15 downto 0),
        ULACtl => s_instruction (2 downto 0),
        R => ula_result_16,
        Zero => ula_zero,
        Overflow => ula_of,
        Cout => ula_cout
      );

    s_write_data <= x"0000" & ula_result_16;
      
    pc_current <= s_pc_current;
    instruction_out <= s_instruction;
    ula_result <= ula_result_16;
    zero <= ula_zero;
    overflow <= ula_of;
    cout <= ula_cout;

end architecture datapath_behaviour;
