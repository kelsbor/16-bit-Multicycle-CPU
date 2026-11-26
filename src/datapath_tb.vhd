-- Integrantes: Carlos Nascimento, Guilherme Dias, Daniel Wu, Kelvin Borges
library ieee;
use ieee.std_logic_1164.all;

entity datapath_tb is
end entity datapath_tb;

architecture test of datapath_tb is

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '1';
	 signal step_en			: std_logic := '0';

    signal pc_current      : std_logic_vector(15 downto 0);
    signal instruction_out : std_logic_vector(15 downto 0);
    signal ula_result      : std_logic_vector(15 downto 0);
    signal mdr_out         : std_logic_vector(15 downto 0);
    signal state_out       : std_logic_vector(4 downto 0);
    signal zero            : std_logic;
    signal overflow        : std_logic;
    signal cout            : std_logic;

    constant clk_period       : time := 20 ns;
    constant program_cycles   : natural := 81;
    signal sim_finished       : boolean := false;

begin

    dut: entity work.datapath
        port map (
            clk             => clk,
				step_en			 => step_en,
            reset           => reset,
            pc_current      => pc_current,
            instruction_out => instruction_out,
            ula_result      => ula_result,
            mdr_out         => mdr_out,
            state_out       => state_out,
            zero            => zero,
            overflow        => overflow,
            cout            => cout
        );

    -- Clock de 50 MHz
    clk_process: process
    begin
        while not sim_finished loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

	stimulus:process
		procedure step_cpu(steps : in positive := 1) is
		begin
			for i in 1 to steps loop
				-- 1 ciclo com step_en = 1 - avança na fsm
				wait until falling_edge(clk);
				step_en <= '1';
				wait until rising_edge(clk);
				
				-- 1 ciclo com step_en = 0 - ram atualiza s_mem_data
				wait until falling_edge(clk);
				step_en <= '0';
				wait until rising_edge(clk);
				wait for 1 ns;
			end loop;
		end procedure;
	begin
		-- reset inicial
		reset <= '1';
		step_en <= '0';
		wait until rising_edge(clk);
		wait until falling_edge(clk);
		reset <= '0';
		
		-- clique 0 - conferencia
		assert pc_current = x"0000" and state_out = "00001"
			report "falha no reset inicial" severity error;
			
		-- cliques 1~3: addi $r1, $r0, 5 - AluOut = 5 no clique 3
		step_cpu(3);
		assert instruction_out = x"5205" and ula_result = x"0005"
			report "falha em addi $r1, $r0, 5" severity error;
			
		-- clique 4: wb $r1
		-- cliques 5~11: addi $r2, $r0, 3 & add $r3, $r1, $r2 - AluOut = 8 no clique 11
		step_cpu(8);
		assert instruction_out = x"0652" and ula_result = x"0008"
			report "falha em add $r3, $r1, $r2" severity error;
			
		-- clique 12: wb $r3
		-- cliques 13~15: sub $r4, $r1, R2 - AluOut = 2 & cout = 1 no clique 15
		step_cpu(4);
		assert ula_result = x"0002" and cout = '1'
			report "falha em sub $r4, $r1, $r2" severity error;
			
		-- clique 16: wb $r4
		-- cliques 17~32: and $r5=1 & or $r6=7 & slt $r7=1 & addi $r3=000C
		-- cliques 33~36: st $r3, $r0, 24 (Mem[0x18] = 000C)
		-- cliques 37~40: ld $r4, $r0, 24 - mdr = 000C & state = wb no clique 40
		step_cpu(25);
		assert instruction_out = x"6818" and mdr_out = x"000C" and state_out = "10000"
			report "falha st/ld (MDR esperado = 000C no clique 40)" severity error;
			
		-- clique 41: wb $r4 (000C)
		-- cliques 42~44: addi $r4, $r4, -2 - AluOut = 000A & cout = 1 no clique 44
		step_cpu(4);
		assert ula_result = x"000A" and cout = '1'
			report "Falha ADDI negativo" severity error;
			
		-- clique 45: wb $r4 (000A)
		-- cliques 46~48: slt $r7, $r1, $r2 (falso) - AluOut = 0000 & zero = 1 no clique 48
		step_cpu(4);
		assert ula_result = x"0000" and zero = '1'
			report "Falha SLT falso" severity error;

			
		-- clique 49: wb $r7
		-- cliques 50~52: beq $r3, $r4, 2 (nao tomado, 12 != 10)
		-- cliques 53~55: bne $r3, $r4, 1 (tomado, pula 0x0E) - pc = 000F no clique 55
		step_cpu(7);
		assert pc_current = x"000F"
			report "falha BNE tomado (PC esperado = 000F)" severity error;
			
		-- cliques 56~58: beq $r3, $r3, 1 (tomado, pula 0x10 -> 0x11)
		-- cliques 59~61: jmp 0x013
		-- cliques 62~64: beq $r0, $r0, -2 (salto negativo) - pc = 0012 no clique 64
		step_cpu(9);
		assert pc_current = x"0012"
			report "Falha BEQ negativo (PC esperado = 0012)" severity error;
			
		-- cliques 65~67: jmp 0x014
		-- cliques 68~70: bne $r3, $r3, 1 (nao tomado, 12 == 12)
		-- cliques 71~74: add $r0, $r1, $r2 (escrita em $r0 ignorada)
		-- cliques 75~77: add $r7, $r2, $r0 - AluOut = 0003 no clique 77 (prova $r0 = 0)
		step_cpu(13);
		assert ula_result = x"0003"
			report "falha protecao de R0 (AluOut esperado = 0003)" severity error;
			
		-- clique 78: wb $r7
		-- cliques 79~81: jmp 0x000 - pc = 0000 & state = fetch no clique 81
		step_cpu(4);
		assert pc_current = x"0000" and state_out = "00001"
			report "Falha JMP 0x000 no clique 81" severity error;
			
		report "simulaçao concluida com sucesso (81 cliques validados)" severity note;
		sim_finished <= true;
		wait;
	end process;
end architecture test;
