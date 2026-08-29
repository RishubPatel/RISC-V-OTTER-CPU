# RISC-V OTTER CPU — RTL Design and FPGA Implementation

This is a 32-bit multicycle RISC-V OTTER CPU implemented in Verilog/SystemVerilog, verified with Vivado simulations, and deployed to a Digilent Basys 3 FPGA board. The completed processor executes RISC-V assembly firmware and supports arithmetic/logic operations, loads and stores, branches and jumps, CSR-based interrupt handling, and timer-counter-based interrupts.

**Technologies:** Verilog/SystemVerilog · RISC-V Assembly · RARS-OTTER · AMD Vivado · Digilent Basys 3 FPGA

> **[INSERT SHORT VIDEO/GIF OF THE FINAL PROCESSOR RUNNING ON THE BASYS 3]**

*Figure 1: Final OTTER demonstration video: The video shows the completed OTTER CPU executing custom RISC-V assembly firmware on a Basys 3. The program reads buttons and switches, controls LEDs, maintains a two-digit count, and uses timer-generated interrupts to multiplex the seven-segment display.*

---

## Project Overview

This GitHub repository documents my implementation of thRISC-V OTTER CPU architecture** used in Cal Poly's CPE 233: Computer Design and Assembly Language Programming from Winter 2026 as taught by Professor James Mealy. The overall processor architecture was provided by the course. Across a sequence of projects, I implemented and tested major datapath components, completed and extended the processor's control logic from starter templates, integrated the complete multicycle CPU, and later added the required hardware support for interrupts and a timer-counter peripheral.

The processor uses a 32-bit multicycle architecture based primarily on the RV32I base integer instruction set, with additional system/CSR instructions used by the OTTER interrupt architecture. Most instructions execute using a fetch cycle followed by an execute cycle, while load instructions require an additional writeback cycle.

The completed implementation supports arithmetic and logical operations, shifts and comparisons, byte/halfword/word loads and stores, conditional branches, `jal`/`jalr`, upper-immediate operations, CSR access, interrupt entry, and return from an interrupt with `mret`.

I verified the design progressively in Vivado using simulation-generated timing diagram waveforms and by synthesizing and implementing the CPU on a Basys 3 FPGA to execute various assembly programs. RISC-V assembly firmware running on the processor interacts with the board through the course-provided memory-mapped I/O interface.

---

## My Contributions

The project combines RTL that I designed, course starter templates that I completed or extended, and prebuilt modules supplied as infrastructure.

| Area | Starting Point | My Work |
| --- | --- | --- |
| OTTER architecture | High-level circuit diagram (see figure **INSERT FIGURE NUMBER**) | Implemented and progressively integrated the architecture in Verilog/SystemVerilog |
| Program Counter | Functional requirements | Designed and implemented the PC and next-PC logic |
| ALU | Functional requirements | Designed and implemented the 32-bit ALU based on operation descriptions in the assembler manual|
| Immediate Generator | Functional requirements | Implemented extraction and extension of RISC-V immediate formats based on their descriptions in the assembler manual|
| Branch Address Generator | Functional requirements | Implemented branch, `jal`, and `jalr` target generation based on relevant descriptions in the assembler manual|
| Branch Condition Generator | Functional requirements | Implemented equality and signed/unsigned comparison logic for conditional branches |
| Control Units FSM / Decoder | Barebones course starter templates | Completed and extended control logic for the supported instruction set and interrupt behavior |
| Register File / Memory | Course-provided modules | Integrated into the processor datapath |
| CSR Module | Course-provided module | Integrated with the CPU and modified the surrounding datapath/control logic to support interrupts |
| Timer-Counter | Course-provided peripheral | Integrated with the FPGA system on the wrapper level and used as an interrupt source |
| Basys 3 MMIO Wrapper | Course starter template | Completed and modified memory mappings to buttons, switches, LEDs, and 7-segment display and implemented connections to the CPU and timer-counter|
| Firmware | Assignment specifications | Designed and coded assembly test programs and final demonstration firmware |
| Verification | — | Simulated individual modules and the complete CPU in Vivado and validated the completed design on the Basys 3 (see Figure 1)|

