`timescale 1ns/1ps
// Top-level pipelined MIPS: imem + pipelined datapath + dmem.
// Exposes useful debug ports for the testbench waveform view.
module mips_top_pipe (
        input  wire        clk,
        input  wire        rst,
        input  wire [4:0]  ra3,
        output wire        we_dm,
        output wire [31:0] pc_current,
        output wire [31:0] instrD,
        output wire [31:0] instrE,
        output wire [31:0] instrM,
        output wire [31:0] instrW,
        output wire [31:0] alu_outM,
        output wire [31:0] wd_dm,
        output wire [31:0] rd_dm,
        output wire [31:0] rd3
    );

    wire [31:0] instr_from_imem;
    wire [5:0]  dm_addr;

    datapath_pipe dp (
        .clk             (clk),
        .rst             (rst),
        .ra3             (ra3),
        .instr_from_imem (instr_from_imem),
        .rd_dm           (rd_dm),
        .we_dm           (we_dm),
        .dm_addr         (dm_addr),
        .wd_dm           (wd_dm),
        .pc_current      (pc_current),
        .instrD_out      (instrD),
        .instrE_out      (instrE),
        .instrM_out      (instrM),
        .instrW_out      (instrW),
        .alu_outM_dbg    (alu_outM),
        .rd3             (rd3)
    );

    imem_pipe imem (
        .a (pc_current[7:2]),
        .y (instr_from_imem)
    );

    dmem_pipe dmem (
        .clk (clk),
        .rst (rst),
        .we  (we_dm),
        .a   (dm_addr),
        .d   (wd_dm),
        .q   (rd_dm)
    );
endmodule
