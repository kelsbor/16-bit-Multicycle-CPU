#set document(
  title: "Projeto Final - CPU 16 Bits Multiciclo em VHDL",
  author: "Grupo 10",
)

#set page(
  paper: "a4",
  margin: (top: 3cm, left: 3cm, bottom: 2cm, right: 2cm),
)

#set text(
  font: "Linux Libertine",
  size: 11pt,
  lang: "pt",
)

#show heading.where(level: 1): set text(size: 14pt, weight: "bold", fill: rgb("#1a237e"))
#show heading.where(level: 2): set text(size: 12pt, weight: "bold")
#show heading.where(level: 3): set text(size: 10.5pt, weight: "bold")
#show heading: set block(above: 1em, below: 0.7em)

#set par(
  first-line-indent: 1em,
  spacing: 0.75em,
  justify: true,
  linebreaks: "optimized",
)

#show raw.where(block: true): it => block(
  fill: luma(245),
  inset: 6pt,
  radius: 2pt,
  width: 100%,
  text(size: 9.5pt, it),
)

#show raw.where(block: false): box.with(
  fill: luma(242),
  inset: (x: 3pt, y: 0pt),
  outset: (y: 2pt),
  radius: 2pt,
)

#set table(
  stroke: 0.5pt + luma(150),
  inset: 4.5pt,
)

#show figure.caption: set text(size: 9.5pt, style: "italic", fill: luma(70))

// ========================== CAPA ==========================
#align(center)[
  #text(weight: "bold")[PONTIFÍCIA UNIVERSIDADE CATÓLICA DE CAMPINAS]\
  #text(weight: "bold")[Engenharia de Computação]\
  #v(1.2cm)
  #image("image (10).png", width: 55%)
  #v(0.6cm)
  #text(weight: "bold", size: 1.4em)[Grupo 10]\
  #text(size: 1.2em)[
    Curso : Engenharia da Computação \
    Professor: Leonardo Rezende Costa \
    Disciplina: Arquitetura de Sistemas Computacionais
  ]
  #v(2.8cm)

  #block(width: 100%, align(center)[
    #text(size: 13pt)[
      *Integrantes:* \
      #v(0.4em)
      Carlos Eduardo A. Nascimento - 24787111 \
      Daniel Wu - 24021993 \
      Guilherme Dias Cavalheri - 24013423 \
      Kelvin Huss Borges - 24795486
    ]
  ])

  #v(1fr)
  #text(weight: "bold", size: 12pt)[Campinas, 2° Semestre de 2026]
]

#pagebreak()

#set page(numbering: "1")
#counter(page).update(1)
#set heading(numbering: "1.1.")

// ==================== 1. DESCRIÇÃO ====================
= Descrição

Foi idealizada e desenvolvida uma unidade central de processamento (CPU), a partir do aprendizado adquirido através das aulas teóricas e práticas da disciplina de *Arquitetura de Sistemas Computacionais*. Por conta do propósito educacional do projeto, e buscando uma implementação facilitada na placa Altera DE2-115, a CPU desenvolvida é uma CPU de 16 bits, com execução em multiciclo.

A topologia adotada parte de uma arquitetura de von Neumann adaptada a partir do modelo MIPS multiciclo: mantém uma única memória unificada para instruções e dados e uma única ULA de 16 bits compartilhada entre incremento do `PC`, cálculo de endereços e operações lógico-aritméticas, mas incorpora adaptações específicas para a ISA de 16 bits e para a execução em FPGA — entre elas o endereçamento por palavra (dispensando deslocamentos por 2), o reposicionamento do multiplexador `RegDst` na segunda porta de leitura do banco de registradores (com escrita fixa em `Ri`) e sinais dedicados de habilitação (`step_en`, `AluOutWrite` e controle de escrita no `MDR`). Dividindo a execução em etapas de um ciclo (busca, decodificação, execução, memória e escrita), cada instrução leva entre 3 e 5 ciclos (3 para saltos, 4 para Tipo R, `ADDI` e `ST`, e 5 para `LD`), com registradores intermediários guardando os dados entre ciclos e uma máquina de estados (FSM) coordenando os sinais de controle. O projeto em VHDL foi modularizado em `pc`, `memory_unit`, `instruction_register`, `memory_data_register`, `register_bank`, `ula`, `control_unit`, `datapath` e nos módulos de interface da placa (`datapath_board` e `display_logic`).

