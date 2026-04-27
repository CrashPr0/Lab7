`timescale 1ns/1ps
// Combinational control unit for pipelined MIPS.
// Generates all control signals for the 17 Lab 8 instructions. The pipeline
// pushes these signals through ID/EX, EX/MEM, MEM/WB registers so each stage
// consumes only the bits it cares about.
//
// wd_rf_selW[2:0]:  000=alu_out  001=rd_dm(LW)  010=hi(MFHI)  011=lo(MFLO)  100=pc_plus4(JAL)
// reg_dstE[1:0]:    00=rt(ADDI/LW)   01=rd(R-type)   10=$31(JAL)
module controlunit_pipe (
        input  wire [5:0] opcode,
        input  wire [5:0] funct,

        // --- ID-stage signals (used immediately for J/JAL) ---
        output reg        jumpD,          // 1 for J and JAL  (PC <- jta in ID)
        output reg        jalD,           // 1 for JAL only

        // --- EX-stage signals ---
        output reg  [3:0] alu_ctrlE,
        output reg        alu_srcE,       // 0=reg(rd2), 1=sign-ext imm
        output reg  [1:0] reg_dstE,       // 00=rt, 01=rd, 10=$31
        output reg        branchE,        // BEQ
        output reg        jrE,            // JR
        output reg        shift_selE,     // 1 = route instr-bits to alu input 'a' for SLL/SRL

        // --- MEM-stage signals ---
        output reg        we_dmM,
        output reg        hilo_weM,

        // --- WB-stage signals ---
        output reg        we_regW,
        output reg  [2:0] wd_rf_selW
    );

    // R-type decode via funct (alu_op == 2'b10 style collapsed into funct)
    // We produce control directly; no two-level decode.
    always @ (*) begin
        // Defaults: NOP (nothing happens).
        jumpD      = 1'b0;
        jalD       = 1'b0;
        alu_ctrlE  = 4'b0010;  // ADD default
        alu_srcE   = 1'b0;
        reg_dstE   = 2'b01;
        branchE    = 1'b0;
        jrE        = 1'b0;
        shift_selE = 1'b0;
        we_dmM     = 1'b0;
        hilo_weM   = 1'b0;
        we_regW    = 1'b0;
        wd_rf_selW = 3'b000;

        case (opcode)
        // -------- R-type --------
        6'b00_0000: begin
            reg_dstE = 2'b01;           // write rd
            case (funct)
                6'b10_0000: begin       // ADD
                    alu_ctrlE = 4'b0010;
                    we_regW   = 1'b1;
                end
                6'b10_0010: begin       // SUB
                    alu_ctrlE = 4'b0110;
                    we_regW   = 1'b1;
                end
                6'b10_0100: begin       // AND
                    alu_ctrlE = 4'b0000;
                    we_regW   = 1'b1;
                end
                6'b10_0101: begin       // OR
                    alu_ctrlE = 4'b0001;
                    we_regW   = 1'b1;
                end
                6'b10_1010: begin       // SLT
                    alu_ctrlE = 4'b0111;
                    we_regW   = 1'b1;
                end
                6'b00_0000: begin       // SLL
                    alu_ctrlE  = 4'b1001;
                    shift_selE = 1'b1;  // route instr to a for shamt
                    we_regW    = 1'b1;
                end
                6'b00_0010: begin       // SRL
                    alu_ctrlE  = 4'b1010;
                    shift_selE = 1'b1;
                    we_regW    = 1'b1;
                end
                6'b01_1001: begin       // MULTU  -> writes HI/LO (no RF write)
                    hilo_weM  = 1'b1;
                    we_regW   = 1'b0;
                end
                6'b01_0000: begin       // MFHI
                    wd_rf_selW = 3'b010;
                    we_regW    = 1'b1;
                end
                6'b01_0010: begin       // MFLO
                    wd_rf_selW = 3'b011;
                    we_regW    = 1'b1;
                end
                6'b00_1000: begin       // JR
                    jrE     = 1'b1;
                    we_regW = 1'b0;
                end
                default: ;
            endcase
        end

        // -------- I-type --------
        6'b00_1000: begin               // ADDI
            alu_ctrlE = 4'b0010;
            alu_srcE  = 1'b1;
            reg_dstE  = 2'b00;          // write rt
            we_regW   = 1'b1;
        end
        6'b10_0011: begin               // LW
            alu_ctrlE  = 4'b0010;
            alu_srcE   = 1'b1;
            reg_dstE   = 2'b00;
            wd_rf_selW = 3'b001;        // mem data
            we_regW    = 1'b1;
        end
        6'b10_1011: begin               // SW
            alu_ctrlE = 4'b0010;
            alu_srcE  = 1'b1;
            we_dmM    = 1'b1;
            we_regW   = 1'b0;
        end
        6'b00_0100: begin               // BEQ
            alu_ctrlE = 4'b0110;        // subtract -> zero = equal
            branchE   = 1'b1;
            we_regW   = 1'b0;
        end

        // -------- J-type --------
        6'b00_0010: begin               // J
            jumpD   = 1'b1;
            we_regW = 1'b0;
        end
        6'b00_0011: begin               // JAL
            jumpD      = 1'b1;
            jalD       = 1'b1;
            reg_dstE   = 2'b10;         // target = $31
            wd_rf_selW = 3'b100;        // write pc+4
            we_regW    = 1'b1;
        end
        default: ;
        endcase
    end
endmodule
