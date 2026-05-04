`timescale 1ns/1ps

module soc_top_pipe (
    input  wire        clk,
    input  wire        rst,
    input  wire        btn_in,
    input  wire [3:0]  sw_in,
    input  wire [4:0]  ra3,
    output wire [31:0] rd3,
    output wire [31:0] pc_current,
    output wire [31:0] display_out,
    output wire        we_dm
);

    // Debounce the button
    wire btn_pulse;
    debounce_pulse deb (
        .clk       (clk),
        .rst       (rst),
        .btn_in    (btn_in),
        .pulse_out (btn_pulse)
    );

    // Bus signals from MIPS
    wire [31:0] instr_from_imem;
    wire [31:0] rd_bus;
    wire        we_bus;
    wire [31:0] addr_bus;
    wire [31:0] wd_bus;
    
    assign we_dm = we_bus;

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

    // MIPS Pipelined Core
    datapath_pipe dp (
        .clk             (clk),
        .rst             (rst),
        .ra3             (ra3),
        .instr_from_imem (instr_from_imem),
        .rd_dm           (rd_bus),
        .we_dm           (we_bus),
        .dm_addr         (addr_bus),
        .wd_dm           (wd_bus),
        .pc_current      (pc_current),
        .instrD_out      (),
        .instrE_out      (),
        .instrM_out      (),
        .instrW_out      (),
        .alu_outM_dbg    (),
        .rd3             (rd3)
    );

    imem_soc imem (
        .a (pc_current[7:2]),
        .y (instr_from_imem)
    );

    // Peripherals
    dmem_pipe dmem (
        .clk (clk),
        .rst (rst),
        .we  (we_bus && sel_dm),
        .a   (addr_bus[7:2]),
        .d   (wd_bus),
        .q   (rd_dm)
    );

    gpio_top gpio (
        .clk         (clk),
        .rst         (rst),
        .we          (we_bus && sel_gpio),
        .a           (addr_bus[3:2]),
        .wd          (wd_bus),
        .sw_in       (sw_in),
        .btn_pulse   (btn_pulse),
        .rd          (rd_gpio),
        .display_reg (display_out)
    );

    factorial_wrapper fact (
        .clk (clk),
        .rst (rst),
        .we  (we_bus && sel_fact),
        .a   (addr_bus[4:2]),
        .wd  (wd_bus),
        .rd  (rd_fact)
    );

endmodule
