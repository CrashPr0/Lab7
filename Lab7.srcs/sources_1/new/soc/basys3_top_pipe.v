`timescale 1ns/1ps

module basys3_top_pipe (
    input  wire       clk,
    input  wire       rst,
    input  wire       button,     // Unused in logic, but required by constraints
    input  wire [8:0] switches,   // using [3:0] for N input, per the xdc
    output wire [3:0] LEDSEL,     // Anodes
    output wire [7:0] LEDOUT,     // Cathodes
    output wire       we_dm       // Optional debug LED
);

    // The raw 32-bit output from the SoC
    wire [31:0] display_data;

    // Instantiate the Week 4 Pipelined SoC
    soc_top_pipe soc (
        .clk         (clk),
        .rst         (rst),
        .btn_in      (button),
        .sw_in       (switches[3:0]),
        .ra3         (5'b0),
        .rd3         (),
        .pc_current  (),
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
    assign we_dm = 1'b0; // Or connect to a debug signal if desired

endmodule
