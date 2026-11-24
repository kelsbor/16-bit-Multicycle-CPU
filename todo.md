# Checklist de Correções e Pendências — CPU 16 bits Multiciclo

Análise estática dos arquivos `.vhd`, `.mif`, `.qsf` e documentação comparados aos requisitos do `Projeto.pdf`.

---

## Parte 1 — Bugs Críticos na Lógica da CPU (VHDL) ✅

- [x] **Corrigir seleção de `read_reg2` na Unidade de Controle (instruções Tipo R: `ADD`, `SUB`, `AND`, `OR`, `SLT`)**
  - Resolvido via sinal `ReadReg2Sel` ativo em `S_ID` para Tipo R (`src/control_unit.vhd`, `src/datapath.vhd`, `src/datapath_pkg.vhd`), mantendo `s_write_reg <= Ri`.
- [x] **Corrigir cálculo do endereço de desvio em `S_ID` (`BEQ` e `BNE`)**
  - Resolvido em `src/control_unit.vhd` (`AluSrcA <= '0'`, `AluSrcB <= "10"`, `AluOp <= "00"`), calculando `PC + imediato` em `AluOut`.
- [x] **Corrigir falta de `state_out` em `S_WB_R` (evitar *latch* e LED errado)**
  - Resolvido em `src/control_unit.vhd` com valor padrão `state_out <= "00000"` e `state_out <= "10000"` em `S_WB_R`.

---

## Parte 2 — Memória (`.mif`) e Síntese no Quartus (Ajustes antes do Testbench)

- [x] **Converter leitura de `src/memory_unit.vhd` para síncrona (`s_mem_clk <= not clk` em `src/datapath.vhd`)**
- [x] **Expandir casos de teste em `src/ram_init.mif` (imediato negativo, `SLT` falso, `BEQ`/`BNE` e salto reverso)**
- [ ] **Corrigir colisão de endereço `0x10` em `src/ram_init.mif` (bloqueia teste completo)**
  - `06 : ST $3, $0, 16` grava `0x000C` em `0x10`, sobrescrevendo a instrução `10 : JMP 0x000` e causando loop infinito entre `0x10` e `0x11`.
  - **Correção:** alterar o imediato de `ST` (`06`) e `LD` (`07`) de `16` (`010000` = `0x10`) para um endereço na área livre de dados `0x12..0x1F` (ex.: `24` = `011000` = `0x18`).
- [ ] **Garantir inicialização da RAM na simulação (`src/memory_unit.vhd`)**
  - `attribute ram_init_file` só é lido pelo Quartus na síntese e é **ignorado pelo ModelSim/GHDL** (a `ram` inicia em `'U'` no testbench).
  - **Correção:** inicializar a `ram` em VHDL (valor inicial / função de leitura de `.mif`) ou usar o IP `altsyncram` (`RAM: 1-PORT`) do Quartus para funcionar tanto na simulação quanto na FPGA.
- [ ] **Validar inferência de M9K + `.mif` no Quartus com `datapath` / `datapath_board` como Top-Level**
  - A última compilação (`src/output_files/datapath.map.rpt`) elaborou apenas `register_bank`.

---

## Parte 3 — Testbench / Simulação (Próximo passo — em desenvolvimento)

- [ ] **Reescrever `src/datapath_tb.vhd` para a CPU multiciclo de 16 bits**
  - Ajustar larguras de `pc_current` e `instruction_out` de 32 bits para **16 bits**.
  - Remover a porta inexistente `reg_write` e conectar `mdr_out` e `state_out`.
  - Adaptar a sequência de ciclos e `assert`s para execução **multiciclo** (3 ciclos para `BEQ`/`BNE`/`JMP`, 4 para Tipo R/`ADDI`/`ST`, 5 para `LD`; `PC` somando `+1`; 8 registradores `R0`–`R7`).
  - **Atenção ao `reset` + `s_mem_clk <= not clk`:** garantir ao menos uma `falling_edge(clk)` com `PC = 0x0000` e `IorD = '0'` antes da primeira `rising_edge(clk)` ativa após liberar `reset`, para que `IR` capture `ram(0)` corretamente.
  - Validar todas as 11 instruções da ISA (`ADD`, `SUB`, `AND`, `OR`, `SLT` 1/0, `ADDI` +/-, `ST`, `LD`, `BEQ` tomado/não tomado/negativo, `BNE`, `JMP`), além de `state_out` e `mdr_out`.

---

## Parte 4 — Placa FPGA (DE2-115) e Projeto Quartus

- [ ] **Implementar o Debouncer para o botão de clock em `src/datapath_board.vhd` (L39–L40)**
  - O `Projeto.pdf` pede explicitamente: *"Utilize um dos botões para controlar o sinal de clock (lembre do debouncer)"*.
  - Adicionar `CLOCK_50 : in std_logic` (pino `PIN_Y2`) em `src/datapath_board.vhd` e um circuito debouncer (~10–20 ms) para `KEY(0)` (e opcionalmente `KEY(1)`).
