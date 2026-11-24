# Checklist de Correções e Pendências — CPU 16 bits Multiciclo

Checklist baseado no VHDL atual, nos requisitos do projeto e nos resultados do ModelSim e do Quartus.

---

## Parte 1 — Bugs Críticos na Lógica da CPU (VHDL) ✅

- [x] **Corrigir seleção de `read_reg2` na Unidade de Controle (instruções Tipo R: `ADD`, `SUB`, `AND`, `OR`, `SLT`)**
  - Em `S_ID`, `RegDst = '1'` seleciona `Rk` (`IR(5 downto 3)`) para `read_reg2` nas instruções tipo R. Com `RegDst = '0'`, a segunda porta lê `Ri` (`IR(11 downto 9)`), usado por `ST`, `BEQ` e `BNE`.
  - O endereço de escrita é sempre `Ri` nas instruções que habilitam `RegWrite`.
- [x] **Corrigir cálculo do endereço de desvio em `S_ID` (`BEQ` e `BNE`)**
  - Resolvido em `src/control_unit.vhd` (`AluSrcA <= '0'`, `AluSrcB <= "10"`, `AluOp <= "00"`), calculando `PC + imediato` em `AluOut` com o PC já incrementado na busca.
- [x] **Corrigir falta de `state_out` em `S_WB_R` (evitar *latch* e LED errado)**
  - Resolvido em `src/control_unit.vhd` com valor padrão `state_out <= "00000"` e `state_out <= "10000"` em `S_WB_R`.

---

## Parte 2 — Memória (`.mif`) e Síntese no Quartus

- [x] **Converter a leitura de `src/memory_unit.vhd` para síncrona.** A RAM usa `s_mem_clk <= not clk` em `src/datapath.vhd`.
- [x] **Expandir os casos de teste em `src/ram_init.mif`** com imediato negativo, `SLT` falso, desvios tomados e não tomados e salto para trás.
- [x] **Corrigir a colisão de código e dados no endereço `0x10`.** O `ST` em `0x08` e o `LD` em `0x09` usam o imediato `24` (`0x18`), preservando a instrução em `0x10`.
- [x] **Validar a inferência de M9K e o vínculo com o MIF no Quartus.** A compilação de diagnóstico com `datapath_board` confirmou uma RAM de 256 × 16 bits em 1 M9K, com `ram_init.mif` no relatório do Fitter.

---

## Parte 3 — Testbench / Simulação

- [x] **Adaptar `src/datapath_tb.vhd` para a CPU multiciclo de 16 bits.**
  - `pc_current` e `instruction_out` têm 16 bits. O testbench observa `mdr_out` e `state_out` e usa a interface atual do datapath.
  - O reset é liberado depois da primeira borda de descida do clock, quando a RAM já fez a leitura do endereço zero. O testbench roda uma volta de 81 ciclos do programa atual.
- [x] **Validar as 11 instruções, `state_out` e `mdr_out` no ModelSim.** As checagens cobriram PC, FSM, ULA e MDR, além de `SLT` verdadeiro e falso, imediato negativo e desvios tomados e não tomados. O `ADD R3, R1, R2` confirmou a seleção de `R2` por `RegDst` e a escrita de `8` em `R3`.
- [ ] **Registrar no projeto como repetir a simulação.** A execução usou um arquivo temporário gerado de `ram_init.mif` e carregado na RAM com `mem load` no ModelSim. Falta salvar o fluxo ou documentar os comandos de conversão, carregamento e checagem. O atributo `ram_init_file` já atende à síntese no Quartus.

---

## Parte 4 — Placa FPGA (DE2-115) e Projeto Quartus

- [ ] **Implementar o debouncer do clock manual em `src/datapath_board.vhd`.**
  - Adicionar `CLOCK_50` e usá-lo para filtrar `KEY(0)` (~10–20 ms). A CPU avança na borda de subida e a RAM opera na borda de descida.
- [ ] **Completar as configurações de `src/datapath.qsf`.**
  - [x] Definir `datapath_board` como top-level.
  - [ ] Atribuir `LEDG[0..4]` a `PIN_E21`, `PIN_E22`, `PIN_E25`, `PIN_E24` e `PIN_H21`, respectivamente, e `CLOCK_50` a `PIN_Y2`. O Fitter atribuiu automaticamente os cinco pinos de LED na compilação de diagnóstico.
  - [ ] Remover as referências a `instruction_memory.vhd` e `ula_tb` e registrar `ram_init.mif` explicitamente no projeto. O Quartus já encontrou o MIF pelo atributo da RAM.
