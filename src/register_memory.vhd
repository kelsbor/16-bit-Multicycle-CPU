-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_bank is
    port (
        clk  : in  std_logic;
        reg_write : in std_logic;
        reset : in std_logic;

        read_reg1 : in std_logic_vector(4 downto 0);
        read_reg2 : in std_logic_vector(4 downto 0);

        read_data1 : out std_logic_vector(31 downto 0);
        read_data2 : out std_logic_vector(31 downto 0);

        write_reg : in std_logic_vector(4 downto 0);
        write_data : in std_logic_vector(31 downto 0)
    );
end entity register_bank;

architecture register_bank_behaviour of register_bank is 
  
  type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);

  signal registers : reg_array := (
    1 => X"00000005",
    2 => X"00000003",
    others => (others => '0')
  );

begin   
  process(clk, reset)
  begin
    if reset = '1' then
      registers <= (1 => X"00000005", 2 => X"00000003", others => (others => '0'));
    elsif rising_edge(clk) then
      if reg_write = '1' and to_integer(unsigned(write_reg)) /= 0 then 
        registers(to_integer(unsigned(write_reg))) <= write_data;
      end if;
    end if;
  end process;


  read_data1 <= (others => '0') when to_integer(unsigned(read_reg1)) = 0 else 
  registers(to_integer(unsigned(read_reg1)));

  read_data2 <= (others => '0') when to_integer(unsigned(read_reg2)) = 0 else
  registers(to_integer(unsigned(read_reg2)));

end architecture register_bank_behaviour;