*Figure 2: Table detailing my contributions the project as opposed to what was course-provided*

---

## Architecture Overview

### CPU Architecture

> **[INSERT THE INTERRUPT-ENABLED OTTER ARCHITECTURE DIAGRAM HERE]**

> **[If using or adapting the textbook diagram, add appropriate attribution to James Mealy, _FreeRange Computer Design: The RISC-V OTTER MCU_, v14.02.]**

The processor consists of a datapath controlled by two control units:

- **Program Counter (PC):** stores the address of the current instruction and selects the next address
- **MEMORY:** stores program instructions and data and connects the CPU to memory-mapped I/O
- **Register File (REG_FILE):** contains 32 32-bit registers and provides two source operands and one destination write port
- **Immediate Generator (IMMED_GEN):** extracts and extends immediate fields from the current instruction
- **Branch Address Generator (BRANCH_ADDR_GEN):** calculates branch, `jal`, and `jalr` targets
- **Branch Condition Generator (BRANCH_COND_GEN):** compares register operands for conditional branches
- **Arithmetic Logic Unit (ALU):** performs arithmetic, logical, shift, comparison, and address calculations
- **Control Unit FSM (CU_FSM):** sequences the CPU through instruction-execution cycles and generates control signals based on both the current state and instruction
- **Control Unit Decoder (CU_DCDR):** generates control signals based on only the current instruction
- **Control and Status Register module (CSR):** stores interrupt-related CSRs and updates saved PC and interrupt-enable state during interrupt entry and return

### Multicycle Execution

The OTTER uses a multicycle execution model.

Most instructions use two primary cycles:

1. **Fetch** — the PC provides the instruction address and the CPU reads the next instruction from memory.
2. **Execute** — the processor decodes the instruction and performs the required datapath operation.

Most arithmetic, logical, branch, jump, and store instructions complete after execute.

Load instructions require a third **writeback** cycle. The execute cycle calculates the memory address and initiates the read; the following cycle writes the returned data into the destination register.

The interrupt-enabled implementation also contains an **interrupt cycle** used to save the return state and redirect execution to the interrupt service routine.

### Program Counter Sources

The next value loaded into the PC depends on the current instruction and processor state.

Possible sources include:

- `PC + 4` for normal sequential execution
- Conditional branch target
- `jal` target
- `jalr` target
- `mtvec` when entering an interrupt service routine
- `mepc` when returning from an interrupt

The branch and jump targets are generated from the current PC, register operands, and immediate fields encoded in the instruction.

### Control

Processor control is divided between `CU_FSM` and `CU_DCDR`.

`CU_FSM` is **state-based**. It sequences the CPU through fetch, execute, writeback, and interrupt behavior and produces signals controlling when stateful components may change, including the PC, register file, memory, and CSR module.

`CU_DCDR` is **instruction-based combinational logic**. It decodes the opcode and function fields of the current instruction, along with relevant branch and interrupt conditions, to select:

- ALU operation
- ALU source operands
- next-PC source
- register-file writeback source

Together, the two units determine both **what operation the datapath performs** and **when processor state is updated**.

### Memory and I/O Architecture

The OTTER uses a **32-bit unified address space**. Program code, data, stack, and memory-mapped I/O occupy regions of the same address space.

The course implementation provides 64 KiB of physical memory for code, data, and stack, while peripheral devices occupy a separate memory-mapped I/O region.

Because I/O is memory-mapped, software can communicate with peripherals using the same load and store instructions used for normal memory accesses.

### FPGA System Integration

> **[INSERT WRAPPER-LEVEL DIAGRAM SHOWING CPU, TIMER-COUNTER, INTERRUPT CONNECTION, MMIO WRAPPER, BUTTONS/SWITCHES, LEDS, AND SEVEN-SEGMENT DISPLAY]**

The CPU interfaces with the Basys 3 through a course-provided memory-mapped I/O wrapper.

The wrapper exposes:

- switches and buttons as CPU-readable inputs
- LEDs as processor-controlled outputs
- seven-segment cathode and anode controls
- timer-counter configuration and count registers

The timer-counter can generate an interrupt connected to the CPU's interrupt input, allowing firmware to schedule periodic work without continuously polling the timer or using a blocking delay.

