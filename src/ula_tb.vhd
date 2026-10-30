-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

entity ULA_tb is
end entity ULA_tb;

architecture test of ULA_tb is
    signal A         : std_logic_vector(15 downto 0) := (others => '0');
    signal B         : std_logic_vector(15 downto 0) := (others => '0');
    signal ULACtl    : std_logic_vector(2 downto 0) := (others => '0');
    signal R         : std_logic_vector(15 downto 0);
    signal Zero      : std_logic;
    signal Overflow  : std_logic;
    signal Cout      : std_logic;
begin
    dut: entity work.ula
        port map (
            A => A,
            B => B,
            ULACtl => ULACtl,
            R => R,
            Zero => Zero,
            Overflow => Overflow,
            Cout => Cout
        );

    stimulus: process
        procedure check_case(
            constant test_name : in string;
            constant operation : in std_logic_vector(2 downto 0);
            constant operand_a : in std_logic_vector(15 downto 0);
            constant operand_b : in std_logic_vector(15 downto 0);
            constant expected_r : in std_logic_vector(15 downto 0);
            constant expected_zero : in std_logic;
            constant expected_overflow : in std_logic;
            constant expected_cout : in std_logic
        ) is
        begin
            ULACtl <= operation;
            A <= operand_a;
            B <= operand_b;
            wait for 2 ns;

            assert R = expected_r
                report test_name & ": R mismatch"
                severity error;
            assert Zero = expected_zero
                report test_name & ": Zero mismatch"
                severity error;
            assert Overflow = expected_overflow
                report test_name & ": Overflow mismatch"
                severity error;
            assert Cout = expected_cout
                report test_name & ": Cout mismatch"
                severity error;
        end procedure;
    begin
        check_case("AND zero", "000", x"00F0", x"0F0F", x"0000", '1', '0', '0');
        check_case("AND nonzero", "000", x"FFFF", x"00FF", x"00FF", '0', '0', '0');
        check_case("OR zero", "001", x"0000", x"0000", x"0000", '1', '0', '0');
        check_case("OR nonzero", "001", x"1234", x"00F0", x"12F4", '0', '0', '0');

        check_case("ADD ordinary", "010", x"0001", x"0001", x"0002", '0', '0', '0');
        check_case("ADD carry and zero", "010", x"FFFF", x"0001", x"0000", '1', '0', '1');
        check_case("ADD signed overflow", "010", x"7FFF", x"0001", x"8000", '0', '1', '0');

        check_case("SUB ordinary", "100", x"0005", x"0003", x"0002", '0', '0', '1');
        check_case("SUB borrow", "100", x"0000", x"0001", x"FFFF", '0', '0', '0');
        check_case("SUB signed overflow", "100", x"8000", x"0001", x"7FFF", '0', '1', '1');
        check_case("SUB zero", "100", x"4321", x"4321", x"0000", '1', '0', '1');

        check_case("SLT negative less than positive", "110", x"FFFF", x"0001", x"0001", '0', '0', '0');
        check_case("SLT positive not less than negative", "110", x"0001", x"FFFF", x"0000", '1', '0', '0');
        check_case("SLT equal", "110", x"8000", x"8000", x"0000", '1', '0', '0');
        check_case("SLT maximum positive vs minimum negative", "110", x"7FFF", x"8000", x"0000", '1', '0', '0');
        check_case("SLT minimum negative vs maximum positive", "110", x"8000", x"7FFF", x"0001", '0', '0', '0');

        check_case("NOR nonzero", "111", x"0000", x"0000", x"FFFF", '0', '0', '0');
        check_case("NOR zero", "111", x"FFFF", x"0000", x"0000", '1', '0', '0');

        assert false report "ULA_tb: all test cases passed" severity note;
        wait;
    end process;
end architecture test;