// ==================== 2. ESPECIFICAÇÃO ====================
= Especificação

== Registradores

A CPU trabalha com palavra de 16 bits. Os campos de registrador nas instruções (`Ri`, `Rj`, `Rk`) têm 3 bits, endereçando $2^3 = 8$ registradores de propósito geral (`R0` a `R7`), com duas portas de leitura assíncronas e uma de escrita síncrona (`RegWrite`), sendo `R0` permanentemente fixo em `0` conforme a convenção MIPS. Além do banco, o multiciclo utiliza registradores internos de 16 bits sincronizados pelo clock global `CLOCK_50` sob habilitação de passo (`step_en`), conforme detalhado na @tab-regs. Para evitar sobrescritas indesejadas nos ciclos ociosos e garantir estabilidade na visualização em bancada, tanto o `MDR` (`RDM`) quanto o `AluOut` possuem controle dedicado de escrita (`MemRead` e `IorD` para o `MDR`; `AluOutWrite` para o `AluOut`), enquanto `A` e `B` capturam os operandos a cada passo.

#figure(
  table(
    columns: (auto, auto, auto, auto, 1fr),
    align: (left, center, center, center, left),
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
    table.header[*Registrador*][*Qtd.*][*Endereço*][*Tam.*][*Função / Controle*],
    [`R0` a `R7`], [8], [`000`–`111`], [16 b], [Banco de propósito geral (`RegWrite` e `step_en`; `R0` fixo em `0`).],
    [`PC`], [1], [-], [16 b], [Endereço da instrução atual/próxima (`PCWrite` / `PCWriteCond` e `step_en`).],
    [`IR`], [1], [-], [16 b], [Retém a instrução buscada durante toda a execução (`IRWrite` e `step_en`).],
    [`MDR` (`RDM`)], [1], [-], [16 b], [Retém o dado lido em `LD` (`MemRead and IorD and step_en`).],
    [`A`, `B`], [2], [-], [16 b], [Armazenam os operandos lidos do banco na decodificação (`step_en`).],
    [`AluOut`], [1], [-], [16 b], [Salva a saída útil da ULA e sincroniza as flags `LEDR` (`AluOutWrite and step_en`).],
  ),
  caption: [Especificação do banco de registradores e registradores internos da CPU.],
) <tab-regs>

== Formato das Instruções

As instruções possuem 16 bits (`[15:0]`), sempre com o `Opcode` nos 4 bits mais significativos (`[15:12]`), distribuídas nos três formatos da @tab-formatos. No Tipo R, os 3 bits menos significativos (`[2:0]`) - marcados como não usados no enunciado - foram aproveitados como campo `Funct` para definir a operação da ULA, como no MIPS de 32 bits. No Tipo I, o imediato de 6 bits em complemento de dois ($-32$ a $+31$) passa por um *Sign Extend* para 16 bits.

#figure(
  table(
    columns: (1.1fr, 1.1fr, 0.9fr, 0.9fr, 0.9fr, 1.3fr),
    align: center,
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
    table.header[*Formato*][*`[15:12]`*][*`[11:9]`*][*`[8:6]`*][*`[5:3]`*][*`[2:0]`*],
    [*Tipo R*], [`Opcode` (4b)], [`Ri` (3b)], [`Rj` (3b)], [`Rk` (3b)], [`Funct` (3b)],
    [*Tipo I*], [`Opcode` (4b)], [`Ri` (3b)], [`Rj` (3b)], table.cell(colspan: 2)[`Imediato` (`[5:0]`, 6b sinalizado)],
    [*Tipo J*], [`Opcode` (4b)], table.cell(colspan: 4)[`end` (`[11:0]`, 12b — endereço de destino)],
  ),
  caption: [Formatos das instruções de 16 bits (Tipo R, Tipo I e Tipo J).],
) <tab-formatos>

