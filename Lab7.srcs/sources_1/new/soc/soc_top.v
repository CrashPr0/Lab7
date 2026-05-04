`timescale 1ns/1ps

module soc_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  sw_in,
    output wire [31:0] display_out
);

    // Bus signals from MIPS
    wire [31:0] pc_current;
    wire [31:0] instr_from_imem;
    wire [31:0] rd_bus;
    wire        we_bus;
    wire [31:0] addr_bus;
    wire [31:0] wd_bus;

    // Peripheral read data
    wire [31:0] rd_dm;
    wire [31:0] rd_gpio;
    wire [31:0] rd_fact;

    // Address Decoding logic
    wire sel_dm   = (addr_bus[11:8] == 4'h0); // 0x000 - 0x0FF
    wire sel_gpio = (addr_bus[11:8] == 4'h8) || (addr_bus[11:8] == 4'h9); // 0x800, 0x900
    wire sel_fact = (addr_bus[11:8] == 4'hA); // 0xA00

    // Mux for read bus
    assign rd_bus = sel_dm   ? rd_dm   :
                    sel_gpio ? rd_gpio :
                    sel_fact ? rd_fact :
                               32'h0;

    // Single-Cycle MIPS Core
    // NOTE: You may need to adjust the port names to match your single-cycle 'mips' or 'mips_top' module exactly.
    // If your module is named differently, change 'mips' below.
    mips mips_core (
        .clk        (clk),
        .rst        (rst),
        .pc         (pc_current),
        .instr      (instr_from_imem),
        .memwrite   (we_bus),
        .aluout     (addr_bus),
        .writedata  (wd_bus),
        .readdata   (rd_bus)
    );

    // Instruction Memory
    imem_soc imem (
        .a (pc_current[7:2]),
        .y (instr_from_imem)
    );

    // Data Memory (reusing dmem_pipe as it is just a standard synchronous RAM)
    dmem_pipe dmem (
        .clk (clk),
        .rst (rst),
        .we  (we_bus && sel_dm),
        .a   (addr_bus[7:2]),
        .d   (wd_bus),
        .q   (rd_dm)
    );

    // GPIO Wrapper
    gpio_top gpio (
        .clk         (clk),
        .rst         (rst),
        .we          (we_bus && (addr_bus[11:8] == 4'h9)),
        .a           (addr_bus[3:2]),
        .wd          (wd_bus),
        .sw_in       (sw_in),
        .rd          (rd_gpio),
        .display_reg (display_out)
    );

    // Factorial Wrapper
    factorial_wrapper fact (
        .clk (clk),
        .rst (rst),
        .we  (we_bus && sel_fact),
        .a   (addr_bus[4:2]),
        .wd  (wd_bus),
        .rd  (rd_fact)
    );

endmodule
