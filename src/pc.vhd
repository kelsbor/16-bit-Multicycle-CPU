-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;

entity pc is
    port (
	     PcSource : in std_logic;
		  PcWriteCond : in std_logic;
		  PcWrite : in std_logic;
		  zero : in std_logic;
        clk    : in  std_logic;
        reset  : in  std_logic;
        ALUOutData : in  std_logic_vector(15 downto 0);
		  ALUResultData : in std_logic_vector(15 downto 0);
		  JumpAddressData : in std_logic_vector(15 downto 0);
        pc_out : out std_logic_vector(15 downto 0)
    );
end entity pc;

architecture pc_behaviour of pc is 
	 signal write : std_logic;
	 signal source : std_logic_vector(15 downto 0);
	 
	 with PcSource select
		source <= 
begin
	 write <= PCWrite OR (PCWriteCond & zero);
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
        elsif (rising_edge(clk) & write) then
            pc_out <= pc_in;
        end if;
    end process;
end architecture pc_behaviour;