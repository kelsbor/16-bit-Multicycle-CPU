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
  component control_unit is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        opcode      : in std_logic_vector(3 downto 0);

        PCWriteCond : out std_logic;
        PCWrite     : out std_logic;
        IorD        : out std_logic;
        MemRead     : out std_logic;
        MemWrite    : out std_logic;
        IRWrite     : out std_logic;
        RegWrite    : out std_logic;
        RegDst      : out std_logic;
        MemtoReg    : out std_logic;
        AluOp       : out std_logic_vector(1 downto 0); 
        AluSrcA     : out std_logic;
        AluSrcB     : out std_logic_vector(1 downto 0); 
        PCSrc       : out std_logic_vector(1 downto 0);
        BNE         : out std_logic
    );
  end component;
	
	component pc is
		port (
		  PcSrc : in std_logic;
		  PcWriteCond : in std_logic;
		  PcWrite : in std_logic;
		  Zero : in std_logic;
        clk    : in  std_logic;
        reset  : in  std_logic;
        ALUOutData : in  std_logic_vector(15 downto 0);
		  ALUResultData : in std_logic_vector(15 downto 0);
		  JumpAddressData : in std_logic_vector(15 downto 0);
        pc_out : out std_logic_vector(15 downto 0)
		);
	end component;
end package ula_pkg;
