-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;

entity memory_data_register is
	port (
		clk : in std_logic;
		reset : in std_logic;
		en : in std_logic;
		mem_data : in std_logic_vector(15 downto 0);
		mdr_out : out std_logic_vector(15 downto 0)
	);
end entity memory_data_register;

architecture save of memory_data_register is

begin
	process (clk, reset)
	begin
		if reset = '1' then
			mdr_out <= (others => '0');
		elsif rising_edge(clk) then 
			if en = '1' then
				mdr_out <= mem_data;
			end if;
		end if;
	end process;
end architecture save;