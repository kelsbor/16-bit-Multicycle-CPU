# Checklist de Correções e Pendências — CPU 16 bits Multiciclo

Análise estática dos arquivos `.vhd`, `.mif`, `.qsf` e documentação comparados aos requisitos do `Projeto.pdf`.

---

## Parte 1 — Bugs Críticos na Lógica da CPU (VHDL)

Esses erros impedem o funcionamento correto das instruções mesmo em simulação:

- [x] **Corrigir `RegDst` na Unidade de Controle (quebra TODAS as instruções Tipo R: `ADD`, `SUB`, `AND`, `OR`, `SLT`)**
  - Em `src/datapath.vhd` (L142–L156), `s_RegDst` multiplexa `read_reg2` (`Rk` quando `'1'`, `Ri` quando `'0'`), que é capturado em `reg_B` na borda de subida ao sair de **`S_ID`**.
  - Porém, em `src/control_unit.vhd` (L100–L150), `RegDst` fica em `'0'` durante `S_ID` e só vai para `'1'` em `S_WB_R` (tarde demais, e `write_reg` já é fixo em `Ri`). Resultado: todas as instruções Tipo R leem `Ri` em vez de `Rk` para `reg_B`.
  - **Correção:** ativar `RegDst <= '1'` no estado `S_ID` quando `opcode` for Tipo R (`OP_ADD | OP_SUB | OP_AND | OP_OR | OP_SLT`) e remover a lógica de `RegDst` de `S_WB_R`.

- [x] **Corrigir cálculo do endereço de desvio em `S_ID` (quebra `BEQ` e `BNE`)**
  - Em `src/control_unit.vhd` (L100–L102), `S_ID` define `AluSrcB <= "11"`.
  - Em `src/ula.vhd` (L80–L85) e `src/datapath.vhd` (L189–L191), `"11"` seleciona `B_End` (`s_jump_addr = PC[15:12] & IR[11:0]`), somando `PC + s_jump_addr` em `AluOut` em vez de `PC + imediato`.
  - **Correção:** mudar para `AluSrcB <= "10"` em `S_ID` para selecionar `B_Ime` (`s_imm_ext`), já que a memória é endereçada por palavra (sem *shift left 2*).

- [x] **Corrigir falta de `state_out` em `S_WB_R` (gera *latch* indesejado e LED errado)**
  - Em `src/control_unit.vhd` (L72–L87) não há valor padrão para `state_out`, e em `S_WB_R` (L141–L150) `state_out` não é atribuído.
  - **Correção:** inicializar `state_out <= "00000";` no início do processo combinacional e atribuir `state_out <= "10000";` em `S_WB_R` (assim como em `S_WB_LD`).

---

## Parte 2 — Memória (`.mif`) e Síntese no Quartus

- [x] **Corrigir inferência de RAM + carregamento do `.mif` em `src/memory_unit.vhd` (L23–L46)**
  - A leitura atual (`data <= ram(...)`) é **assíncrona/combinacional**. Na Cyclone IV E (DE2-115), blocos M9K exigem leitura **síncrona**; quando a RAM cai para registradores/lógica, o Quartus **ignora `attribute ram_init_file`** e a memória sobe zerada na FPGA (além de ficar sem inicialização `'U'` na simulação).
  - **Correção:** usar memória síncrona (ou IP `RAM: 1-PORT` / `altsyncram` do Quartus vinculada ao `.mif`). Para não adicionar estados extras de espera na FSM, o clock da RAM pode usar `falling_edge(clk)` ou o `CLOCK_50` da placa.

- [x] **Corrigir imediato inválido (`32`) e ampliar cobertura em `src/ram_init.mif` (L55–L61)**
  - Nas instruções `ST` (endereço `06`) e `LD` (endereço `07`), o imediato de 6 bits está como `100000` com comentário indicando `+32 (0x20)`. Em complemento de dois de 6 bits (faixa **-32 a +31**), `100000` estende para `0xFFE0` (**-32**), acessando `0xE0` (224) e exibindo `FFE0` na ULA em vez de `0020`. Trocar para um endereço `<= 31` (ex.: `010000` = `0x10`).
  - Adicionar casos de teste faltantes para validar todas as instruções e imediatos positivos/negativos:
    - `ADDI` com imediato **negativo**;
    - `SLT` resultando em `0` (além do caso `1`);
    - `BNE` **tomado** (hoje só testa não tomado) e `BEQ` **não tomado** (hoje só testa tomado);
    - desvio com offset **negativo** (salto para trás).

---

## Parte 3 — Placa FPGA (DE2-115) e Projeto Quartus

- [ ] **Implementar o Debouncer para o botão de clock em `src/datapath_board.vhd` (L39–L40)**
  - O `Projeto.pdf` pede explicitamente: *"Utilize um dos botões para controlar o sinal de clock (lembre do debouncer)"*.
  - Atualmente `s_clk <= not KEY(0)` vai direto para a CPU, sem porta `CLOCK_50` e sem circuito debouncer.
  - **Correção:** adicionar `CLOCK_50 : in std_logic` (pino `PIN_Y2`) em `src/datapath_board.vhd` e um módulo/processo debouncer (ex.: filtro de ~10–20 ms) para `KEY(0)` (e opcionalmente `KEY(1)`).

- [ ] **Corrigir configurações críticas em `src/datapath.qsf`**
  - **Top-level errado** (L42): está `TOP_LEVEL_ENTITY control_unit` em vez de `datapath_board`.
  - **Pinos de `LEDG[0..4]` ausentes:** não há `set_location_assignment` para `LEDG[0..4]` (na DE2-115: `PIN_E21`, `PIN_E22`, `PIN_E25`, `PIN_E24`, `PIN_H21`), nem para `CLOCK_50` (`PIN_Y2`) após incluir o debouncer.
  - **Arquivos fantasmas:** remover referência a `instruction_memory.vhd` (L164) e `ula_tb.vhd` (L148) que não existem, e adicionar `ram_init.mif` ao projeto.

