-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_unit is
    port (
		  mem_read : in std_logic;
		  mem_write : in std_logic;
		  clk : in std_logic;
		  IorD : in std_logic;
		  pc_out  : in std_logic_vector(15 downto 0);
		  AluOutData : in std_logic_vector(15 downto 0);
		  write_data : in std_logic_vector(15 downto 0);
        data : out std_logic_vector(15 downto 0)
    );
end entity memory_unit;

architecture memory_unit_behaviour of memory_unit is 
	
	 -- Memória de 256 posições de 16 bits (endereçada pelos 8 bits inferiores)
    type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
    signal ram : ram_type;
	 
	 -- Vincula o arquivo .mif do Quartus à memória
    attribute ram_init_file : string;
    attribute ram_init_file of ram : signal is "ram_init.mif";
	 
	 -- Endereço selecionado pelo IorD
    signal selected_addr : std_logic_vector(15 downto 0);

begin
	selected_addr <= pc_out when IorD ='0' else AluOutData;
	process(clk)
		variable index : integer range 0 to 255;
	begin
		if rising_edge(clk) then
			index := to_integer(unsigned(selected_addr(7 downto 0)));
			if mem_write ='1' then
				ram(index) <= write_data;
			end if;
		end if;
	end process;
	
	data <= ram(to_integer(unsigned(selected_addr(7 downto 0)))) when mem_read = '1' else (others => '0');
end architecture memory_unit_behaviour;
