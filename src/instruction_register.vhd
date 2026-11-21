-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;

entity instruction_register is
	port (
		clk : in std_logic;
		reset : in std_logic;
		IRwrite : in std_logic;
		mem_data : in std_logic_vector(15 downto 0);
		instruction : out std_logic_vector(15 downto 0)
	);
end entity instruction_register;

architecture behaviour of instruction_register is

begin
	process(clk, reset)
	begin
		if reset = '1' then
			instruction <= (others => '0');
		elsif rising_edge(clk) then
			if IRwrite = '1' then
				instruction <= mem_data;
			end if;
		end if;
	end process;
end architecture behaviour;
			