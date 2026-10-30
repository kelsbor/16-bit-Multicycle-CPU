-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

entity display_logic is
    port (
        R           : in std_logic_vector(15 downto 0); 
        boardA      : in std_logic_vector(7 downto 0);
        boardB      : in std_logic_vector(7 downto 0);
        
        -- Saídas para os displays
        HEX0        : out std_logic_vector(6 downto 0);
        HEX1        : out std_logic_vector(6 downto 0);
        HEX2        : out std_logic_vector(6 downto 0);
        HEX3        : out std_logic_vector(6 downto 0);
        HEX4        : out std_logic_vector(6 downto 0);
        HEX5        : out std_logic_vector(6 downto 0);
        HEX6        : out std_logic_vector(6 downto 0);
        HEX7        : out std_logic_vector(6 downto 0)
    );
end display_logic;

architecture behavior of display_logic is
    function decode_7seg(hex_digit: std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case hex_digit is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- b
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- d
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111"; 
        end case;
    end function;

begin
    -- ==========================================
    -- MAPEAMENTO DOS DISPLAYS
    -- ==========================================
    
    -- HEX3 a HEX0 recebem os 16 bits de R em hexadecimal.
    HEX0 <= decode_7seg(R(3 downto 0));
    HEX1 <= decode_7seg(R(7 downto 4));
    HEX2 <= decode_7seg(R(11 downto 8));
    HEX3 <= decode_7seg(R(15 downto 12));

    -- HEX5 a HEX4 recebem boardB (8 bits = 2 blocos de 4 bits)
    HEX4 <= decode_7seg(boardB(3 downto 0));
    HEX5 <= decode_7seg(boardB(7 downto 4));

    -- HEX7 a HEX6 recebem boardA (8 bits = 2 blocos de 4 bits)
    HEX6 <= decode_7seg(boardA(3 downto 0));
    HEX7 <= decode_7seg(boardA(7 downto 4));

end behavior;