-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

package datapath_pkg is
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
			A_operand: in std_logic_vector(15 downto 0);
			B_operand: in std_logic_vector(15 downto 0);
			PC_increment: in std_logic_vector(15 downto 0);
			Immediate_operand: in std_logic_vector(15 downto 0);
			Jump_operand: in std_logic_vector(15 downto 0);
			
			-- 000 | AndOp
			-- 001 | OrOp
			-- 010 | AddOp
			-- 100 | SubOp
			-- 110 | SltOp
			-- 111 | NorOp
			Funct		: in std_logic_vector(2 downto 0);
			
			-- 00 | AddOp
			-- 01 | SubOp
			-- 10 | Funct do tipo R repassado para a ULA
			AluOp		: in std_logic_vector(1 downto 0)
		);
	end component;
	
	component display_logic is 
			port (
			  val_hex0_3 : in std_logic_vector(15 downto 0);
			  val_hex4_7 : in std_logic_vector(15 downto 0);
			  
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
		  ReadReg2Sel : out std_logic;
        MemtoReg    : out std_logic;
        AluOp       : out std_logic_vector(1 downto 0); 
        AluSrcA     : out std_logic;
        AluSrcB     : out std_logic_vector(1 downto 0); 
        PCSrc       : out std_logic_vector(1 downto 0);
        BNE         : out std_logic;
		  state_out   : out std_logic_vector(4 downto 0)
    );
  end component;
	
	component pc is
		port (
	     PcSrc : in std_logic_vector(1 downto 0);
		  PcWriteCond : in std_logic;
		  PcWrite : in std_logic;
		  zero : in std_logic;
		  BNE : in std_logic;
        clk    : in  std_logic;
        reset  : in  std_logic;
        ALUOutData : in  std_logic_vector(15 downto 0);
		  ALUResultData : in std_logic_vector(15 downto 0);
		  JumpAddressData : in std_logic_vector(15 downto 0);
        pc_out : out std_logic_vector(15 downto 0)
    );
	end component;
	
	component memory_data_register is
		port (
			clk : in std_logic;
			reset : in std_logic;
			mem_data : in std_logic_vector(15 downto 0);
			mdr_out : out std_logic_vector(15 downto 0)
	);
	end component;
	
	component instruction_register is
		port (
		clk : in std_logic;
		reset : in std_logic;
		IRwrite : in std_logic;
		mem_data : in std_logic_vector(15 downto 0);
		instruction : out std_logic_vector(15 downto 0)
	);
	end component;

	component memory_unit is
		port (
		  mem_read : in std_logic;
		  mem_write : in std_logic;
		  clk : in std_logic;
		  IorD : in std_logic;
		  pc_out  : in std_logic_vector(15 downto 0);
		  AluOutData : in std_logic_vector(15 downto 0);
		  write_data : in std_logic_vector(15 downto 0);
        data : out std_logic_vector(15 downto 0)
    );
	end component;
	
	component register_bank is
		port (
			clk        : in std_logic;
			reg_write  : in std_logic;
			reset      : in std_logic;
			read_reg1  : in std_logic_vector(2 downto 0);
			read_reg2  : in std_logic_vector(2 downto 0);
			read_data1 : out std_logic_vector(15 downto 0);
			read_data2 : out std_logic_vector(15 downto 0);
			write_reg  : in std_logic_vector(2 downto 0);
			
			write_data : in std_logic_vector(15 downto 0)
		);
	end component;
	
end package datapath_pkg;
