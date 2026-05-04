`timescale 1ns/1ps

module mips (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc,
    input  wire [31:0] instr,
    output wire        memwrite,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    input  wire [31:0] readdata
);
    wire [4:0]  rs = instr[25:21];
    wire [4:0]  rt = instr[20:16];
    wire [4:0]  rd = instr[15:11];

    // Control Signals
    wire        jump;
    wire        jal;
    wire        jr;
    wire        branch;
    wire        alusrc;
    wire [1:0]  regdst;
    wire        regwrite;
    wire [3:0]  alucontrol;
    wire        shift_sel;
    wire [2:0]  wd_rf_sel;
    wire        hilowrite;
    // datapath wires
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] rd1, rd2;
    wire [31:0] sext_imm;
    wire [31:0] jta;
    wire [31:0] bta;
    wire [31:0] alu_a, alu_b, alu_y;
    wire        alu_zero;
    wire [63:0] mult_out;
    wire [31:0] hi_out, lo_out;
    wire [4:0]  rf_wa;
    wire [31:0] rf_wd;

    controller_single cu (
        .opcode     (instr[31:26]),
        .funct      (instr[5:0]),
        .jump       (jump),
        .jal        (jal),
        .jr         (jr),
        .branch     (branch),
        .alusrc     (alusrc),
        .regdst     (regdst),
        .regwrite   (regwrite),
        .alucontrol (alucontrol),
        .shift_sel  (shift_sel),
        .we_dm      (memwrite),
        .hilowrite  (hilowrite),
        .wd_rf_sel  (wd_rf_sel)
    );

    // PC Reg
    reg [31:0] PC_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) PC_reg <= 32'h0;
        else     PC_reg <= pc_next;
    end
    assign pc = PC_reg;
    assign pc_plus4 = PC_reg + 32'd4;

    assign jta = {pc_plus4[31:28], instr[25:0], 2'b00};
    assign sext_imm = {{16{instr[15]}}, instr[15:0]};
    assign bta = pc_plus4 + {sext_imm[29:0], 2'b00};

    wire pc_branch = branch & alu_zero;
    wire [31:0] pc_next_br = pc_branch ? bta : pc_plus4;
    wire [31:0] pc_next_j  = jump ? jta : pc_next_br;
    assign pc_next = jr ? rd1 : pc_next_j;

    // Regfile Write Address
    assign rf_wa = (regdst == 2'b10) ? 5'd31 :
                   (regdst == 2'b01) ? rd    : rt;

    // Regfile Write Data
    assign rf_wd = (wd_rf_sel == 3'b001) ? readdata :
                   (wd_rf_sel == 3'b010) ? hi_out :
                   (wd_rf_sel == 3'b011) ? lo_out :
                   (wd_rf_sel == 3'b100) ? pc_plus4 : alu_y;

    regfile_single rf (
        .clk (clk),
        .we  (regwrite),
        .ra1 (rs),
        .ra2 (rt),
        .wa  (rf_wa),
        .wd  (rf_wd),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    // ALU
    assign alu_a = shift_sel ? instr : rd1;
    assign alu_b = alusrc ? sext_imm : rd2;

    alu_single alu (
        .op   (alucontrol),
        .a    (alu_a),
        .b    (alu_b),
        .zero (alu_zero),
        .y    (alu_y)
    );

    // HI/LO
    multiplier mult (.a(rd1), .b(rd2), .y(mult_out));
    hilo_reg hilo (
        .clk (clk),
        .we  (hilowrite),
        .d   (mult_out),
        .hi  (hi_out),
        .lo  (lo_out)
    );

    // Outputs
    assign aluout    = alu_y;
    assign writedata = rd2;
endmodule

module controller_single (
        input  wire [5:0] opcode,
        input  wire [5:0] funct,
        output reg        jump,
        output reg        jal,
        output reg        jr,
        output reg        branch,
        output reg        alusrc,
        output reg  [1:0] regdst,
        output reg        regwrite,
        output reg  [3:0] alucontrol,
        output reg        shift_sel,
        output reg        we_dm,
        output reg        hilowrite,
        output reg  [2:0] wd_rf_sel
);
    always @(*) begin
        jump       = 1'b0;
        jal        = 1'b0;
        jr         = 1'b0;
        branch     = 1'b0;
        alusrc     = 1'b0;
        regdst     = 2'b01;
        regwrite   = 1'b0;
        alucontrol = 4'b0010;
        shift_sel  = 1'b0;
        we_dm      = 1'b0;
        hilowrite  = 1'b0;
        wd_rf_sel  = 3'b000;

        case (opcode)
        6'b00_0000: begin // R-type
            regdst = 2'b01;
            case (funct)
                6'b10_0000: begin alucontrol=4'b0010; regwrite=1'b1; end // ADD
                6'b10_0010: begin alucontrol=4'b0110; regwrite=1'b1; end // SUB
                6'b10_0100: begin alucontrol=4'b0000; regwrite=1'b1; end // AND
                6'b10_0101: begin alucontrol=4'b0001; regwrite=1'b1; end // OR
                6'b10_1010: begin alucontrol=4'b0111; regwrite=1'b1; end // SLT
                6'b00_0000: begin alucontrol=4'b1001; shift_sel=1'b1; regwrite=1'b1; end // SLL
                6'b00_0010: begin alucontrol=4'b1010; shift_sel=1'b1; regwrite=1'b1; end // SRL
                6'b01_1001: begin hilowrite=1'b1; end // MULTU
                6'b01_0000: begin wd_rf_sel=3'b010; regwrite=1'b1; end // MFHI
                6'b01_0010: begin wd_rf_sel=3'b011; regwrite=1'b1; end // MFLO
                6'b00_1000: begin jr=1'b1; end // JR
                default: ;
            endcase
        end
        6'b00_1000: begin // ADDI
            alucontrol=4'b0010; alusrc=1'b1; regdst=2'b00; regwrite=1'b1;
        end
        6'b10_0011: begin // LW
            alucontrol=4'b0010; alusrc=1'b1; regdst=2'b00; wd_rf_sel=3'b001; regwrite=1'b1;
        end
        6'b10_1011: begin // SW
            alucontrol=4'b0010; alusrc=1'b1; we_dm=1'b1;
        end
        6'b00_0100: begin // BEQ
            alucontrol=4'b0110; branch=1'b1;
        end
        6'b00_0010: begin // J
            jump=1'b1;
        end
        6'b00_0011: begin // JAL
            jump=1'b1; jal=1'b1; regdst=2'b10; wd_rf_sel=3'b100; regwrite=1'b1;
        end
        default: ;
        endcase
    end
endmodule

module alu_single (
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
            4'b0010: y = a + b;               // ADD
            4'b0110: y = a - b;               // SUB
            4'b0111: y = (a < b) ? 32'd1 : 32'd0;    // SLT
            4'b1001: y = b << a[10:6];        // SLL
            4'b1010: y = b >> a[10:6];        // SRL
            default: y = 32'b0;
        endcase
    end
endmodule

module regfile_single (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] rf [31:0];

    always @(posedge clk) begin
        if (we && (wa != 5'd0)) begin
            rf[wa] <= wd;
        end
    end

    // asynchronous read
    assign rd1 = (ra1 == 5'd0) ? 32'b0 : rf[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'b0 : rf[ra2];
endmodule