A @tab-isa resume as 11 instruções implementadas com seus opcodes (`control_unit.vhd`), campo `Funct` (`ula.vhd`), operação e ciclos. Na ULA, `AluOp = 00` força soma (`010`), `AluOp = 01` força subtração (`100`, usada na comparação de `BEQ`/`BNE`) e `AluOp = 10` repassa `Funct` diretamente para o controle interno `ULACtl` (que também conta com `111` para `NOR` auxiliar), além de gerar a flag `Zero`.

#figure(
  table(
    columns: (auto, auto, auto, auto, 1fr, auto),
    align: (left, center, center, center, left, center),
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
    table.header[*Instrução*][*Tipo*][*Opcode*][*Funct*][*Significado*][*Ciclos*],
    [`ADD Ri, Rj, Rk`], [R], [`0000`], [`010`], [`Ri` $<-$ `Rj + Rk`], [4],
    [`SUB Ri, Rj, Rk`], [R], [`0001`], [`100`], [`Ri` $<-$ `Rj - Rk`], [4],
    [`AND Ri, Rj, Rk`], [R], [`0010`], [`000`], [`Ri` $<-$ `Rj && Rk`], [4],
    [`OR Ri, Rj, Rk`], [R], [`0011`], [`001`], [`Ri` $<-$ `Rj || Rk`], [4],
    [`SLT Ri, Rj, Rk`], [R], [`0100`], [`110`], [`Ri` $<-$ `1` se `Rj < Rk`; senão `0`], [4],
    [`ADDI Ri, Rj, imm`], [I], [`0101`], [-], [`Ri` $<-$ `Rj + imm`], [4],
    [`LD Ri, Rj, imm`], [I], [`0110`], [-], [`Ri` $<-$ `Memoria[Rj + imm]`], [5],
    [`ST Ri, Rj, imm`], [I], [`0111`], [-], [`Memoria[Rj + imm]` $<-$ `Ri`], [4],
    [`BEQ Ri, Rj, imm`], [I], [`1000`], [-], [`PC` $<-$ `PC + imm`, se `Ri == Rj`], [3],
    [`BNE Ri, Rj, imm`], [I], [`1001`], [-], [`PC` $<-$ `PC + imm`, se `Ri != Rj`], [3],
    [`JMP end`], [J], [`1010`], [-], [`PC` $<-$ `end`], [3],
  ),
  caption: [Conjunto de instruções (ISA), codificação e contagem de ciclos.],
) <tab-isa>

== Unidade de Controle

A Unidade de Controle (`control_unit.vhd`) é uma FSM de 12 estados com reset assíncrono para `S_IF` e transições síncronas na borda de subida de `clk` (`CLOCK_50`) condicionadas ao pulso de passo `step_en`, conforme o `Opcode` da instrução (opcodes inválidos retornam para `S_IF`). A @tab-sinais lista os 16 sinais de saída (15 sinais de controle do caminho de dados e o indicador `state_out` para os `LEDG`), a @fig-fsm mostra o diagrama de estados e a @tab-fsm resume os sinais ativos e transições de cada estado.

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, center, left),
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
    table.header[*Sinal*][*Bits*][*Significado*],
    [`PCWrite`], [1], [Escrita incondicional no `PC` (`S_IF` e `JMP`).],
    [`PCWriteCond`], [1], [Escrita condicional no `PC` em `BEQ`/`BNE`, conforme `Zero`.],
    [`BNE`], [1], [Inverte a condição do desvio (`0`: `Zero = 1`; `1`: `Zero = 0`).],
    [`IorD`], [1], [Endereço da memória (`0`: `PC`; `1`: `AluOut`).],
    [`MemRead` / `MemWrite`], [1 / 1], [Habilitam leitura de dados (usado no `MDR` junto com `IorD`) e escrita na RAM.],
    [`IRWrite`], [1], [Grava a palavra lida da memória no `IR`.],
    [`RegWrite`], [1], [Habilita escrita no banco de registradores (sempre no destino `Ri`).],
    [`RegDst`], [1], [Seleciona a 2ª porta de leitura (`read_reg2`) em `S_ID` (`0`: `Ri` em `ST`/`BEQ`/`BNE`; `1`: `Rk` no Tipo R).],
    [`MemtoReg`], [1], [Dado gravado no banco (`0`: `AluOut`; `1`: `MDR`).],
    [`AluSrcA`], [1], [Entrada A da ULA (`0`: `PC`; `1`: registrador `A`).],
    [`AluSrcB`], [2], [Entrada B da ULA (`00`: `B`; `01`: `0x0001`; `10`: imediato estendido).],
    [`AluOp`], [2], [Modo da ULA (`00`: soma; `01`: subtração; `10`: usa `Funct`).],
    [`PCSrc`], [2], [Fonte do próximo `PC` (`00`: `AluOut`; `01`: saída combinacional da ULA; `10`: endereço de `JMP`).],
    [`AluOutWrite`], [1], [Habilita gravação em `AluOut` e nas flags registradas de exibição (`LEDR`).],
    [`state_out`], [5], [Codificação _one-hot_ do estágio atual exibida em `LEDG(4..0)`.],
  ),
  caption: [Sinais gerados pela Unidade de Controle e seus significados.],
) <tab-sinais>

