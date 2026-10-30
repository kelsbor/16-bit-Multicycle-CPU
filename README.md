# 16-bit Multicycle CPU in VHDL

Design and implementation of a simple multicycle CPU in VHDL with support for a reduced instruction set (RISC-like), developed for synthesis and testing on an FPGA board.

---

## 📌 Overview

- **Data Word:** 16 bits
- **Registers:** 16 bits each (addressed via 3 bits)
- **Architecture:** Multicycle datapath with Control Unit based on a Finite State Machine (FSM)
- **Target:** FPGA with memory initialization via `.mif` file

---

## 📑 Instruction Set Architecture (ISA)

| Instruction | Format | Operation | Description |
| :--- | :---: | :--- | :--- |
| `ADD Ri, Rj, Rk` | R-Type | Ri <- Rj + Rk | Addition between registers |
| `SUB Ri, Rj, Rk` | R-Type | Ri <- Rj - Rk | Subtraction between registers |
| `AND Ri, Rj, Rk` | R-Type | Ri <- Rj && Rk | Bitwise AND operation |
| `OR Ri, Rj, Rk`  | R-Type | Ri <- Rj \|\| Rk | Bitwise OR operation |
| `SLT Ri, Rj, Rk` | R-Type | Ri <- 1 if Rj < Rk else 0 | Set on less than |
| `ADDI Ri, Rj, imm` | I-Type | Ri <- Rj + immediate | Addition with immediate value |
| `LD Ri, Rj, imm`   | I-Type | Ri <- Memory[Rj + immediate] | Memory read (Load) |
| `ST Ri, Rj, imm`   | I-Type | Memory[Rj + immediate] <- Ri | Memory write (Store) |
| `BEQ Ri, Rj, imm`  | I-Type | If Ri == Rj, PC <- PC + immediate | Branch on equal |
| `BNE Ri, Rj, imm`  | I-Type | If Ri != Rj, PC <- PC + immediate | Branch on not equal |
| `JMP end`         | J-Type | PC <- address | Unconditional jump |

---

## 🔤 Instruction Formats

### R-Type (Register Operations)
| Opcode (4 bits) | Ri (3 bits) | Rj (3 bits) | Rk (3 bits) | Unused (3 bits) |
| :---: | :---: | :---: | :---: | :---: |

### I-Type (Immediate/Memory/Branch Operations)
| Opcode (4 bits) | Ri (3 bits) | Rj (3 bits) | Immediate (6 bits) |
| :---: | :---: | :---: | :---: |

### J-Type (Unconditional Jump)
| Opcode (4 bits) | Address (12 bits) |
| :---: | :---: |

---

## 🎛️ FPGA Interface

| FPGA Component | Function in Project |
| :--- | :--- |
| **Push Button** | Manual clock control (with Debouncer circuit) |
| **Displays HEX0 – HEX3** | Displays current Program Counter (**PC**) value |
| **Displays HEX4 – HEX7** | Multiplexed display between **MDR** (Memory Data Register) and **ALU Output** |
| **Switch SW17** | Controls the HEX4–7 display multiplexer (`0`: MDR \| `1`: ALU) |
| **Green LEDs (LEDG)** | Indicates current Control Unit state (Fetch, Decode, Execute, etc.) |

---

## 📁 Repository Structure

```text
.
├── src/            # VHDL source files (.vhd)
│   ├── datapath/   # Registers, ALU and MUXes
│   └── control/    # Control Unit (FSM)
├── memory/         # Memory initialization files (.mif)
└── docs/           # Technical specification document and reports (.pdf)