- [ ] **Conferir polaridade do `SW(17)` e saída da ULA nos displays `HEX4`–`HEX7`**
  - Em `src/datapath_board.vhd` (L59), `SW(17) = '1'` mostra `MDR` e `'0'` mostra `ULA` — está invertido em relação ao `README.md` (L57). Alinhar código e documentação.
  - Em `src/datapath.vhd` (L199), `ula_result` está ligado em `s_alu_out` (registrado, atualizado só na próxima borda) e não em `s_ula_res` (combinacional do ciclo atual). Verificar se é esse o comportamento desejado na apresentação da placa.

---

## Parte 4 — Limpeza e Boas Práticas nos `.vhd`

- [ ] **Remover valores hardcoded no banco de registradores (ou documentar explicitamente)**
  - Em `src/register_bank.vhd` (L28–L38), `R1` e `R2` reiniciam em `5` e `3` mesmo após `reset = '1'`. O ideal é zerar todos os registradores no reset e inicializá-los no próprio `.mif` usando `ADDI $1, $0, 5` e `ADDI $2, $0, 3`.
- [ ] **Ajustar estilo síncrono em `src/pc.vhd` (L39–L41)**
  - Trocar `elsif (rising_edge(clk) AND write='1') then` por `elsif rising_edge(clk) then if write = '1' then ...` (padrão seguro de síntese para *clock enable*).
- [ ] **Limpar sinais redundantes e nomes confusos**
  - Em `src/control_unit.vhd`: remover `PCSrc <= "01"` desnecessário em `S_EX_ADDI` e `S_EX_MEM`, e `AluSrcA <= '1'` / `AluSrcB <= "11"` desnecessários em `S_EX_JMP`.
  - Em `src/ula.vhd` (L22–L28) e `src/datapath_pkg.vhd` (L43–L49): os nomes `A_Ri_data`, `B_Rj_data`, `B_4` e `B_End` não refletem o que realmente entra (recebem `reg_A`=`Rj`, `reg_B`=`Rk/Ri` e `x"0001"`), e o comentário de `111` diz `NotOp` enquanto implementa `NOR`.
  - Em `src/datapath_board.vhd` (L32): remover o sinal não utilizado `s_inst` (ou deixar `instruction_out => open`).

---

## Parte 5 — Testbench (Simulação)

- [ ] **Reescrever `src/datapath_tb.vhd` (atualmente não compila)**
  - `pc_current` e `instruction_out` ainda estão com **32 bits** (L15–L16) em vez de 16 bits.
  - Mapeia a porta inexistente `reg_write` (L30) e não conecta `mdr_out` nem `state_out`.
  - Os `assert` foram feitos para uma CPU **monociclo** de 32 bits (`PC` somando `+4`, 1 ciclo por instrução, registradores `$8`/`$9` e instrução `NOR`), em vez da CPU **multiciclo** de 16 bits (3 a 5 ciclos por instrução, `PC` somando `+1`, 8 registradores `R0`–`R7`).
  - Atualizar para testar todas as 11 instruções da ISA do PDF + `state_out` + `mdr_out`.

---

## Parte 6 — Documentação e Entrega (CANVAS)

Baseado na seção **ENTREGA** do `Projeto.pdf` e no estado atual de `docs/relatorio.typ`:

- [ ] **Corrigir inconsistências na parte já escrita de `docs/relatorio.typ`**
  - **Capa** (L85–L89): adicionar o 4º integrante (**Kelvin Borges** + RA), pois o PDF exige grupos de 4 a 5 pessoas.
  - **Tabela de sinais / FSM** (L203–L236): atualizar a descrição de `RegDst` (seleciona `read_reg2`, não `write_reg`), refletir as correções da Parte 1 em `S_ID` e `S_WB_R`, e documentar `state_out` (mapeamento dos `LEDG`).
  - **Banco de registradores** (L122): afirmar definitivamente que `R0` é fixo em `0`.
- [ ] **Atualizar diagramas para bater com o VHDL de 16 bits**
  - `docs/diagrama_datapath.png` ainda tem restos de MIPS 32 bits que contradizem o código: constante `4` em vez de `1`, dois blocos `Shif Left 2` (inexistentes e com erro de grafia), `RegDst` no `Write Reg` em vez de `Read Reg 2`, `PCSrc` `0`/`1` invertidos e falta o controle de `BNE` (porta `XOR` com `Zero`).
  - Atualizar `docs/diagrama_fsm.svg` após corrigir os sinais em `S_ID`, `S_WB_R`, `S_EX_ADDI`, `S_EX_MEM` e `S_EX_JMP`.
- [ ] **Preencher as 4 seções ainda marcadas como `#pendente` em `docs/relatorio.typ` (L252–L291)**
  - `Descrição dos Testes Utilizados` (testbench, `.mif` comentado e testes na DE2-115);
  - `Resultados e Discussão` (formas de onda da simulação, resultados na placa, fotos/relato);
  - `Dificuldades Encontradas`;
  - `Uso de IA` (quais partes usaram IA, por quê e como foram revisadas).
- [ ] **Gerar e revisar o pacote final de entrega no CANVAS**
  - Compilar `docs/relatorio.typ` para `.pdf`;
  - Conferir envio conjunto dos `.pdf`, `.vhd` e `.mif`.