#figure(
  image("diagrama_fsm.svg", width: 100%),
  caption: [Diagrama de estados da Unidade de Controle (`control_unit.vhd`).],
) <fig-fsm>

#figure(
  table(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") } else if calc.even(y) { luma(248) },
    table.header[*Estado*][*Sinais ativos (demais em `0` / `00`)*][*Próximo Estado*],
    [`S_IF`], [`PCWrite=1`, `MemRead=1`, `IRWrite=1`, `AluSrcB=01`, `PCSrc=01`, `state_out=00001`], [`S_ID`],
    [`S_ID`], [`AluSrcB=10`, `RegDst=1` (Tipo R), `AluOutWrite=1` (`BEQ`/`BNE`), `state_out=00010`], [Conforme `opcode` (padrão `S_IF`)],
    [`S_EX_R`], [`AluSrcA=1`, `AluOp=10`, `AluOutWrite=1`, `state_out=00100`], [`S_WB_R`],
    [`S_EX_ADDI`], [`AluSrcA=1`, `AluSrcB=10`, `AluOutWrite=1`, `state_out=00100`], [`S_WB_R`],
    [`S_WB_R`], [`RegWrite=1`, `MemtoReg=0`, `state_out=10000`], [`S_IF`],
    [`S_EX_MEM`], [`AluSrcA=1`, `AluSrcB=10`, `AluOutWrite=1`, `state_out=00100`], [`S_MEM_RD` (`LD`) / `S_MEM_WR` (`ST`)],
    [`S_MEM_RD`], [`IorD=1`, `MemRead=1`, `state_out=01000`], [`S_WB_LD`],
    [`S_WB_LD`], [`RegWrite=1`, `MemtoReg=1`, `state_out=10000`], [`S_IF`],
    [`S_MEM_WR`], [`IorD=1`, `MemWrite=1`, `state_out=01000`], [`S_IF`],
    [`S_EX_BEQ`], [`PCWriteCond=1`, `AluSrcA=1`, `AluOp=01`, `state_out=00100`], [`S_IF`],
    [`S_EX_BNE`], [`PCWriteCond=1`, `BNE=1`, `AluSrcA=1`, `AluOp=01`, `state_out=00100`], [`S_IF`],
    [`S_EX_JMP`], [`PCWrite=1`, `PCSrc=10`, `state_out=00100`], [`S_IF`],
  ),
  caption: [Tabela de estados, sinais ativos e transições da FSM (`control_unit.vhd`).],
) <tab-fsm>

// ==================== 3. CAMINHO DE DADOS ====================
= Diagrama de Caminho de Dados

Abaixo, na @fig-datapath, está o diagrama do datapath projetado para ser implementado utilizando VHDL.

#figure(
  image("diagrama_datapath.png", width: 100%),
  caption: [Diagrama do caminho de dados (datapath) da CPU multiciclo de 16 bits.],
) <fig-datapath>

