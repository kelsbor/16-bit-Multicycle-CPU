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

// Bloco para seções que ainda serão preenchidas pelo grupo
#let pendente(titulo, body) = block(
  width: 100%,
  fill: rgb("#fff8e1"),
  stroke: (left: 3pt + rgb("#f57c00"), rest: 0.5pt + rgb("#ffe0b2")),
  inset: 9pt,
  radius: 3pt,
  breakable: true,
)[
  #text(weight: "bold", fill: rgb("#e65100"))[Pendente - #titulo]
  #v(0.25em)
  #set par(first-line-indent: 0pt)
  #body
]

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
      // TODO: adicionar 4º integrante com RA, se aplicável
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

A topologia adotada segue o modelo MIPS multiciclo com arquitetura de von Neumann, usando uma única memória para instruções e dados e uma única ULA de 16 bits compartilhada entre incremento do `PC`, cálculo de endereços e operações lógico-aritméticas. Dividindo a execução em etapas de um ciclo (busca, decodificação, execução, memória e escrita), cada instrução leva entre 3 e 5 ciclos (3 para saltos, 4 para Tipo R, `ADDI` e `ST`, e 5 para `LD`), com registradores intermediários guardando os dados entre ciclos e uma máquina de estados (FSM) coordenando os sinais de controle. O projeto em VHDL foi modularizado em `pc`, `memory_unit`, `register_bank`, `ula`, `control_unit`, `datapath` e nos módulos de interface da placa (`datapath_board` e `display_logic`).

// ==================== 2. ESPECIFICAÇÃO ====================
= Especificação

== Registradores

A CPU trabalha com palavra de 16 bits. Os campos de registrador nas instruções (`Ri`, `Rj`, `Rk`) têm 3 bits, endereçando $2^3 = 8$ registradores de propósito geral (`R0` a `R7`), com duas portas de leitura assíncronas e uma de escrita síncrona (`RegWrite`). Além do banco, o multiciclo usa registradores internos de 16 bits para manter os valores entre ciclos, conforme agrupado na @tab-regs. Vale destacar que o *Memory Data Reg* (`MDR`/`RDM`) não possui controle de escrita, gravando diretamente o que chega da memória a cada ciclo, assim como `A`, `B` e `AluOut`.

#figure(
  table(
    columns: (auto, auto, auto, auto, 1fr),
    align: (left, center, center, center, left),
    fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
    table.header[*Registrador*][*Qtd.*][*Endereço*][*Tam.*][*Função / Controle*],
    [`R0` a `R7`], [8], [`000`–`111`], [16 b], [Banco de propósito geral (`RegWrite`; `R0` fixo em `0` se seguida a convenção MIPS).],
    [`PC`], [1], [-], [16 b], [Endereço da instrução atual/próxima (`PCWrite` / `PCWriteCond`).],
    [`IR`], [1], [-], [16 b], [Retém a instrução buscada durante toda a execução (`IRWrite`).],
    [`MDR` (`RDM`)], [1], [-], [16 b], [Guarda o dado lido da memória (sem sinal de controle).],
    [`A`, `B`], [2], [-], [16 b], [Armazenam os operandos lidos do banco após a decodificação (sem controle).],
    [`AluOut`], [1], [-], [16 b], [Salva a saída da ULA para o ciclo seguinte (sem controle).],
  ),
  caption: [Especificação do banco de registradores e registradores internos da CPU.],
) <tab-regs>

== Formato das Instruções

As instruções possuem 16 bits (`[15:0]`), sempre com o `Opcode` nos 4 bits mais significativos (`[15:12]`), distribuídas nos três formatos da @tab-formatos. No Tipo R, os 3 bits menos significativos (`[2:0]`) - marcados como não usados no enunciado - foram aproveitados como campo `Funct` para definir a operação da ULA, como no MIPS de 32 bits. No Tipo I, o imediato de 6 bits em complemento de dois ($-32$ a $+31$) passa por um *Sign Extend* para 16 bits.

