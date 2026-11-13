-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;

entity pc is
    port (
	     PcSrc : in std_logic_vector(1 downto 0);
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
begin
	 with PcSrc select
		source <= JumpAddressData when "10",
					 ALUResultData when "01",
					 AluOutData when "00";
	
	 write <= PCWrite OR (PCWriteCond and zero);
	 
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
        elsif (rising_edge(clk) AND write='1') then
            pc_out <= source;
        end if;
    end process;
end architecture pc_behaviour;