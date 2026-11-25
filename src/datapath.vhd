-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.datapath_pkg.all;

entity datapath is
    port (
        clk  : in  std_logic;
		  step_en: in std_logic;
        reset : in std_logic;
        
        pc_current : out std_logic_vector(15 downto 0);
        instruction_out : out std_logic_vector(15 downto 0);
        ula_result : out std_logic_vector(15 downto 0);
		  
		  mdr_out   : out std_logic_vector(15 downto 0);
		  state_out : out std_logic_vector(4 downto 0);
		  
        zero : out std_logic;
        overflow : out std_logic;
        cout : out std_logic
    );
end entity datapath;

architecture datapath_behaviour of datapath is 
    
	 -- Sinais da Unidade de Controle
    signal s_PCWriteCond : std_logic;
    signal s_PCWrite     : std_logic;
    signal s_IorD        : std_logic;
    signal s_MemRead     : std_logic;
    signal s_MemWrite    : std_logic;
	 signal s_write_reg  : std_logic_vector(2 downto 0);
    signal s_IRWrite     : std_logic;
    signal s_RegWrite    : std_logic;
    signal s_RegDst      : std_logic;
    signal s_MemtoReg    : std_logic;
    signal s_AluOp       : std_logic_vector(1 downto 0);
    signal s_AluSrcA     : std_logic;
    signal s_AluSrcB     : std_logic_vector(1 downto 0);
    signal s_PCSrc       : std_logic_vector(1 downto 0);
    signal s_BNE         : std_logic;
	 signal s_mem_write_en: std_logic;
	 signal s_ir_write_en : std_logic;
	 signal s_reg_write_en: std_logic;
	 signal s_pc_write_en : std_logic;
	 signal s_pc_write_cond_en: std_logic;
	 signal s_AluOutWrite : std_logic;
	 signal s_alu_out_en  : std_logic;
	 signal s_mdr_write_en: std_logic;
	 
	 -- Barramentos de 16 bits
    signal s_pc_out      : std_logic_vector(15 downto 0);
    signal s_mem_data    : std_logic_vector(15 downto 0);
    signal s_ir          : std_logic_vector(15 downto 0);
    signal s_mdr         : std_logic_vector(15 downto 0);
    
    signal s_read_data1  : std_logic_vector(15 downto 0);
    signal s_read_data2  : std_logic_vector(15 downto 0);
    signal reg_A         : std_logic_vector(15 downto 0);
    signal reg_B         : std_logic_vector(15 downto 0);
    signal s_write_data  : std_logic_vector(15 downto 0);
    
	 
    signal s_ula_res     : std_logic_vector(15 downto 0);
    signal s_alu_out     : std_logic_vector(15 downto 0);
    signal s_zero        : std_logic;
    signal s_overflow    : std_logic;
    signal s_cout        : std_logic;
    signal s_zero_reg    : std_logic;
    signal s_overflow_reg: std_logic;
    signal s_cout_reg    : std_logic;
	 
	 -- Sinais auxiliares de fatiamento e extensão
    signal s_read_reg2   : std_logic_vector(2 downto 0);
    signal s_imm_ext     : std_logic_vector(15 downto 0);
    signal s_jump_addr   : std_logic_vector(15 downto 0);

