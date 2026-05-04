`timescale 1ns/1ps

module basys3_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       button,
    input  wire [8:0] switches,
    output wire [3:0] LEDSEL,
    output wire [7:0] LEDOUT,
    output wire       we_dm
);

    // --- Clock Enable Generator ---
    // The single-cycle processor struggles at 100MHz (10ns) due to the long critical path.
    // We divide the clock to 12.5MHz (a /8 divider) to ensure setup times are met.
    reg [2:0] ce_div;
    always @(posedge clk) begin
        if (rst) ce_div <= 3'b0;
        else     ce_div <= ce_div + 1;
    end
    wire ce = (ce_div == 3'b000);

    wire sys_clk;
    BUFGCE #(
        .SIM_DEVICE("7SERIES")
    ) clk_buf (
        .I  (clk),
        .CE (ce),
        .O  (sys_clk)
    );

    wire [31:0] display_data;

    // Instantiate the Week 3 Single-Cycle SoC (runs on 12.5MHz safe clock)
    soc_top soc (
        .clk         (sys_clk),
        .rst         (rst),
        .sw_in       (switches[3:0]),
        .display_out (display_data)
    );

    // Instantiate the 7-segment display driver (runs on 100MHz for flicker-free refresh)
    disp_hex_mux display (
        .clk     (clk),
        .reset   (rst),
        .hex_in  (display_data),
        .an      (LEDSEL),
        .sseg    (LEDOUT)
    );

    // Optional: wire a single LED to we_dm to show when memory is being written
    assign we_dm = 1'b0;

endmodule
