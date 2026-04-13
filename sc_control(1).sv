// =============================================================================
// sc_control.sv
// Main Control Unit - single-cycle RISC-V (Section 4.4 - Patterson & Hennessy)
//
// Decodes the 7-bit opcode and asserts control signals for the datapath.
//
// Supported instructions:
//   R-type  (0110011): add, sub, and, or, slt
//   I-type  (0000011): lw
//   S-type  (0100011): sw
//   B-type  (1100011): beq
//
// Control signal summary:
//
//   Signal    | R-type | lw | sw | beq
//   ----------|--------|----|----|-----
//   ALUSrc    |   0    |  1 |  1 |  0    0=reg, 1=imm
//   MemtoReg  |   0    |  1 |  - |  -    0=ALU, 1=mem
//   RegWrite  |   1    |  1 |  0 |  0
//   MemRead   |   0    |  1 |  0 |  0
//   MemWrite  |   0    |  0 |  1 |  0
//   Branch    |   0    |  0 |  0 |  1
//   ALUOp[1]  |   1    |  0 |  0 |  0
//   ALUOp[0]  |   0    |  0 |  0 |  1
//
//   ALUOp encoding:
//     2'b00 = Load/Store (force ADD)
//     2'b01 = Branch     (force SUB)
//     2'b10 = R-type     (ALU Control decodes Funct3/Funct7)
//
// Exercise:
//   Implement the always_comb block below.
//   Use the opcode constants and the control signal table above as reference.
//   Validate your implementation by running sc_cpu_tb against golden.txt.
// =============================================================================

`timescale 1ns / 1ps

module sc_control (
    input  logic [6:0] Opcode,
    output logic       ALUSrc,
    output logic       MemtoReg,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       Branch,
    output logic [1:0] ALUOp
);

    localparam R_TYPE = 7'b0110011; // add, sub, and, or, slt
    localparam LOAD   = 7'b0000011; // lw
    localparam STORE  = 7'b0100011; // sw
    localparam BRANCH = 7'b1100011; // beq

    always_comb begin
        // Set safe defaults for all signals before the case statement.
        // This prevents latches and ensures unrecognized opcodes produce
        // no side effects (no memory writes, no register writes).
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 2'b00;

        case (Opcode)
            R_TYPE: begin
                // add, sub, and, or, slt
                // ALUSrc=0 (usa rs2), RegWrite=1, ALUOp=10 (decodifica pelo ALU Control)
                ALUSrc   = 1'b0;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                ALUOp    = 2'b10;
            end

            LOAD: begin
                // lw: endereço = rs1 + imm, lê memória, escreve no registrador
                ALUSrc   = 1'b1; // usa imediato para calcular endereço
                MemtoReg = 1'b1; // dado vem da memória
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                ALUOp    = 2'b00; // força ADD
            end

            STORE: begin
                // sw: endereço = rs1 + imm, escreve na memória
                ALUSrc   = 1'b1; // usa imediato para calcular endereço
                MemtoReg = 1'b0; // não escreve em registrador (don't care, mas 0 é seguro)
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b1;
                Branch   = 1'b0;
                ALUOp    = 2'b00; // força ADD
            end

            BRANCH: begin
                // beq: compara rs1 - rs2, desvia se Zero=1
                ALUSrc   = 1'b0; // usa rs2
                MemtoReg = 1'b0; // don't care
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b1;
                ALUOp    = 2'b01; // força SUB (para verificar igualdade via Zero)
            end

            default: ; // signals remain at safe defaults
        endcase
    end

endmodule
