`timescale 1ns/1ps

module basys3_top_pipe (
    input  wire       clk,
    input  wire       rst,
    input  wire       button,
    input  wire [8:0] switches,
    output wire [3:0] LEDSEL,
    output wire [7:0] LEDOUT,
    output wire       we_dm
);

    // --- Clock Enable Generator ---
    // Instead of a dangerous clock divider, we generate a 1-cycle pulse every 4 clock cycles (25MHz effective)
    reg [1:0] ce_div;
    always @(posedge clk) begin
        if (rst) ce_div <= 2'b0;
        else     ce_div <= ce_div + 1;
    end
    wire ce = (ce_div == 2'b00); // Pulse high every 4th cycle

    // To use this CE, we'd need to thread it through every register in the SoC...
    // Since we don't have a CE port on every module, we'll use a BUFGCE (Global Clock Buffer with Clock Enable)
    // This is the Xilinx-safe way to divide a clock without timing violations!
    wire sys_clk;
    BUFGCE #(
        .SIM_DEVICE("7SERIES")
    ) clk_buf (
        .I  (clk),
        .CE (ce),
        .O  (sys_clk)
    );

    wire [31:0] display_data;

    // The SoC runs on the heavily throttled (but safe) sys_clk
    soc_top_pipe soc (
        .clk         (sys_clk),
        .rst         (rst),
        .btn_in      (button),
        .sw_in       (switches[3:0]),
        .ra3         (5'b0),
        .rd3         (),
        .pc_current  (),
        .display_out (display_data),
        .we_dm       (we_dm)
    );

    // The display driver runs on the sys_clk to clear multiple clock driver warnings
    disp_hex_mux display (
        .clk     (sys_clk),
        .reset   (rst),
        .hex_in  (display_data),
        .an      (LEDSEL),
        .sseg    (LEDOUT)
    );

endmodule
