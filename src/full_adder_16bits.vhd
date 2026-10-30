-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;
use work.ula_pkg.all;

entity full_adder_16bits is
	port(
			a: 			in std_logic_vector (15 downto 0);
			b: 			in std_logic_vector (15 downto 0);
			cin: 			in std_logic;
			
			r: 			out std_logic_vector (15 downto 0);
			cout: 		out std_logic;
			overflow: 	out std_logic;
			zero: 		out std_logic
	);
end full_adder_16bits;

architecture logic of full_adder_16bits is
	-- sinais necessarios para ripple carry
	signal couti:	std_logic_vector(15 downto 0);
	signal ri:		std_logic_vector(15 downto 0);
	
	begin
		fa0: full_adder port map(
			a => a(0),
			b => b(0),
			cin => cin,		-- deve ser 1 quando for subtraçao
			
			r => ri(0),
			cout => couti(0)
		);
		
		fa1: full_adder port map(
			a => a(1),
			b => b(1),
			cin => couti(0),
			
			r => ri(1),
			cout => couti(1)
		);
		
		fa2: full_adder port map(
			a => a(2),
			b => b(2),
			cin => couti(1),
			
			r => ri(2),
			cout => couti(2)
		);
		
		fa3: full_adder port map(
			a => a(3),
			b => b(3),
			cin => couti(2),
			
			r => ri(3),
			cout => couti(3)
		);
		
		fa4: full_adder port map(
			a => a(4),
			b => b(4),
			cin => couti(3),
			
			r => ri(4),
			cout => couti(4)
		);
		
		fa5: full_adder port map(
			a => a(5),
			b => b(5),
			cin => couti(4),
			
			r => ri(5),
			cout => couti(5)
		);
		
		fa6: full_adder port map(
			a => a(6),
			b => b(6),
			cin => couti(5),
			
			r => ri(6),
			cout => couti(6)
		);
		
		fa7: full_adder port map(
			a => a(7),
			b => b(7),
			cin => couti(6),
			
			r => ri(7),
			cout => couti(7)
		);
		
		fa8: full_adder port map(
			a => a(8),
			b => b(8),
			cin => couti(7),
			
			r => ri(8),
			cout => couti(8)
		);
		
		fa9: full_adder port map(
			a => a(9),
			b => b(9),
			cin => couti(8),
			
			r => ri(9),
			cout => couti(9)
		);
		
		fa10: full_adder port map(
			a => a(10),
			b => b(10),
			cin => couti(9),
			
			r => ri(10),
			cout => couti(10)
		);
		
		fa11: full_adder port map(
			a => a(11),
			b => b(11),
			cin => couti(10),
			
			r => ri(11),
			cout => couti(11)
		);
		
		fa12: full_adder port map(
			a => a(12),
			b => b(12),
			cin => couti(11),
			
			r => ri(12),
			cout => couti(12)
		);
		
		fa13: full_adder port map(
			a => a(13),
			b => b(13),
			cin => couti(12),
			
			r => ri(13),
			cout => couti(13)
		);
		
		fa14: full_adder port map(
			a => a(14),
			b => b(14),
			cin => couti(13),
			
			r => ri(14),
			cout => couti(14)
		);
		
		fa15: full_adder port map(
			a => a(15),
			b => b(15),
			cin => couti(14),
			
			r => ri(15),
			cout => couti(15)
		);
		
		cout <= couti(15);
		overflow <= couti(14) xor couti(15);
		zero <= 	(not ri(0)) and (not ri(1)) and (not ri(2)) and (not ri(3)) and (not ri(4)) and
					(not ri(5)) and (not ri(6)) and (not ri(7)) and (not ri(8)) and (not ri(9)) and
					(not ri(10)) and (not ri(11)) and (not ri(12)) and (not ri(13)) and (not ri(14)) and (not ri(15));
					
		r <= ri;
	end logic;