- [ ] **Alinhar `SW(17)` e o display `HEX4`–`HEX7` ao README.**
  - Hoje, `1` seleciona MDR e `0` seleciona ULA. O README define `0` para MDR e `1` para ULA. Confirmar o uso de `AluOut`, que é o resultado registrado exibido atualmente.
- [ ] **Adicionar as restrições de temporização e recompilar.** A compilação de diagnóstico terminou com 0 erros e 34 avisos, incluindo a ausência de `datapath.sdc` e de atribuições para os cinco LEDs.
- [ ] **Validar na DE2-115.** Conferir a primeira busca após reset, um avanço de estado por pressão de `KEY(0)`, o PC em `HEX0`–`HEX3`, os estados em `LEDG` e a troca entre MDR e ULA. No `LD` do programa, conferir `000C` no MDR ao entrar em write-back.

---

## Parte 5 — Limpeza e Boas Práticas nos `.vhd`

- [x] **Remover os valores fixos de `R1` e `R2` no reset.** O banco reinicia em zero e as instruções em `0x00` e `0x01` do MIF inicializam `R1` com 5 e `R2` com 3.
- [x] **Ajustar o estilo síncrono em `src/pc.vhd`.** A condição de escrita está dentro do bloco `elsif rising_edge(clk)`.
- [x] **Atualizar os nomes das entradas da ULA e o comentário de `NorOp`.** As assinaturas atuais de `src/ula.vhd` e `src/datapath_pkg.vhd` já refletem esses ajustes.
- [x] **Limpar referências obsoletas no VHDL.** `ula_pkg.vhd` foi removido, `instruction_out` está ligado a `open` no wrapper da placa e `S_EX_MEM` usa o valor padrão de `PCSrc`.
- [ ] **Remover a atribuição redundante de `AluSrcB` em `S_ID`.** O valor `"10"` já é definido antes da condição específica de `BEQ` e `BNE`.

---

## Parte 6 — Documentação e Entrega (CANVAS)

Baseado na seção **ENTREGA** do `Projeto.pdf` e no estado atual de `docs/relatorio.typ`:

- [ ] **Corrigir inconsistências na parte já escrita de `docs/relatorio.typ`**
  - **Capa** (L85–L89): adicionar o 4º integrante (**Kelvin Borges** + RA), pois o PDF exige grupos de 4 a 5 pessoas.
  - **Tabela de sinais, FSM e texto do datapath**: descrever `RegDst` como seletor de `read_reg2` em `S_ID`. No write-back, documentar `Ri` como endereço de escrita, `RegWrite` como habilitação e `MemtoReg` como seleção do dado. Atualizar as descrições de `S_WB_R`, `S_EX_ADDI` e `S_EX_JMP` e documentar o mapeamento de `state_out` nos `LEDG`.
  - **Banco de registradores** (L122): afirmar definitivamente que `R0` é fixo em `0`.
- [ ] **Atualizar diagramas para bater com o VHDL de 16 bits**
  - Atualizar `docs/diagrama_datapath.png` com o incremento `+1`, retirar os blocos de deslocamento por 2 e ligar `RegDst` ao multiplexador de `Read Reg 2` (`Rk` ou `Ri`). Ligar `Ri` diretamente a `Write Reg`, alinhar a seleção de `PCSrc` ao VHDL e representar o controle de `BNE` (`XOR` com `Zero`).
  - Atualizar `docs/diagrama_fsm.svg` com os sinais corrigidos de `control_unit.vhd`.
- [ ] **Preencher as 4 seções ainda marcadas como `#pendente` em `docs/relatorio.typ` (L252–L291)**
  - `Descrição dos Testes Utilizados` (testbench, `.mif` comentado e testes na DE2-115);
  - `Resultados e Discussão` (formas de onda da simulação, resultados na placa, fotos/relato);
  - `Dificuldades Encontradas`;
  - `Uso de IA` (quais partes usaram IA, por quê e como foram revisadas).
- [ ] **Gerar e revisar o pacote final de entrega no CANVAS**
  - Compilar `docs/relatorio.typ` para `.pdf`;
  - Conferir envio conjunto dos `.pdf`, `.vhd` e `.mif`.
