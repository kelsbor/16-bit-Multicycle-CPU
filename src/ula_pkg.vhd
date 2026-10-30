-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

package ula_pkg is
	component full_adder is		-- inicio component
		port (
			-- declaracao das portas in e out do componente
			a, b, cin:	in std_logic;
			r, cout:		out std_logic
		);
	end component;
	
	component full_adder_16bits is
		port(
			a: 			in std_logic_vector (15 downto 0);
			b: 			in std_logic_vector (15 downto 0);
			cin: 			in std_logic;
			
			r: 			out std_logic_vector (15 downto 0);
			cout: 		out std_logic;
			overflow: 	out std_logic;
			zero: 		out std_logic
		);
	end component;

	component ula is
		port(
			A			: in std_logic_vector(15 downto 0);
			B			: in std_logic_vector(15 downto 0);
			ULACtl	: in std_logic_vector(2 downto 0);
			
			R			: out std_logic_vector(15 downto 0);
			Zero		: out std_logic;
			Overflow	: out std_logic;
			Cout		: out std_logic
		);
	end component;
	
	component display_logic is 
			port (
			  -- Novas entradas substituindo 'number'
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
	end component;
end package ula_pkg;