-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;
use work.ula_pkg.all;

entity full_adder is
	port (
		a, b, cin:	in std_logic;
		r, cout:		out std_logic
	);
end full_adder;

architecture logic of full_adder is
	begin
		r		<= a xor b xor cin;									-- bit resultante da soma
		cout	<= (a and b) or (a and cin) or (b and cin);	-- bit do cout
	end logic;