Todo o caminho de dados e a memória unificada (`memory_unit.vhd`, inferida em blocos M9K com `ram_init.mif`) compartilham o mesmo domínio de clock síncrono (`CLOCK_50`), enquanto os registradores da CPU e a escrita em memória só avançam na ocorrência do pulso de passo `step_en`. Como a memória é endereçada por palavra de 16 bits, não há blocos de deslocamento por 2 (_Shift Left 2_): o incremento do `PC` usa a constante `0x0001` e a saída direta do *Sign Extend* (`AluSrcB = 10`) atende tanto `ADDI`/`LD`/`ST` quanto o cálculo do endereço de desvio em `S_ID`, dispensando uma quarta entrada útil no multiplexador `AluSrcB`. No ciclo de busca (`S_IF`), o `PC` passa por `IorD` para ler a instrução já disponibilizada pela memória e gravá-la no `IR` (`IRWrite = 1`), enquanto a ULA incrementa o `PC` combinacionalmente via `PCSrc = 01`. Na decodificação (`S_ID`), `RegDst` seleciona a segunda porta de leitura do banco (`Rk` no Tipo R ou `Ri` em `ST`/`BEQ`/`BNE`), os operandos são salvos em `A` e `B`, o imediato (`[5:0]`) passa pelo *Sign Extend* e, no caso de desvios condicionais, `AluOutWrite = 1` salva o endereço alvo `PC + imm` em `AluOut`. Nos ciclos de execução, `AluSrcA`, `AluSrcB` e `AluOp`/`Funct` configuram a ULA para operações aritmético-lógicas, cálculo de endereço de `LD`/`ST` (gravados em `AluOut` via `AluOutWrite = 1`) ou comparação de desvios (usando `Zero` combinacional em `pc.vhd`). Por fim, acessos a dados reutilizam a memória com `IorD = 1` (atualizando o `MDR` exclusivamente em `S_MEM_RD` ou escrevendo a partir de `B` em `S_MEM_WR`), o write-back grava no registrador destino `Ri` selecionando o dado por `MemtoReg`, e os saltos atualizam o `PC` combinando `PCWrite`, `PCWriteCond`, `BNE` e `Zero`.

// ==================== 4. TESTES ====================
= Descrição dos Testes Utilizados

Para validar o caminho de dados, a Unidade de Controle e a interface na placa Altera DE2-115, foi elaborado um programa de teste carregado na memória pelo arquivo `ram_init.mif`. O programa exercita todas as 11 instruções da ISA em um ciclo fechado de 81 passos de clock (KEY(0)), cobrindo:

- Inicialização de registradores via ADDI (R1 = 5, R2 = 3);
- Operações Tipo R (ADD, SUB, AND, OR e SLT verdadeiro e falso);
- Operação imediata positiva e negativa em complemento de dois (ADDI com $+4$ e $-2$);
- Escrita e leitura na memória de dados (ST e LD no endereço 0x18);
- Desvios condicionais tomados, não tomados e com deslocamento negativo (BEQ e BNE), com instruções-armadilha nos endereços 0x0E (ADD R1, R0, R0, 0x0202) e 0x10 (ADD R2, R0, R0, 0x0402) que devem ser puladas;
- Saltos incondicionais (JMP), proteção contra escrita em R0 e retorno automático ao endereço 0x00.

Na placa DE2-115, o teste passo a passo utiliza `CLOCK_50` como clock síncrono global, KEY(1) como reset e KEY(0) como avanço manual de ciclo: aproveitando o filtro Schmitt trigger em hardware dos botões KEY[3:0] da placa, o módulo `datapath_board.vhd` sincroniza os botões em `CLOCK_50` e gera um pulso único de um ciclo (`step_en`) na borda de acionamento de KEY(0). Os displays HEX3..HEX0 exibem o PC, enquanto HEX7..HEX4 exibem AluOut (SW(17)=0, SW(16)=0), IR (SW(17)=0, SW(16)=1) ou MDR (SW(17)=1). Os LEDs verdes LEDG(4..0) indicam o estágio ativo da FSM (`S_IF`, `S_ID`, `S_EX`, `S_MEM` e `S_WB`) e os LEDs vermelhos LEDR(2..0) mostram as flags registradas (Cout, Overflow e Zero) alinhadas a AluOut.

A @tab-seq-esperada apresenta a sequência exata de saídas esperadas ao longo dos 81 cliques de uma volta completa após o reset.