- [ ] **Corrigir configurações críticas em `src/datapath.qsf`**
  - **Top-level errado** (L42): está `TOP_LEVEL_ENTITY register_bank` (antes `control_unit`) — alterar para `datapath_board`.
  - **Pinos ausentes:** adicionar `set_location_assignment` para `LEDG[0..4]` (`PIN_E21`, `PIN_E22`, `PIN_E25`, `PIN_E24`, `PIN_H21`) e `CLOCK_50` (`PIN_Y2`).
  - **Arquivos fantasmas:** remover referências a `instruction_memory.vhd` (L161) e `ula_tb.vhd` (L148) que não existem, e incluir `ram_init.mif` no projeto.
- [ ] **Conferir polaridade do `SW(17)` e saída da ULA nos displays `HEX4`–`HEX7`**
  - Em `src/datapath_board.vhd` (L59), `SW(17) = '1'` mostra `MDR` e `'0'` mostra `ULA` — está invertido em relação ao `README.md` (L57). Alinhar código e documentação.
  - Em `src/datapath.vhd` (L209), `ula_result` está ligado em `s_alu_out` (registrado) e não em `s_ula_res` (combinacional). Confirmar se é o comportamento desejado na apresentação da placa.

---

## Parte 5 — Limpeza e Boas Práticas nos `.vhd`

- [ ] **Remover valores hardcoded no banco de registradores (ou documentar explicitamente)**
  - Em `src/register_bank.vhd` (L28–L38), `R1` e `R2` reiniciam em `5` e `3` no reset. Ideal: zerar todos os registradores no reset e inicializar no `.mif` via `ADDI $1, $0, 5` e `ADDI $2, $0, 3`.
- [ ] **Ajustar estilo síncrono em `src/pc.vhd` (L39–L41)**
  - Trocar `elsif (rising_edge(clk) AND write='1') then` por `elsif rising_edge(clk) then if write = '1' then ...`.
- [ ] **Limpar sinais mortos, redundâncias e arquivos obsoletos**
  - Remover `src/ula_pkg.vhd` (package antigo não utilizado com assinaturas desatualizadas).
  - Remover sinal morto `RegDst` / `s_RegDst` em `src/control_unit.vhd`, `src/datapath.vhd` e `src/datapath_pkg.vhd` (substituído por `ReadReg2Sel`).
  - Em `src/control_unit.vhd` (L158): remover `PCSrc <= "01"` desnecessário em `S_EX_MEM`.
  - Em `src/ula.vhd` (L22–L28) e `src/datapath_pkg.vhd` (L43–L49): revisar nomes confusos (`A_Ri_data`, `B_Rj_data`, `B_4`, `B_End`) e o comentário `NotOp` (implementa `NOR`).
  - Em `src/datapath_board.vhd` (L32): remover o sinal não utilizado `s_inst` (ou ligar `instruction_out => open`).

---

## Parte 6 — Documentação e Entrega (CANVAS)

Baseado na seção **ENTREGA** do `Projeto.pdf` e no estado atual de `docs/relatorio.typ`:

- [ ] **Corrigir inconsistências na parte já escrita de `docs/relatorio.typ`**
  - **Capa** (L85–L89): adicionar o 4º integrante (**Kelvin Borges** + RA), pois o PDF exige grupos de 4 a 5 pessoas.
  - **Tabela de sinais / FSM** (L203–L236): atualizar para `ReadReg2Sel` (em vez de `RegDst` em `write_reg`), refletir as correções da Parte 1 em `S_ID`, `S_WB_R`, `S_EX_ADDI`, `S_EX_JMP`, e documentar `state_out` (mapeamento dos `LEDG`).
  - **Banco de registradores** (L122): afirmar definitivamente que `R0` é fixo em `0`.
- [ ] **Atualizar diagramas para bater com o VHDL de 16 bits**
  - `docs/diagrama_datapath.png` ainda tem restos de MIPS 32 bits: constante `4` em vez de `1`, dois blocos `Shif Left 2` (inexistentes e com erro de grafia), `RegDst` no `Write Reg` em vez de `ReadReg2Sel` no `Read Reg 2`, `PCSrc` `0`/`1` invertidos e falta o controle de `BNE` (`XOR` com `Zero`).
  - Atualizar `docs/diagrama_fsm.svg` com os sinais corrigidos de `control_unit.vhd`.
- [ ] **Preencher as 4 seções ainda marcadas como `#pendente` em `docs/relatorio.typ` (L252–L291)**
  - `Descrição dos Testes Utilizados` (testbench, `.mif` comentado e testes na DE2-115);
  - `Resultados e Discussão` (formas de onda da simulação, resultados na placa, fotos/relato);
  - `Dificuldades Encontradas`;
  - `Uso de IA` (quais partes usaram IA, por quê e como foram revisadas).
- [ ] **Gerar e revisar o pacote final de entrega no CANVAS**
  - Compilar `docs/relatorio.typ` para `.pdf`;
  - Conferir envio conjunto dos `.pdf`, `.vhd` e `.mif`.