---

## Implementation Details

### Program Counter and Control Flow

The program counter stores the address of the instruction currently being executed and loads its next value through a multiplexer.

During normal sequential execution:

```text
PC_next = PC + 4
```

Control-flow instructions can redirect execution instead.

The branch-address logic calculates:

```text
branch = PC + B-immediate
jal    = PC + J-immediate
jalr   = rs1 + I-immediate
```

The branch-condition logic independently evaluates:

- equality
- signed less-than
- unsigned less-than

The control decoder combines these results with the current branch instruction to determine whether the PC should be redirected.

### Immediate Generation

RISC-V distributes immediate bits differently across its instruction formats. The immediate generator reconstructs the immediate value required by each instruction and extends it to 32 bits.

The implementation handles the immediate formats required for:

- I-type instructions
- S-type instructions
- B-type instructions
- U-type instructions
- J-type instructions

> **[OPTIONAL: INSERT A COMPACT IMMEDIATE-FORMAT DIAGRAM HERE]**

These values are used for arithmetic-immediate operations, memory addressing, branches, jumps, and upper-immediate instructions.

### Arithmetic Logic Unit

The 32-bit ALU implements the operations required by the supported instruction set, including:

- addition and subtraction
- bitwise AND, OR, and XOR
- logical left/right shifts
- arithmetic right shift
- signed comparison
- unsigned comparison

The ALU inputs are selected by multiplexers controlled by `CU_DCDR`, allowing operations to use different combinations of register values, immediate values, PC-related values, and CSR data.

### Register File and Writeback

The course-provided register file contains **32 32-bit architectural registers**.

Two registers can be read as instruction operands (`rs1` and `rs2`), while instruction results can be written into destination register `rd`.

Depending on the instruction, the register-file writeback path can select data from sources including:

- ALU result
- data returned from memory
- `PC + 4`
- CSR read data

Register `x0` is architecturally fixed to zero. The remaining registers can also be referenced by standard RISC-V ABI names such as `ra`, `sp`, `t0`, `s0`, and `a0`.

### Memory Access

Instruction fetches use the PC as the program-memory address.

Loads and stores calculate their effective address using:

```text
effective_address = rs1 + sign-extended immediate
```

The implementation supports byte, halfword, and word memory operations, including signed and unsigned loads:

- `lb`
- `lbu`
- `lh`
- `lhu`
- `lw`
- `sb`
- `sh`
- `sw`

The same memory-access mechanism also allows software to communicate with memory-mapped peripherals.

---

## Control Logic

### FSM

> **[INSERT FSM STATE DIAGRAM HERE]**

The processor control system consists of `CU_FSM` and `CU_DCDR`. Both began from course-provided starter templates that I completed and later extended.

The interrupt-enabled FSM contains the major states:

- **Initialization**
- **Fetch**
- **Execute**
- **Writeback**
- **Interrupt**

During **fetch**, instruction-memory access is enabled.

The processor then enters **execute**, where most instructions complete. Arithmetic, logical, store, branch, and jump instructions normally return directly to fetch afterward.

Loads transition to **writeback**, where the value returned from memory can be written into the destination register.

When an enabled interrupt is detected at the appropriate point in execution, the FSM enters the **interrupt** state rather than immediately fetching the next instruction.

### Decoder

`CU_DCDR` interprets the instruction opcode and function fields and generates the selection signals that configure the datapath.

Depending on the instruction, it determines:

- ALU function
- ALU source A
- ALU source B
- register-file writeback source
- next-PC source

For conditional branches, it also uses the comparison results generated by `BRANCH_COND_GEN`.

Adding interrupt support required extending both control units and expanding several datapath-selection paths.

---

## Supported Instructions

The processor implements the hardware operations required by the OTTER's RV32I-based instruction set.

### Arithmetic and Logic

`add` · `addi` · `sub` · `and` · `andi` · `or` · `ori` · `xor` · `xori`

### Shifts and Comparisons

`sll` · `slli` · `srl` · `srli` · `sra` · `srai` · `slt` · `slti` · `sltu` · `sltiu`

### Loads and Stores