#figure(
  kind: table,
  {
    set text(size: 8.2pt)
    set table(inset: 3.2pt)
    table(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto, 1fr),
      align: (center, center, left, center, center, center, center, center, left),
      fill: (_, y) => if y == 0 { rgb("#e8eaf6") } else if calc.even(y) { luma(248) },
      table.header[*Cliques*][*End.*][*Instrução*][*`IR`*][*`PC`*][*`AluOut` (cl.)*][*`MDR`*][*`LEDR`*][*Efeito esperado*],
      [0], [-], [Reset (`KEY(1)`)], [`0000`], [`0000`], [`0000` (-)], [`0000`], [`000`], [`LEDG(0)=1` (`S_IF`)],
      [1–4], [`00`], [`ADDI R1, R0, 5`], [`5205`], [`0001`], [`0005` (3)], [`0000`], [`000`], [`R1` $<-$ `0005` (cl. 4)],
      [5–8], [`01`], [`ADDI R2, R0, 3`], [`5403`], [`0002`], [`0003` (7)], [`0000`], [`000`], [`R2` $<-$ `0003` (cl. 8)],
      [9–12], [`02`], [`ADD R3, R1, R2`], [`0652`], [`0003`], [`0008` (11)], [`0000`], [`000`], [`R3` $<-$ `0008` (cl. 12)],
      [13–16], [`03`], [`SUB R4, R1, R2`], [`1854`], [`0004`], [`0002` (15)], [`0000`], [`100`], [`R4` $<-$ `0002` (`Cout=1`)],
      [17–20], [`04`], [`AND R5, R1, R2`], [`2A50`], [`0005`], [`0001` (19)], [`0000`], [`000`], [`R5` $<-$ `0001` (cl. 20)],
      [21–24], [`05`], [`OR R6, R1, R2`], [`3C51`], [`0006`], [`0007` (23)], [`0000`], [`000`], [`R6` $<-$ `0007` (cl. 24)],
      [25–28], [`06`], [`SLT R7, R2, R1`], [`4E8E`], [`0007`], [`0001` (27)], [`0000`], [`000`], [`R7` $<-$ `0001` (`3 < 5`)],
      [29–32], [`07`], [`ADDI R3, R3, 4`], [`56C4`], [`0008`], [`000C` (31)], [`0000`], [`000`], [`R3` $<-$ `000C` (12)],
      [33–36], [`08`], [`ST R3, R0, 24`], [`7618`], [`0009`], [`0018` (35)], [`0000`], [`000`], [`Mem[0x18]` $<-$ `000C` (cl. 36)],
      [37–41], [`09`], [`LD R4, R0, 24`], [`6818`], [`000A`], [`0018` (39)], [`000C`], [`000`], [`MDR` $<-$ `000C` (40); `R4` (41)],
      [42–45], [`0A`], [`ADDI R4, R4, -2`], [`593E`], [`000B`], [`000A` (44)], [`000C`], [`100`], [`R4` $<-$ `000A` (`Cout=1`)],
      [46–49], [`0B`], [`SLT R7, R1, R2`], [`4E56`], [`000C`], [`0000` (48)], [`000C`], [`001`], [`R7` $<-$ `0000` (`Zero=1`)],
      [50–52], [`0C`], [`BEQ R3, R4, 2`], [`8702`], [`000D`], [`000F` (51)], [`000C`], [`000`], [Não tomado (`12 != 10`)],
      [53–55], [`0D`], [`BNE R3, R4, 1`], [`9701`], [`000E` $->$ `000F`], [`000F` (54)], [`000C`], [`000`], [Tomado (55): pula `0x0E`],
      [56–58], [`0F`], [`BEQ R3, R3, 1`], [`86C1`], [`0010` $->$ `0011`], [`0011` (57)], [`000C`], [`000`], [Tomado (58): pula `0x10`],
      [59–61], [`11`], [`JMP 0x013`], [`A013`], [`0012` $->$ `0013`], [`0011` (-)], [`000C`], [`000`], [Salta para `0x013` (cl. 61)],
      [62–64], [`13`], [`BEQ R0, R0, -2`], [`803E`], [`0014` $->$ `0012`], [`0012` (63)], [`000C`], [`100`], [Tomado (64): volta a `0x12`],
      [65–67], [`12`], [`JMP 0x014`], [`A014`], [`0013` $->$ `0014`], [`0012` (-)], [`000C`], [`100`], [Salta para `0x014` (cl. 67)],
      [68–70], [`14`], [`BNE R3, R3, 1`], [`96C1`], [`0015`], [`0016` (69)], [`000C`], [`000`], [Não tomado (`12 == 12`)],
      [71–74], [`15`], [`ADD R0, R1, R2`], [`0052`], [`0016`], [`0008` (73)], [`000C`], [`000`], [Escrita em `R0` ignorada],
      [75–78], [`16`], [`ADD R7, R2, R0`], [`0E82`], [`0017`], [`0003` (77)], [`000C`], [`000`], [`R7` $<-$ `0003` (prova `R0=0`)],
      [79–81], [`17`], [`JMP 0x000`], [`A000`], [`0018` $->$ `0000`], [`0003` (-)], [`000C`], [`000`], [Reinicia em `0x0000` (cl. 81)],
    )
  },
  caption: [Sequência esperada de saídas na placa DE2-115 para o programa de teste em `ram_init.mif` (81 cliques; `LEDR` na ordem `Cout`, `Overflow`, `Zero`).],
) <tab-seq-esperada>

