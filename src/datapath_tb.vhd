-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath_tb is
end entity datapath_tb;

architecture test of datapath_tb is

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';
    signal reg_write       : std_logic := '0';

    signal pc_current      : std_logic_vector(31 downto 0);
    signal instruction_out : std_logic_vector(31 downto 0);
    signal ula_result      : std_logic_vector(15 downto 0);
    signal zero            : std_logic;
    signal overflow        : std_logic;
    signal cout            : std_logic;

    constant clk_period    : time := 20 ns;
    signal sim_finished    : boolean := false;

begin

    dut: entity work.datapath
        port map (
            clk             => clk,
            reg_write       => reg_write,
            reset           => reset,
            pc_current      => pc_current,
            instruction_out => instruction_out,
            ula_result      => ula_result,
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

    stimulus: process
    begin
        -- Reset inicial
        reset     <= '1';
        reg_write <= '0';
        wait for clk_period * 2;
        assert pc_current = x"00000000" severity error;

        wait until falling_edge(clk);
        reset     <= '0';
        reg_write <= '1';

        -- Ciclo 0: ADD $3, $1, $2 (5 + 3 = 8)
        wait for 1 ns;
        assert pc_current = x"00000000" severity error;
        assert ula_result = x"0008" severity error;
        assert zero = '0' severity error;

        -- Ciclo 1: SUB $4, $1, $2 (5 - 3 = 2)
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_current = x"00000004" severity error;
        assert ula_result = x"0002" severity error;
        assert zero = '0' severity error;

        -- Ciclo 2: AND $5, $1, $2 (5 and 3 = 1)
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_current = x"00000008" severity error;
        assert ula_result = x"0001" severity error;

        -- Ciclo 3: OR $6, $1, $2 (5 or 3 = 7)
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_current = x"0000000C" severity error;
        assert ula_result = x"0007" severity error;

        -- Ciclo 4: ADD $7, $3, $4 (8 + 2 = 10 = 0x000A)
        wait until rising_edge(clk);
        wait for 1 ns;
        assert pc_current = x"00000010" severity error;
        assert ula_result = x"000A" severity error;
		  
		  -- Ciclo 5: SLT $8, $4, $3 (2 < 8 = 1 = 0x0001)
		  wait until rising_edge(clk);
		  wait for 1 ns;
		  assert pc_current = x"00000014" severity error;
		  assert ula_result = x"0001" severity error;
		  
		  -- Ciclo 6: NOR $9, $3, $4 (~(8 or 2) = 0xFFF5)
		  wait until rising_edge(clk);
		  wait for 1 ns;
		  assert pc_current = x"00000018" severity error;
		  assert ula_result = x"FFF5" severity error;
		  
		  -- Ciclo 7: Fim da execucao (NOP -> 0 and 0 = 0, Zero = '1')
		  wait until rising_edge(clk);
		  wait for 1 ns;
		  assert pc_current = x"0000001C" severity error;
		  assert ula_result = x"0000" severity error;
		  assert zero = '1' severity error;

        wait for clk_period * 2;
        sim_finished <= true;
        wait;
    end process;

end architecture test;
