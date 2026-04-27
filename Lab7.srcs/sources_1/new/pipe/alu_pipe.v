`timescale 1ns/1ps
// 4-bit op ALU (Lab 8 pipelined MIPS).
// Shift ops use `shamt` which is instr[10:6] carried in via input `a` bits [10:6]
// (datapath drives `instr` onto `a` for shift ops; rs value otherwise).
module alu_pipe (
        input  wire [3:0]  op,
        input  wire [31:0] a,
        input  wire [31:0] b,
        output wire        zero,
        output reg  [31:0] y
    );

    assign zero = (y == 32'b0);

    always @ (*) begin
        case (op)
            4'b0000: y = a & b;               // AND
            4'b0001: y = a | b;               // OR
            4'b0010: y = a + b;               // ADD (also LW/SW/ADDI address calc)
            4'b0110: y = a - b;               // SUB (and BEQ compare)
            4'b0111: y = (a < b) ? 32'd1 : 32'd0;    // SLT (unsigned for simplicity)
            4'b1001: y = b << a[10:6];        // SLL : b is rt, shamt from instr[10:6]
            4'b1010: y = b >> a[10:6];        // SRL
            default: y = 32'b0;
        endcase
    end
endmodule
