`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////
// Company: Ratner Surf Designs
// Engineer: James Ratner
// 
// Create Date: 01/29/2019 04:56:13 PM
// Design Name: 
// Module Name: CU_DCDR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Decoder for RISC-V OTTER
// 
// Dependencies:
// 
// Instantiation Template:
//
// CU_DCDR my_cu_dcdr(
//   .br_eq     (xxxx), 
//   .br_lt     (xxxx), 
//   .br_ltu    (xxxx),
//   .opcode    (xxxx),    
//   .func7     (xxxx),    
//   .func3     (xxxx),    
//   .ALU_FUN   (xxxx),
//   .PC_SEL    (xxxx),
//   .srcA_SEL  (xxxx),
//   .srcB_SEL  (xxxx), 
//   .RF_SEL    (xxxx)   );
//
// 
// Revision:
// Revision 1.00 - Created (02-01-2020) - from Paul, Joseph, & Celina
//          1.01 - (02-08-2020) - removed  else's; fixed assignments
//          1.02 - (02-25-2020) - made all assignments blocking
//          1.03 - (05-12-2020) - reduced func7 to one bit
//          1.04 - (05-31-2020) - removed misleading code
//          1.05 - (12-10-2020) - added comments
//          1.06 - (02-11-2021) - fixed formatting issues
//          1.07 - (12-26-2023) - changed signal names
//
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////

module CU_DCDR(
   input br_eq, 
   input br_lt, 
   input br_ltu,
   input [6:0] opcode,   //-  ir[6:0]
   input func7,          //-  ir[30]
   input [2:0] func3,    //-  ir[14:12] 
   input int_taken,
   output logic [3:0] ALU_FUN,
   output logic [2:0] PC_SEL,
   output logic [1:0] srcA_SEL,
   output logic [2:0] srcB_SEL, 
   output logic [1:0] RF_SEL   );
    
   //- datatypes for RISC-V opcode types
   typedef enum logic [6:0] {
        LUI    = 7'b0110111, 
        AUIPC  = 7'b0010111, 
        JAL    = 7'b1101111, 
        JALR   = 7'b1100111, 
        BRANCH = 7'b1100011, 
        LOAD   = 7'b0000011,
        STORE  = 7'b0100011,
        OP_IMM = 7'b0010011,
        OP_RG3 = 7'b0110011,
        sys    = 7'b1110011
   } opcode_t;
   opcode_t OPCODE; //- define variable of new opcode type
    
   assign OPCODE = opcode_t'(opcode); //- Cast input enum 

   //- datatype for func3Symbols tied to values
   typedef enum logic [2:0] {
        //BRANCH labels (func3)
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
   } func3_t;    
   func3_t FUNC3; //- define variable of new opcode type
   assign FUNC3 = func3_t'(func3); //- Cast input enum 
   
   typedef enum logic [2:0] {
        MRET  = 3'b000,
        CSRRW = 3'b001,
        CSRRS = 3'b010,
        CSRRC = 3'b011
    } sys_func3_t;
    sys_func3_t SYS_FUNC3;
    assign SYS_FUNC3 = sys_func3_t'(func3);
       
   always_comb
   begin
      //- schedule all values to avoid latch
      ALU_FUN = 4'b0000; //add
      srcA_SEL = 2'b00;  //rs1
      srcB_SEL = 2'b00;  //rs2
      PC_SEL = 3'b000;   //pc + 4
      RF_SEL = 2'b00;    //pc + 4
      
      if (int_taken == 1) //just load mtvec into PC; other signals are don't cares
        PC_SEL = 3'b100; //mtvec (ISR address)
      else begin	  
          case(OPCODE)
             LUI:
             begin
                srcA_SEL = 2'b01;   //u-type immediate
                RF_SEL = 2'b11;    //ALU
                ALU_FUN = 4'b1001; //LUI
             end
             
             AUIPC: //add upper immediate to PC and load into X[rd]
             begin
                srcA_SEL = 2'b01;  //u-type immediate
                srcB_SEL = 3'b011; //PC
                RF_SEL = 2'b11;   //ALU
             end
                
             JAL:
             begin
                PC_SEL = 3'b011; //jal
             end
            
             JALR:
             begin
                PC_SEL = 3'b001; //jalr
             end
             
             BRANCH:
             begin //if condition is met, then PC_SEL = 3'b010
                case(FUNC3)
                    BEQ:
                    begin
                        if (br_eq == 1)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    BNE:
                    begin
                        if (br_eq == 0)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    BLT:
                    begin
                        if (br_lt == 1)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    BGE:
                    begin
                        if (br_lt == 0)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    BLTU:
                    begin
                        if (br_ltu == 1)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    BGEU:
                    begin
                        if (br_ltu == 0)
                            PC_SEL = 3'b010; //branch
                    end
                    
                    default: //all 0s
                    begin
                       PC_SEL = 'b000;
                       srcB_SEL = 3'b000; 
                       RF_SEL = 2'b00; 
                       srcA_SEL = 2'b00; 
                       ALU_FUN = 4'b0000;
                    end
                endcase
             end
                
             LOAD:
             begin //adds I-type + RS1 (calculate ADDR), send to MEMADDR2, load into RF
                srcB_SEL = 3'b001; //i-type immediate
                RF_SEL = 2'b10;   //memDOUT2
             end
                
             STORE: //calculate addr, send to mem, mem stores data directly from rs2
             begin
                 srcB_SEL = 3'b010; //s-type
             end
                
             OP_IMM: //does operation in ALU on rs1 with i-type immediate, sends to RF
             begin
                srcB_SEL = 3'b001;  //i-type immediate
                RF_SEL = 2'b11;    //ALU            
                if (func3 == 3'b101)
                    ALU_FUN = {func7, func3};
                else
                    ALU_FUN = {1'b0, func3};
             end
             
             OP_RG3: //add
             begin
                ALU_FUN = {func7, func3};
                RF_SEL = 2'b11; //ALU
             end
             
             sys:
             begin
             case(SYS_FUNC3)
             
             CSRRW: //csrrw
             begin
             PC_SEL = 3'b000;   //next instruction (PC+4)
             RF_SEL = 2'b01;    //CSR_RD
             srcA_SEL = 2'b00;  //rs1
             ALU_FUN = 4'b1001; //LUI; just passes the input --> this way, rs1 loads into CSR
             end
             
             CSRRC: //csrrc
             begin
             PC_SEL = 3'b000;   //next instruction (PC+4)
             RF_SEL = 2'b01;    //CSR_RD
             srcB_SEL = 3'b100; //csr
             srcA_SEL = 2'b10;  //not rs1
             ALU_FUN = 4'b0111; //and
             end
             
             CSRRS: //csrrs
             begin
             PC_SEL = 3'b000;   //next instruction (PC+4)
             RF_SEL = 2'b01;    //CSR_RD
             srcB_SEL = 3'b100; //csr
             srcA_SEL = 2'b00;  //rs1
             ALU_FUN = 4'b0110; //or
             end
             
             MRET: //mret
             begin
             PC_SEL = 3'b101; //mepc
             end
             
             default:
             begin
             //all 0s
             end
             endcase
             end
    
             default: //all 0s
             begin
                 PC_SEL = 3'b000;
                 srcB_SEL = 3'b000; 
                 RF_SEL = 2'b00; 
                 srcA_SEL = 2'b00; 
                 ALU_FUN = 4'b0000;
             end
          endcase
       end
    end
endmodule