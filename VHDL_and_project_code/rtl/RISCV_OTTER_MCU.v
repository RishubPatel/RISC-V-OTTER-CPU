`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly SLO
// Engineer: Rishub Patel
// 
// Create Date:  
// Design Name: RISC-V_OTTER_MCU
// Module Name: RISCV_OTTER_MCU
// Project Name: RISCV_MCU 
// Target Devices: Basys3 Board 
// Tool Versions: 
// Description: This is a top-level for a working RISC-V MCU (without the wrapper).
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module RISCV_OTTER_MCU( 
    input RST, 
    input intr,
    input clk,
    input [31:0] iobus_in,
    output [31:0] iobus_out,
    output [31:0] iobus_addr,
    output iobus_wr
    );
    
    wire memRDEN1;
    wire memRDEN2;
    wire memWE2;
    wire [31:0] pc;
    wire [31:0] ALU_result;
    wire [31:0] rs2;
    wire [31:0] ir;
    wire [31:0] memDOUT2;
    wire [1:0] RF_SEL;
    wire [31:0] w_data_rf;
    wire [31:0] rs1;
    wire [2:0] PC_SEL;
    wire [31:0] branch;
    wire [31:0] jal;
    wire [31:0] jalr;
    wire [31:0] pc_mux_out;
    wire PC_WE;
    wire PC_reset;
    wire [31:0] i_type_imm;
    wire [31:0] j_type_imm;
    wire [31:0] b_type_imm;
    wire [31:0] s_type_imm;
    wire [31:0] u_type_imm;
    wire [1:0] srcA_SEL;
    wire [2:0] srcB_SEL;
    wire [31:0] ALU_srcA;
    wire [31:0] ALU_srcB;
    wire [3:0] ALU_FUN;
    wire RF_WE;
    wire br_eq; 
    wire br_lt;
    wire br_ltu;
    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire int_taken;
    wire [31:0] csr_RD;
    wire csr_WE;
    wire mret_exec;
    wire mie;
    
    assign iobus_out = rs2;
    assign iobus_addr = ALU_result;
    
    //MEMORY
    Memory OTTER_MEMORY (
        .MEM_CLK   (clk),
        .MEM_RDEN1 (memRDEN1), 
        .MEM_RDEN2 (memRDEN2), 
        .MEM_WE2   (memWE2),
        .MEM_ADDR1 (pc[15:2]),
        .MEM_ADDR2 (ALU_result),
        .MEM_DIN2  (rs2),  
        .MEM_SIZE  (ir[13:12]),
        .MEM_SIGN  (ir[14]),
        .IO_IN     (iobus_in),
        .IO_WR     (iobus_wr),
        .MEM_DOUT1 (ir),           //instructions
        .MEM_DOUT2 (memDOUT2)  ); 
    
    //REG_FILE
    mux_4t1_nb  #(.n(32)) MUX_rf  (
        .SEL   (RF_SEL), 
        .D0    (pc + 4), 
        .D1    (csr_RD),
        .D2    (memDOUT2), 
        .D3    (ALU_result),
        .D_OUT (w_data_rf) ); //rf write data
    
    RegFile REG_FILE (
        .w_data (w_data_rf),
        .clk    (clk), 
        .en     (RF_WE),
        .adr1   (ir[19:15]),
        .adr2   (ir[24:20]),
        .w_adr  (ir[11:7]),
        .rs1    (rs1), 
        .rs2    (rs2)  );
    
    //PC
    mux_8t1_nb  #(.n(32)) PC_MUX  (
        .SEL   (PC_SEL), 
        .D0    (pc + 4), 
        .D1    (jalr), 
        .D2    (branch), 
        .D3    (jal),
        .D4    (mtvec),
        .D5    (mepc),
        .D6    (0), //unused input
        .D7    (0), //unused input
        .D_OUT (pc_mux_out) );  
    
    reg_nb_synch_clr #(.n(32)) PC (
       .data_in  (pc_mux_out), 
       .ld       (PC_WE), 
       .clk      (clk), 
       .clr      (PC_reset),
       .data_out (pc) );
       
    //IMMED_GEN
    assign i_type_imm = {{21{ir[31]}}, ir[30:25], ir[24:20]};
    assign j_type_imm = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
    assign b_type_imm = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};
    assign s_type_imm = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign u_type_imm = {ir[31:12], 12'd0};
    
    //BRANCH_ADDR_GEN
    assign jal = pc + j_type_imm;
    assign jalr = rs1 + i_type_imm;
    assign branch = pc + b_type_imm;
    
    //BRANCH_COND_GEN
    assign br_eq = rs1 == rs2;
    assign br_lt = $signed(rs1) < $signed(rs2);
    assign br_ltu = rs1 < rs2;
    
    //ALU
    mux_4t1_nb  #(.n(32)) ALU_MUXA  (
        .SEL   (srcA_SEL), 
        .D0    (rs1), 
        .D1    (u_type_imm),
        .D2    (~rs1),
        .D3    (0), //unused input
        .D_OUT (ALU_srcA) );  
 
    
    mux_8t1_nb  #(.n(32)) ALU_MUXB  (
       .SEL   (srcB_SEL), 
       .D0    (rs2), 
       .D1    (i_type_imm), 
       .D2    (s_type_imm), 
       .D3    (pc),
       .D4    (csr_RD),
       .D5    (0), //unused input
       .D6    (0), //unused input
       .D7    (0), //unused input
       .D_OUT (ALU_srcB) ); 
    
    ALU ALU (
        .OP_1(ALU_srcA),
        .OP_2(ALU_srcB),
        .ALU_FUN(ALU_FUN),
        .RESULT(ALU_result) );
   
    //CU_FSM
     CU_FSM my_fsm(
        .intr      (intr && mie),
        .clk       (clk),
        .RST       (RST),
        .opcode    (ir[6:0]),
        .func3     (ir[14:12]),
        .PC_WE     (PC_WE),
        .RF_WE     (RF_WE),
        .memWE2    (memWE2),
        .memRDEN1  (memRDEN1),
        .memRDEN2  (memRDEN2),
        .reset     (PC_reset),
        .csr_WE    (csr_WE),
        .int_taken (int_taken),
        .mret_exec (mret_exec)   );
    
    //CU_DCDR
     CU_DCDR my_cu_dcdr(
       .br_eq     (br_eq),
       .br_lt     (br_lt),
       .br_ltu    (br_ltu),
       .int_taken (int_taken),
       .opcode    (ir[6:0]),
       .func3     (ir[14:12]),    
       .func7     (ir[30]),
       .ALU_FUN   (ALU_FUN),
       .PC_SEL    (PC_SEL),
       .srcA_SEL  (srcA_SEL),
       .srcB_SEL  (srcB_SEL), 
       .RF_SEL    (RF_SEL)   );
    
    //CSR
     CSR  csr(
        .CLK        (clk),
        .RST        (RST),
        .MRET_EXEC  (mret_exec),
        .INT_TAKEN  (int_taken),
        .ADDR       (ir[31:20]),
        .PC         (pc),
        .WD         (ALU_result),
        .WR_EN      (csr_WE),
        .RD         (csr_RD),
        .CSR_MEPC   (mepc),
        .CSR_MTVEC  (mtvec),
        .CSR_MSTATUS_MIE (mie)    );
    
    endmodule