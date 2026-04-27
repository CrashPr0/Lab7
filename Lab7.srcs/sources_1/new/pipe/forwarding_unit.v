`timescale 1ns/1ps
// Forwarding unit for EX stage operands.
// Priority: EX/MEM forward, then MEM/WB forward, else use ID/EX register value.
//
// fwd_* = 2'b00 : use ID/EX register value
//       = 2'b10 : forward from EX/MEM stage (alu_out)
//       = 2'b01 : forward from MEM/WB stage (write-back data)
module forwarding_unit (
        input  wire [4:0] rsE,
        input  wire [4:0] rtE,

        input  wire       we_regM,
        input  wire [4:0] rf_waM,

        input  wire       we_regW,
        input  wire [4:0] rf_waW,

        output reg  [1:0] fwd_a,
        output reg  [1:0] fwd_b
    );

    always @ (*) begin
        // Default: no forwarding.
        fwd_a = 2'b00;
        fwd_b = 2'b00;

        // EX/MEM -> EX (highest priority).
        if (we_regM && (rf_waM != 5'd0) && (rf_waM == rsE))
            fwd_a = 2'b10;
        if (we_regM && (rf_waM != 5'd0) && (rf_waM == rtE))
            fwd_b = 2'b10;

        // MEM/WB -> EX (only if not already forwarding EX/MEM).
        if (we_regW && (rf_waW != 5'd0) && (rf_waW == rsE) &&
            !(we_regM && (rf_waM != 5'd0) && (rf_waM == rsE)))
            fwd_a = 2'b01;
        if (we_regW && (rf_waW != 5'd0) && (rf_waW == rtE) &&
            !(we_regM && (rf_waM != 5'd0) && (rf_waM == rtE)))
            fwd_b = 2'b01;
    end
endmodule
