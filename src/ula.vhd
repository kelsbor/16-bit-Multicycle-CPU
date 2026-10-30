-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;
use work.ula_pkg.all;

entity ula is
	port(
		A			: in std_logic_vector(15 downto 0);
		B			: in std_logic_vector(15 downto 0);
		ULACtl	: in std_logic_vector(2 downto 0);
		
		R			: out std_logic_vector(15 downto 0);
		Zero		: out std_logic;
		Overflow	: out std_logic;
		Cout		: out std_logic
	);
end ula;

architecture logic of ula is
	-- auxiliares
	
	-- auxiliares p/soma
	signal addop		: std_logic_vector(15 downto 0);
	signal addcout		: std_logic;
	signal addof		: std_logic;
	
	-- auxiliares p/subtraçao
	signal subop		: std_logic_vector(15 downto 0);
	signal c2b			: std_logic_vector(15 downto 0);
	signal subcout		: std_logic;
	signal subof		: std_logic;
	
	-- auxiliares p/SLT
	signal sltop		: std_logic;
	signal sltop_r		: std_logic_vector(15 downto 0);
	
	-- auxiliares das operaçoes logicas
	signal andop		: std_logic_vector(15 downto 0);
	signal orop			: std_logic_vector(15 downto 0);
	signal notop		: std_logic_vector(15 downto 0);
	signal result		: std_logic_vector(15 downto 0);
	
	begin
		-- ULACtl = 000 -> AND
		andop <= A and B;
		
		-- ULACtl = 001 -> OR
		orop <= A or B;
		
		-- ULACtl = 010 -> soma
		fulladd16b: full_adder_16bits port map(
			a			=> A,
			b			=> B,
			cin		=> '0',
		
			r			=> addop,
			cout		=> addcout,
			overflow	=> addof,
			zero		=> open
		);
		
		-- ULACtl = 100 -> subtraçao
		c2b <= not B;
		
		fullsub16b: full_adder_16bits port map(
			a			=> A,
			b			=> c2b,
			cin		=> '1',
		
			r			=> subop,
			cout		=> subcout,
			overflow	=> subof,
			zero		=> open
		);
		
		-- ULACtl = 110 -> SLT
		sltop <= subop(15) xor subof;
		sltop_r <= (0 => sltop, others => '0');
		
		-- ULACtl = 111 -> NOR
		notop <= not(A or B);
	
		-- Multiplexaçao do resultado
		with ULACtl select
            result <= andop   when "000",
                 orop    when "001",
                 addop   when "010",
                 subop   when "100",
                 sltop_r when "110",
                 notop   when "111",
                 (others => '0') when others;

		R <= result;
		Zero <= '1' when result = x"0000" else '0';
						  
		with ULACtl select
            Overflow <= addof when "010",
                        subof when "100",
                        '0'   when others;
								
		with ULACtl select
            Cout <= addcout when "010",
                    subcout when "100",
                    '0'     when others;
	end logic;