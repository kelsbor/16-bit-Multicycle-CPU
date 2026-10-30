-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;

entity pc is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        pc_in  : in  std_logic_vector(31 downto 0);
        pc_out : out std_logic_vector(31 downto 0)
    );
end entity pc;

architecture pc_behaviour of pc is 
begin   
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
        elsif rising_edge(clk) then
            pc_out <= pc_in;
        end if;
    end process;
end architecture pc_behaviour;