-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;
use work.ula_pkg.all;

entity ula is
	port(
			R			: out std_logic_vector(15 downto 0);
			Zero		: out std_logic;
			Overflow	: out std_logic;	-- nao mais utilizado
			Cout		: out std_logic;	-- nao mais utilizado
			
			AluOut	: out std_logic_vector(15 downto 0);
			
			-- Sinais de controle
			clk		: in std_logic;
			rst		: in std_logic;
			AluSrcA	: in std_logic;
			AluSrcB	: in std_logic_vector(1 downto 0);
			
			-- Todas as entradas
			A_PC		: in std_logic_vector(15 downto 0);
			A_Ri_data: in std_logic_vector(15 downto 0);
			
			B_Rj_data: in std_logic_vector(15 downto 0);
			B_4		: in std_logic_vector(15 downto 0);
			B_Ime		: in std_logic_vector(15 downto 0);
			B_End		: in std_logic_vector(15 downto 0);
			
			-- 000 | AndOp
			-- 001 | OrOp
			-- 010 | AddOp
			-- 100 | SubOp
			-- 110 | SltOp
			-- 111 | NotOp
			Funct		: in std_logic_vector(2 downto 0);
			
			-- 00 | AddOp
			-- 01 | SubOp
			-- 10 | Funct do tipo R repassado para a ULA
			AluOp		: in std_logic_vector(1 downto 0)
	);
end ula;

architecture logic of ula is
	-- controle interno de operaçao
	signal ULACtl		: std_logic_vector(2 downto 0);

	-- auxiliares
	signal A				: std_logic_vector(15 downto 0);
	signal B				: std_logic_vector(15 downto 0);
	
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
		-- multiplexaçao das entradas
		with AluSrcA select
			A <=	A_PC when '0',
					A_Ri_data when others;
					
		with AluSrcB select
			B <=	B_Rj_data when "00",
					B_4 when "01",
					B_Ime when "10",
					B_End when "11",
					(others => '0') when others;
					
		-- Operaçao com base em Function ou ALUOp
		with AluOp select
			ULACtl	<= "010" when "00",		-- addop
							"100" when "01",		-- subop
							Funct when "10",
							"000" when others;
	
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
			Cout <=	addcout when "010",
						subcout when "100",
						'0' when others;

		-- Reg AluOut
		process (clk, rst)
		begin
			if rst = '1' then
				AluOut <= (others => '0');
			elsif rising_edge(clk) then
				AluOut <= result;
			end if;
		end process;
		
	end logic;