#figure(
  kind: table,
  stack(
    spacing: 0.65em,
    table(
      columns: (1.1fr, 1.1fr, 0.9fr, 0.9fr, 0.9fr, 1.3fr),
      align: center,
      fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
      [*Formato*], [*`[15:12]`*], [*`[11:9]`*], [*`[8:6]`*], [*`[5:3]`*], [*`[2:0]`*],
      [*Tipo R*], [`Opcode` (4b)], [`Ri` (3b)], [`Rj` (3b)], [`Rk` (3b)], [`Funct` (3b)],
    ),
    table(
      columns: (1.1fr, 1.1fr, 0.9fr, 0.9fr, 2.2fr),
      align: center,
      fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
      [*Tipo I*], [`Opcode` (4b)], [`Ri` (3b)], [`Rj` (3b)], [`Imediato` (6b, sinalizado)],
    ),
    table(
      columns: (1.1fr, 1.1fr, 4.0fr),
      align: center,
      fill: (_, y) => if y == 0 { rgb("#e8eaf6") },
      [*Tipo J*], [`Opcode` (4b)], [`end` (12b, endereço de destino)],
    ),
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

A Unidade de Controle (`control_unit.vhd`) é uma FSM de 12 estados com reset assíncrono para `S_IF` e transições na borda de subida do clock conforme o `Opcode` da instrução (opcodes inválidos retornam para `S_IF`). A @tab-sinais lista os 14 sinais de saída, a @fig-fsm mostra o diagrama de estados e a @tab-fsm resume os sinais ativos e transições de cada estado.

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
    [`MemRead` / `MemWrite`], [1 / 1], [Habilitam leitura e escrita na memória unificada.],
    [`IRWrite`], [1], [Grava a palavra lida da memória no `IR`.],
    [`RegWrite`], [1], [Habilita escrita no banco de registradores.],
    [`RegDst`], [1], [Seleciona o campo de registrador destino na escrita no banco.],
    [`MemtoReg`], [1], [Dado gravado no banco (`0`: `AluOut`; `1`: `MDR`).],
    [`AluSrcA`], [1], [Entrada A da ULA (`0`: `PC`; `1`: registrador `A`).],
    [`AluSrcB`], [2], [Entrada B da ULA (`00`: `B`; `01`: passo do `PC`; `10`: imediato; `11`: deslocamento de salto).],
    [`AluOp`], [2], [Modo da ULA (`00`: soma; `01`: subtração; `10`: usa `Funct`).],
    [`PCSrc`], [2], [Fonte do próximo `PC` (`00`: `AluOut`; `01`: saída da ULA; `10`: endereço de `JMP`).],
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
    [`S_IF`], [`PCWrite=1`, `MemRead=1`, `IRWrite=1`, `AluSrcB=01`, `PCSrc=01`], [`S_ID`],
    [`S_ID`], [`AluSrcB=11`], [Conforme `opcode` (padrão `S_IF`)],
    [`S_EX_R`], [`AluSrcA=1`, `AluOp=10`], [`S_WB_R`],
    [`S_EX_ADDI`], [`AluSrcA=1`, `AluSrcB=10`, `PCSrc=01`], [`S_WB_R`],
    [`S_WB_R`], [`RegWrite=1`, `RegDst=0` (`ADDI`) ou `1` (Tipo R)], [`S_IF`],
    [`S_EX_MEM`], [`AluSrcA=1`, `AluSrcB=10`, `PCSrc=01`], [`S_MEM_RD` (`LD`) / `S_MEM_WR` (`ST`)],
    [`S_MEM_RD`], [`IorD=1`, `MemRead=1`], [`S_WB_LD`],
    [`S_WB_LD`], [`RegWrite=1`, `MemtoReg=1`], [`S_IF`],
    [`S_MEM_WR`], [`IorD=1`, `MemWrite=1`], [`S_IF`],
    [`S_EX_BEQ`], [`PCWriteCond=1`, `AluSrcA=1`, `AluOp=01`], [`S_IF`],
    [`S_EX_BNE`], [`PCWriteCond=1`, `BNE=1`, `AluSrcA=1`, `AluOp=01`], [`S_IF`],
    [`S_EX_JMP`], [`PCWrite=1`, `AluSrcA=1`, `AluSrcB=11`, `PCSrc=10`], [`S_IF`],
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

No ciclo de busca (`S_IF`), o `PC` passa por `IorD` para ler a instrução na memória e gravá-la no `IR` (`IRWrite = 1`), enquanto a ULA já incrementa o `PC` via `PCSrc`. Na decodificação (`S_ID`), os registradores lidos do banco são salvos em `A` e `B` e o imediato (`[5:0]`) passa pelo *Sign Extend*. Nos ciclos seguintes, `AluSrcA`, `AluSrcB` e `ALU Control` configuram a ULA para operações aritmético-lógicas, cálculo de endereço de `LD`/`ST` ou comparação de saltos, salvando a saída em `AluOut`. Por fim, acessos a dados reutilizam a memória com `IorD = 1` (lendo em `MDR` ou escrevendo a partir de `B`), o write-back grava no banco escolhendo destino e dado via `RegDst` e `MemtoReg`, e os desvios atualizam o `PC` combinando `PCWrite`, `PCWriteCond`, `BNE` e `Zero`.

// ==================== 4. TESTES (PESSOAL) ====================
= Descrição dos Testes Utilizados

#pendente("Simulação, .mif e validação na DE2-115")[]

// ==================== 5. RESULTADOS (PESSOAL) ====================
= Resultados e Discussão

#pendente("Resultados obtidos e análise")[]

// ==================== 6. DIFICULDADES (PESSOAL) ====================
= Dificuldades Encontradas

#pendente("Problemas e soluções durante o projeto")[]

// ==================== 7. USO DE IA (PESSOAL) ====================
= Uso de IA

#pendente("Partes desenvolvidas com IA e motivo")[]