begin   
	s_mem_write_en <= s_MemWrite and step_en;
	s_ir_write_en <= s_IRWrite and step_en;
	s_reg_write_en <= s_RegWrite and step_en;
	s_pc_write_en <= s_PCWrite and step_en;
	s_pc_write_cond_en <= s_PCWriteCond and step_en;
	s_alu_out_en       <= s_AluOutWrite and step_en;
	s_mdr_write_en     <= s_MemRead and s_IorD and step_en;
	
	-- Mapeamento dos componentes com os sinais declarados
	-- 1. Unidade de Controle (FSM)
    ctrl_inst : control_unit
      port map (
        clk         => clk,
		  step_en	  => step_en,
        reset       => reset,
        opcode      => s_ir(15 downto 12),
        PCWriteCond => s_PCWriteCond,
        PCWrite     => s_PCWrite,
        IorD        => s_IorD,
        MemRead     => s_MemRead,
        MemWrite    => s_MemWrite,
        IRWrite     => s_IRWrite,
        RegWrite    => s_RegWrite,
        RegDst      => s_RegDst,
        MemtoReg    => s_MemtoReg,
        AluOp       => s_AluOp,
        AluSrcA     => s_AluSrcA,
        AluSrcB     => s_AluSrcB,
        PCSrc       => s_PCSrc,
		  BNE			  => s_BNE,
		  AluOutWrite => s_AluOutWrite,
		  state_out	  => state_out
      );
		
	 -- 2. Registrador do Program Counter
    inst_pc : pc
      port map (
        PcSrc           => s_PCSrc,
        PcWriteCond     => s_pc_write_cond_en,
        PcWrite         => s_pc_write_en,
        BNE             => s_BNE,
        zero            => s_zero,
        clk             => clk,
        reset           => reset,
        ALUOutData      => s_alu_out,
        ALUResultData   => s_ula_res,
        JumpAddressData => s_jump_addr,
        pc_out          => s_pc_out
      );
	
	-- 3. Unidade de memoria
	inst_mem : memory_unit
		port map (
        clk        => clk,
        IorD       => s_IorD,
        mem_read   => s_MemRead,
        mem_write  => s_mem_write_en,
        pc_out     => s_pc_out,
        AluOutData => s_alu_out,
        write_data => reg_B,
        data       => s_mem_data
		);
	
	-- 4. Registrador de instruçoes (RI) e MDR
	inst_ir : instruction_register
		port map (
        clk         => clk,
        reset       => reset,
        IRwrite     => s_ir_write_en,
        mem_data    => s_mem_data,
        instruction => s_ir
      );

	inst_mdr : memory_data_register
      port map (
        clk      => clk,
        reset    => reset,
		  en		  => s_mdr_write_en,
        mem_data => s_mem_data,
        mdr_out  => s_mdr
      );
	
	-- 5. Banco de Registradores
	-- Rj vai para read_reg1 (A). read_reg2 recebe Rk (Tipo R) ou Ri (ST/BEQ/BNE).
   
	s_read_reg2 <= s_ir(5 downto 3) when s_RegDst = '1' else s_ir(11 downto 9);
   s_write_reg <= s_ir(11 downto 9);
	s_write_data <= s_mdr when s_MemtoReg = '1' else s_alu_out;
	
	inst_regbank : register_bank
		port map (
        clk        => clk,
        reset      => reset,
        reg_write  => s_reg_write_en,
        read_reg1  => s_ir(8 downto 6),  -- Rj
        read_reg2  => s_read_reg2,       -- Rk ou Ri
        write_reg => s_write_reg, -- Ri é sempre o destino de escrita
        write_data => s_write_data,
        read_data1 => s_read_data1,
        read_data2 => s_read_data2
      );
	
	-- Registradores temporários A e B na saída do banco de registradores
    process(clk, reset)
    begin
        if reset = '1' then
            reg_A <= (others => '0');
            reg_B <= (others => '0');
        elsif rising_edge(clk) then
            if step_en = '1' then
					reg_A <= s_read_data1;
					reg_B <= s_read_data2;
				end if;
        end if;
    end process;
	 
	 -- 6. Extensão de Sinal (6 -> 16 bits) e Endereço de Jump (16 bits)
    s_imm_ext   <= std_logic_vector'(15 downto 6 => s_ir(5)) & s_ir(5 downto 0);
    s_jump_addr <= s_pc_out(15 downto 12) & s_ir(11 downto 0);
	 
    -- 7. Unidade Lógica e Aritmética (ULA + Reg AluOut)
    ula_main_inst : ula
      port map (
        R         => s_ula_res,
        Zero      => s_zero,
        Overflow  => s_overflow,
        Cout      => s_cout,
        AluOut    => s_alu_out,
        clk       => clk,
        rst       => reset,
		  alu_out_en=> s_alu_out_en,
        AluSrcA   => s_AluSrcA,
        AluSrcB   => s_AluSrcB,
        A_PC      => s_pc_out,
        A_operand => reg_A,
        B_operand => reg_B,
        PC_increment => x"0001",
        Immediate_operand => s_imm_ext,
        Jump_operand => s_jump_addr,
        Funct     => s_ir(2 downto 0),
        AluOp     => s_AluOp
      );

    -- Flags registradas em sincronia com AluOut para exibição nos LEDR
    process(clk, reset)
    begin
        if reset = '1' then
            s_zero_reg     <= '0';
            s_overflow_reg <= '0';
            s_cout_reg     <= '0';
        elsif rising_edge(clk) then
            if s_alu_out_en = '1' then
                s_zero_reg     <= s_zero;
                s_overflow_reg <= s_overflow;
                s_cout_reg     <= s_cout;
            end if;
        end if;
    end process;

   -- Saídas de monitoramento
    pc_current      <= s_pc_out;
    instruction_out <= s_ir;
    ula_result      <= s_alu_out;
    zero            <= s_zero_reg;
    overflow        <= s_overflow_reg;
    cout            <= s_cout_reg;
	 
	 mdr_out <= s_mdr;
end architecture datapath_behaviour;