A validação em hardware foi realizada na placa Altera DE2-115, com registro em vídeo no YouTube (#link("https://youtu.be/6YyJ1-lgvBU")[https://youtu.be/6YyJ1-lgvBU]) mostrando a execução passo a passo. De forma complementar, o mesmo programa de `ram_init.mif` foi verificado em simulação no ModelSim com o testbench `datapath_tb.vhd`, cujas formas de onda aparecem na seção de Resultados.

// ==================== 5. RESULTADOS ====================
= Resultados e Discussão

A execução prática na placa Altera DE2-115 confirmou todos os 81 ciclos previstos na @tab-seq-esperada. Desde o primeiro passo após o reset (KEY(1)), a inspeção do IR via SW(16) = 1 mostrou a instrução 0x5205 (ADDI R1, R0, 5) buscada do endereço 0x0000, validando a carga do `ram_init.mif` na memória e o sincronismo entre `CLOCK_50` e `step_en`.

As operações aritméticas e lógicas produziram os resultados esperados em AluOut (0005, 0003, 0008, 0002, 0001, 0007, 0001, 000C, 000A e 0000), com as flags nos LEDR(2..0) alinhadas ao valor exibido: Cout = 1 na subtração e nas somas com imediato negativo (0xFFFE), e Zero = 1 no SLT falso do endereço 0x0B. No acesso à memória, o ST gravou 0x000C na posição 0x18 e o LD carregou 0x000C no MDR no clique 40, mantendo o valor estável em HEX7..HEX4 (SW(17) = 1) pelos ciclos seguintes.

Os desvios e saltos também funcionaram conforme projetado: BEQ não tomado (0x0C) e BNE não tomado (0x14) seguiram o fluxo sequencial, enquanto BNE (0x0D) e BEQ (0x0F) pularam as instruções-armadilha em 0x0E e 0x10, e o BEQ com deslocamento negativo (0x13) retornou a 0x12. No final, a escrita em R0 (0x15) foi ignorada (comprovado pelo resultado 0003 em ADD R7, R2, R0 em 0x16) e o JMP 0x000 (0x17) reiniciou o ciclo em 0x0000 no 81º clique.

== Validação em Simulação (ModelSim)

Além dos testes na placa, o testbench `datapath_tb.vhd` foi executado no ModelSim com o conteúdo de `ram_init.mif` carregado na memória e pulsos unitários em `step_en`, completando os 81 passos sem erros de assert e reproduzindo os mesmos resultados da DE2-115. A @fig-sim-parte1 mostra a primeira metade da simulação (cliques 0 a 41), com a inicialização de R1 e R2, as instruções Tipo R, ADDI, ST (0x0018) e a captura de 0x000C em `mdr_out` no LD (0x6818), além de cout = 1 na subtração (0x1854) e da sequência de estados em `state_out`.

#figure(
  image("Screenshot From 2026-11-26 10-47-08.png", width: 100%),
  caption: [Formas de onda no ModelSim (Parte 1, cliques 0 a 41): inicialização, operações Tipo R, ADDI, ST e LD (`mdr_out` = 000C).],
) <fig-sim-parte1>