`lb` · `lbu` · `lh` · `lhu` · `lw` · `sb` · `sh` · `sw`

### Branches and Jumps

`beq` · `bne` · `blt` · `bltu` · `bge` · `bgeu` · `jal` · `jalr`

### Upper-Immediate Operations

`lui` · `auipc`

### CSR and System Instructions

`csrrw` · `csrrs` · `csrrc` · `mret`

The assembler also supports pseudoinstructions such as `li`, `la`, `mv`, `j`, `ret`, and `csrw`. These are assembler conveniences that expand into one or more underlying machine instructions rather than requiring separate hardware implementations.

---

## Interrupt Support

The interrupt-enabled OTTER uses a **course-provided CSR module** together with modifications to the processor datapath and control system.

The primary interrupt-related CSRs are:

- **`mstatus`** — stores interrupt enable/state information
- **`mtvec`** — stores the interrupt service routine address
- **`mepc`** — stores the PC value used to resume execution after the ISR

The processor supports the CSR/system instructions:

- `csrrw`
- `csrrs`
- `csrrc`
- `mret`

Adding interrupts required more than instantiating the CSR module. I extended the FSM and decoder, expanded the PC-selection path to include `mtvec` and `mepc`, expanded the ALU operand-selection paths for CSR operations, and added the required interrupt-control connections.

### Interrupt Flow

At a high level:

1. Firmware writes the ISR address to `mtvec`.
2. Firmware enables interrupts through `mstatus`.
3. An interrupt request reaches the CPU.
4. The processor completes the current instruction.
5. The FSM enters the interrupt state.
6. The return address is saved in `mepc`.
7. The PC is redirected to the address stored in `mtvec`.
8. The interrupt service routine executes.
9. `mret` returns execution through the address stored in `mepc`.

---

## Timer-Counter Integration

The final system incorporates a **course-provided timer-counter peripheral** as an interrupt source.

Firmware accesses the peripheral through the memory-mapped I/O interface and configures its control and count registers.

Once enabled, the timer counts clock events and generates an interrupt when the programmed count is reached.

For the final demonstration, I configured the timer to generate interrupts at approximately **200 Hz** with no additional prescaling. With the clock configuration used in the project, this corresponded to a timer count of **249,999**.

These periodic interrupts drive the seven-segment display multiplexing routine.

---

## Basys 3 Firmware Demo

> **[INSERT FULL DEMONSTRATION VIDEO OR CLICKABLE VIDEO THUMBNAIL HERE]**

> **[OPTIONAL: INSERT A CLEAN FLOWCHART OF THE DEMONSTRATION FIRMWARE HERE]**

The final demonstration program combines foreground polling, memory-mapped I/O, software debouncing, and timer-generated interrupts.

### Foreground Behavior

The main program:

1. Polls the pushbutton until a press is detected.
2. Debounces the button in software.
3. Reads the switch corresponding to the currently illuminated LED.
4. Increments a two-digit count if that switch is on.
5. Rolls the count from `99` back to `00`.
6. Moves the active LED one position to the right.
7. Wraps the active LED back to the leftmost position after the final LED.
8. Waits for and debounces the button release before accepting another press.

The active LED therefore indicates which switch will be evaluated on the next valid button press.

### Timer-Driven ISR

The two rightmost seven-segment digits display the current count.

Instead of using a blocking delay loop to multiplex the display, the timer-counter periodically interrupts the CPU.

The ISR:

1. Determines which digit should currently be active.
2. Selects the corresponding decimal value.
3. Looks up the required seven-segment pattern.
4. Writes the segment and anode outputs.
5. Alternates to the other digit for the next interrupt.
6. Returns to the foreground program using `mret`.

This separates the application into two execution paths:

- **Foreground code:** button polling/debouncing, switch input, count updates, and LED movement
- **Interrupt service routine:** periodic display multiplexing

> **[OPTIONAL: INSERT A SHORT ASSEMBLY EXCERPT SHOWING TIMER/INTERRUPT INITIALIZATION OR THE ISR]**

---

## Verification and FPGA Results

I developed and verified the processor progressively, beginning with individual datapath modules and then testing the integrated CPU.

### Module-Level Simulation

Vivado simulation was used to verify core modules including:

