-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

entity datapath_tb is
end entity datapath_tb;

architecture test of datapath_tb is

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '1';

    signal pc_current      : std_logic_vector(15 downto 0);
    signal instruction_out : std_logic_vector(15 downto 0);
    signal ula_result      : std_logic_vector(15 downto 0);
    signal mdr_out         : std_logic_vector(15 downto 0);
    signal state_out       : std_logic_vector(4 downto 0);
    signal zero            : std_logic;
    signal overflow        : std_logic;
    signal cout            : std_logic;

    constant clk_period       : time := 20 ns;
    constant program_cycles   : natural := 81;
    signal sim_finished       : boolean := false;

begin

    dut: entity work.datapath
        port map (
            clk             => clk,
            reset           => reset,
            pc_current      => pc_current,
            instruction_out => instruction_out,
            ula_result      => ula_result,
            mdr_out         => mdr_out,
            state_out       => state_out,
            zero            => zero,
            overflow        => overflow,
            cout            => cout
        );

    -- Clock de 50 MHz
    clk_process: process
    begin
        while not sim_finished loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    process
    begin
        -- Carregue ram_init.mif na RAM do simulador antes de rodar.
        -- A RAM le o endereco zero na descida do clock, ainda em reset.
        wait until falling_edge(clk);
        wait for 1 ns;
        reset <= '0';

        -- O programa atual completa uma volta em 81 ciclos.
        wait until rising_edge(clk);
        wait for (program_cycles - 1) * clk_period + 1 ns;
        sim_finished <= true;
        wait;
    end process;

end architecture test;
