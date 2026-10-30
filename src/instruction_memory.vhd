-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        pc_out  			: in  std_logic_vector(31 downto 0);
        instruction_out : out std_logic_vector(31 downto 0)
    );
end entity instruction_memory;

architecture instruction_memory_behaviour of instruction_memory is 
  
  type rom_type is array (0 to 15) of std_logic_vector(31 downto 0);

	constant instructions : rom_type := (
		--    [opcode]     [rs]      [rt]      [rd]    [shamt]  [funct]                                                                                              
		0 => "000000" & "00001" & "00010" & "00011" & "00000" & "000010", -- PC=00: ADD $3, $1, $2 ($3 = 5 + 3 = 8 -> 0x0008)
		1 => "000000" & "00001" & "00010" & "00100" & "00000" & "000100", -- PC=04: SUB $4, $1, $2 ($4 = 5 - 3 = 2 -> 0x0002)
		2 => "000000" & "00001" & "00010" & "00101" & "00000" & "000000", -- PC=08: AND $5, $1, $2 ($5 = 5 & 3 = 1 -> 0x0001)
		3 => "000000" & "00001" & "00010" & "00110" & "00000" & "000001", -- PC=0C: OR  $6, $1, $2 ($6 = 5 | 3 = 7 -> 0x0007)
		4 => "000000" & "00011" & "00100" & "00111" & "00000" & "000010", -- PC=10: ADD $7, $3, $4 ($7 = 8 + 2 = 10 -> 0x000A)
		5 => "000000" & "00100" & "00011" & "01000" & "00000" & "000110", -- PC=14: SLT $8, $4, $3 ($8 = (2 < 8) = 1 -> 0x0001)
		6 => "000000" & "00011" & "00100" & "01001" & "00000" & "000111", -- PC=18: NOR $9, $3, $4 ($9 = ~(8 | 2) = 0xFFF5)
		others => (others => '0')
	);

begin   
  instruction_out <= instructions(to_integer(unsigned(pc_out(5 downto 2))));


end architecture instruction_memory_behaviour;
