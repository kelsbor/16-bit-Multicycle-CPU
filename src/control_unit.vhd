library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
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
        RegDst      : out std_logic;
        MemtoReg    : out std_logic;
        AluOp       : out std_logic_vector(1 downto 0); 
        AluSrcA     : out std_logic;
        AluSrcB     : out std_logic_vector(1 downto 0); 
        PCSrc       : out std_logic_vector(1 downto 0);
        BNE         : out std_logic;
		  
		  state_out : out std_logic_vector(4 downto 0)
  );
end entity control_unit;

architecture fsm of control_unit is
  type state_t is (
    S_IF,
    S_ID,
    S_EX_R,
    S_EX_ADDI,
    S_WB_R,
    S_EX_MEM,
    S_MEM_RD,
    S_WB_LD,
    S_MEM_WR,
    S_EX_BEQ,
    S_EX_BNE,
    S_EX_JMP
  );

  signal current_state, next_state : state_t;
  
  constant OP_ADD : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB : std_logic_vector(3 downto 0) := "0001";
  constant OP_AND : std_logic_vector(3 downto 0) := "0010";
  constant OP_OR : std_logic_vector(3 downto 0) := "0011";
  constant OP_SLT : std_logic_vector(3 downto 0) := "0100";
  constant OP_ADDI : std_logic_vector(3 downto 0) := "0101";
  constant OP_LD : std_logic_vector(3 downto 0) := "0110";
  constant OP_ST : std_logic_vector(3 downto 0) := "0111";
  constant OP_BEQ : std_logic_vector(3 downto 0) := "1000";
  constant OP_BNE : std_logic_vector(3 downto 0) := "1001";
  constant OP_JMP : std_logic_vector(3 downto 0) := "1010";

begin
 
  process(clk, reset)
  begin
    if reset = '1' then 
      current_state <= S_IF;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  process(current_state, opcode)
  begin
    PCWriteCond <= '0';
    PCWrite <= '0';
    IorD <= '0';
    MemRead <= '0';
    MemWrite <= '0';
    IRWrite <= '0';
    RegWrite <= '0';
	 ReadReg2Sel <= '0';
    RegDst <= '0';
    MemtoReg <= '0';
    AluOp <= "00";
    AluSrcA <= '0';
    AluSrcB <= "00";
    PCSrc <= "00";
    BNE <= '0';
    next_state <= S_IF;

    case current_state is

      when S_IF =>
		  state_out  <= "00001"; -- LEDG(0): Fetch
        PCWrite <= '1';
        MemRead <= '1';
        IRWrite <= '1';
        AluOp <=  "00";
        AluSrcB <= "01";
        PCSrc <= "01";
        next_state <= S_ID;

		when S_ID =>
			state_out <= "00010";
			AluSrcA <= '0';
			AluSrcB <= "11";
			AluOp   <= "00";

    -- Preparação do endereço para BEQ e BNE
			if opcode = OP_BEQ or opcode = OP_BNE then
				AluSrcB <= "10";  -- Seleciona imediato estendido
			end if;
	 
        case opcode is
          when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_SLT =>
				ReadReg2Sel <= '1';
				next_state <= S_EX_R;

          when OP_ADDI => 
            next_state <= S_EX_ADDI;

          when OP_LD | OP_ST => 
            next_state <= S_EX_MEM;

          when OP_BEQ => 
            next_state <= S_EX_BEQ;

          when OP_BNE => 
            next_state <= S_EX_BNE;

          when OP_JMP => 
            next_state <= S_EX_JMP;
        
          when others =>
            next_state <= S_IF;
        end case;

      when S_EX_R =>
		  state_out  <= "00100"; -- LEDG(2): Execução
        AluSrcA <= '1';
        AluOp <= "10";
        next_state <= S_WB_R;
		  
      when S_EX_ADDI =>
		  state_out  <= "00100"; -- LEDG(2): Execução
        AluOp <= "00";
        AluSrcA <= '1';
        AluSrcB <= "10";
        PCSrc <= "01";
        next_state <= S_WB_R;

      when S_WB_R =>
			
		  state_out <= "10000";   -- LEDG(4): Write-Back
        RegWrite <= '1';
        MemtoReg <= '0';
        if opcode = OP_ADDI then
          RegDst <= '0';
        else 
          RegDst <= '1';
        end if;

        next_state <= S_IF;

      when S_EX_MEM => 
		  state_out  <= "00100"; -- LEDG(2): Execução
        AluOp <=  "00";
        AluSrcA <= '1';
        AluSrcB <= "10";
        PCSrc <= "01";
        if opcode = OP_LD then
          next_state <= S_MEM_RD;

        else
          next_state <= S_MEM_WR;
        end if;

      when S_MEM_RD =>
			 state_out  <= "01000"; -- LEDG(3): Memória
          IorD <= '1';
          MemRead <= '1';
          next_state <= S_WB_LD;

      when S_WB_LD =>
		    state_out  <= "10000"; -- LEDG(4): Write-Back
          RegWrite <= '1';
          MemtoReg <= '1';
          next_state <= S_IF;

      when S_MEM_WR =>
			 state_out  <= "01000"; -- LEDG(3): Memória
          IorD <= '1';
          MemWrite <= '1';
          next_state <= S_IF;

      when S_EX_BEQ =>
		    state_out  <= "00100"; -- LEDG(2): Execução
          PCWriteCond <= '1';
          AluOp <= "01";
          AluSrcA <= '1';
          PCSrc <= "00";
          next_state <= S_IF;

      when S_EX_BNE =>
		    state_out  <= "00100"; -- LEDG(2): Execução
          PCWriteCond <= '1';
          AluOp <= "01";
          AluSrcA <= '1';
          PCSrc <= "00";
          BNE <= '1';
          next_state <= S_IF;

      when S_EX_JMP =>
		    state_out  <= "00100"; -- LEDG(2): Execução
          PCWrite <= '1';
          AluSrcA <= '1';
          AluSrcB <= "11";
          PCSrc <= "10";
          next_state <= S_IF;

      when others =>
			 state_out  <= "00000";
          next_state <= S_IF;        

    end case;

  end process;
  
  
end architecture fsm;
