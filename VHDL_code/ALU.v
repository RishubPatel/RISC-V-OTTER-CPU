`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly SLO
// Engineer: Rishub Patel
// 
// Create Date: 01/26/2026 05:31:15 PM
// Design Name: RISC-V OTTER Arithmetic Logic Unit
// Module Name: ALU
// Project Name: CPE233Experiment3
// Description: This is a RISC-V Arithmetic Logic unit (ALU) model. It does a bunch
//              of bit-crunching operations. ALU_FUN selects which operation to do.
///////////////////////////////////////////////////////////////////////////////////

module ALU(
    input [31:0] OP_1,       //input value 1
    input [31:0] OP_2,       //input value 2
    input [3:0] ALU_FUN,     //operation (SEL)
    output reg [31:0] RESULT //output value; automatically truncates to 32 LSBs
    );
    parameter [3:0] ADD = 4'b0000, SUB = 4'b1000, OR = 4'b0110, AND = 4'b0111,
    XOR = 4'b0100, SRL = 4'b0101, SLL = 4'b0001, SRA = 4'b1101, SLT = 4'b0010,
    SLTU = 4'b0011, LUI = 4'b1001;
    
    always@(OP_1, OP_2, ALU_FUN) begin   
    case(ALU_FUN)
        ADD: begin //add
        RESULT = $signed(OP_1) + $signed(OP_2);
        end
        
        SUB: begin //subtract
        RESULT = $signed(OP_1) - $signed(OP_2);
        end
        
        OR: begin //bitwise OR
        RESULT = OP_1 | OP_2;
        end
        
        AND: begin //bitwise AND
        RESULT = OP_1 & OP_2;
        end
        
        XOR: begin //bitwise exclusive OR (XOR)
        RESULT = OP_1 ^ OP_2;
        end
        
        SRL: begin //logical shift right of OP_1 by OP_2-many bits
        RESULT = OP_1 >> OP_2[4:0];
        end
        
        SLL: begin //logical shift left of OP_1 by OP_2-many bits
        RESULT = OP_1 << OP_2[4:0];
        end
        
        SRA: begin //arithmetic shift right of OP_1 by OP_2-many bits
        RESULT = $signed(OP_1) >>> OP_2[4:0];
        end
        
        SLT: begin //set if OP_1 < OP_2 (signed)
        RESULT = ($signed(OP_1) < $signed(OP_2)) ? 1 : 0;
        end
        
        SLTU: begin //set if OP_1 < OP_2 (unsigned)
        RESULT = (OP_1 < OP_2) ? 1 : 0;
        end
        
        LUI: begin //load upper immediate
        RESULT = OP_1;
        end
        
        default: RESULT = 32'hDEADBEEF;
    endcase
    end
endmodule
