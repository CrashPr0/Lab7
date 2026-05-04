`timescale 1ns/1ps

module basys3_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       button,     // Unused in logic, but required by constraints
    input  wire [8:0] switches,   // using [3:0] for N input, per the xdc
    output wire [3:0] LEDSEL,     // Anodes
    output wire [7:0] LEDOUT,     // Cathodes
    output wire       we_dm       // Optional debug LED
);

    wire [31:0] display_data;

    // Instantiate the Week 3 Single-Cycle SoC
    soc_top soc (
        .clk         (clk),
        .rst         (rst),
        .sw_in       (switches[3:0]),
        .display_out (display_data)
    );

    // Instantiate the 7-segment display driver
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