A @fig-sim-parte2 mostra a segunda metade (cliques 40 a 81), confirmando ADDI negativo (0x593E, AluOut = 000A, cout = 1), SLT falso (0x4E56, AluOut = 0000, zero = 1), desvios condicionais tomados e não tomados (0x000E $->$ 0x000F e 0x0010 $->$ 0x0011, pulando as armadilhas), o salto condicional reverso (0x803E, 0x0014 $->$ 0x0012 com cout = 1), a manutenção de R0 = 0 (AluOut = 0003 em 0x0E82) e o retorno ao endereço 0x0000 no 81º clique (A000, `state_out` = 00001).

#figure(
  image("Screenshot From 2026-11-26 10-47-24.png", width: 100%),
  caption: [Formas de onda no ModelSim (Parte 2, cliques 40 a 81): ADDI negativo, SLT falso, desvios BEQ/BNE/JMP, proteção de R0 e retorno a PC = 0000.],
) <fig-sim-parte2>

// ==================== 6. DIFICULDADES ====================
= Dificuldades Encontradas

As principais dificuldades enfrentadas pelo grupo concentraram-se em duas frentes: a elaboração correta do arquivo de inicialização da memória (`ram_init.mif`) e a portabilidade do projeto para a placa Altera DE2-115.

Na montagem do `ram_init.mif`, foi necessário manter a codificação binária de 16 bits coerente com a arquitetura sintetizada. Como os bits [2:0] das instruções Tipo R (que no enunciado eram não usados) funcionam na nossa implementação como campo Funct da ULA, foi preciso revisar manualmente para que ADD, SUB, AND, OR e SLT acionassem os códigos corretos em `ula.vhd`, além de conferir imediatos negativos em complemento de dois e os offsets de desvio considerando o incremento prévio do PC em `S_IF`.

Na portabilidade para a placa DE2-115, surgiram comportamentos incorretos nos displays que não apareciam olhando os módulos isolados:

- *Clock manual e leitura da memória no reset:* inicialmente o clock da CPU vinha direto de KEY(0) e a memória usava clock invertido (`s_mem_clk <= not clk`). Na placa, ao acionar o reset em KEY(1) sem pulsar KEY(0) junto, a memória não pré-carregava o endereço 0x0000, fazendo a primeira instrução ser perdida e dividindo a atualização entre o aperto e a soltura do botão. O problema foi resolvido unificando o sistema no clock global `CLOCK_50`, com sincronização dos botões e pulso único (`step_en`) na borda de acionamento de KEY(0).
- *Instabilidade em HEX7..HEX4 e defasagem nos LEDR:* como MDR e AluOut originalmente não tinham habilitação de escrita, o display do MDR era sobrescrito pelo código das instruções em `S_IF` e AluOut exibia somas intermediárias (PC + B) ao voltar para `S_IF`, além de LEDR(2..0) ficarem um ciclo adiantados em relação a AluOut. A inclusão de enables condicionados (`MemRead and IorD and step_en` no MDR e `AluOutWrite and step_en` em AluOut), o registro das flags junto com AluOut e o modo de depuração do IR em SW(16) resolveram esses problemas.

// ==================== 7. USO DE IA ====================
= Uso de IA

Ferramentas de Inteligência Artificial foram utilizadas ao longo do projeto como suporte de verificação e revisão, com foco em garantir a integridade da entrega frente aos requisitos da disciplina e a consistência técnica do relatório. Em especial, a IA auxiliou na análise estática dos arquivos VHDL para diagnosticar a causa dos valores incorretos exibidos na placa DE2-115, na conferência da sequência esperada a partir do `ram_init.mif` e na revisão do documento. De qualquer forma, todas as alterações foram feitas por humanos, com a IA sendo utilizada somente como uma ferramenta auxiliar.