- PC reset, hold, sequential advancement, and redirected next-PC behavior
- ALU arithmetic, logic, shift, and comparison operations
- immediate extraction
- branch and jump target generation
- branch-condition comparisons

> **[INSERT ONE CLEAN MODULE-LEVEL WAVEFORM — PC OR ALU RECOMMENDED]**

***[WRITE A ONE-SENTENCE CAPTION EXPLAINING EXACTLY WHAT THE WAVEFORM VERIFIES.]***

### Integrated Processor Testing

After integrating the datapath and control system, I used RISC-V assembly test programs and processor-level simulations to verify instruction execution.

Testing exercised:

- arithmetic and logical instructions
- register-file writeback
- byte/halfword/word loads and stores
- conditional branches
- `jal` / `jalr`
- CSR instructions
- interrupt entry
- interrupt return through `mret`

Interrupt simulations tracked processor and CSR state to verify that execution was redirected correctly and returned to the expected program address.

> **[INSERT INTEGRATED CPU OR INTERRUPT WAVEFORM HERE]**

***[WRITE A CAPTION EXPLAINING THE INSTRUCTION OR INTERRUPT SEQUENCE SHOWN.]***

### Physical FPGA Validation

After simulation, I synthesized and implemented the completed processor in Vivado and programmed the bitstream onto a **Digilent Basys 3 FPGA**.

The physical implementation successfully:

- executed custom RISC-V assembly firmware
- read board buttons and switches
- controlled LEDs
- drove the seven-segment display
- generated timer interrupts
- entered and returned from the timer ISR

The demonstration therefore validates the complete system:

**Processor RTL → Control Logic → Firmware → Interrupts → Memory-Mapped I/O → Physical FPGA Peripherals**

> **[OPTIONAL: INSERT PHOTO OF THE BASYS 3 RUNNING THE FINAL DESIGN]**

---

## Repository Contents

> **[UPDATE THIS TREE TO MATCH THE FINAL REPOSITORY.]**

```text
.
├── README.md
├── rtl/
│   ├── cpu/
│   ├── control/
│   └── peripherals/
├── firmware/
│   ├── tests/
│   └── demo/
├── simulation/
│   ├── testbenches/
│   └── memory_files/
├── constraints/
├── vivado/
│   └── [PROJECT_NAME].xpr
└── media/
    ├── diagrams/
    ├── waveforms/
    └── demos/
```

- **`rtl/`** — Verilog/SystemVerilog processor and supporting hardware
- **`firmware/`** — RISC-V assembly test programs and demonstration firmware
- **`simulation/`** — testbenches and memory files used during verification
- **`constraints/`** — Basys 3 FPGA constraints
- **`vivado/`** — Vivado project files required to open the design
- **`media/`** — diagrams, waveforms, photos, and demonstration media used in this README

Generated Vivado caches, synthesis/implementation output, logs, and other reproducible build artifacts are excluded from source control.

---

## Acknowledgments

This project was completed as part of **CPE 233: Computer Design and Assembly Language Programming** at **California Polytechnic State University, San Luis Obispo**.

The RISC-V OTTER architecture and multiple supporting modules and starter templates were provided through the course. Course-provided infrastructure includes the register-file and memory modules, Basys 3 memory-mapped I/O wrapper, control-unit starter templates, CSR module, timer-counter peripheral, and additional supporting modules.

My work consisted of implementing and integrating the provided processor architecture, designing the required datapath RTL, completing and extending the control logic, adding the required processor support for interrupts, integrating the timer-counter, writing RISC-V assembly firmware, verifying the design, and deploying the completed processor to the Basys 3 FPGA.

Original authorship and revision headers are preserved in course-provided source files.

**[ADD ANY SPECIFIC PROFESSOR/COURSE-STAFF ATTRIBUTION REQUIRED.]**

**[IF YOU REUSE OR ADAPT AN ARCHITECTURE DIAGRAM FROM THE TEXTBOOK, INCLUDE ITS SPECIFIC ATTRIBUTION AND LICENSE INFORMATION HERE OR IN THE FIGURE CAPTION.]**

**LIST REFERENCE MATERIALS (assembler manual, lab manual, textbook)**
