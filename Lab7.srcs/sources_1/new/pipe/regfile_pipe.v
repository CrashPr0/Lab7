`timescale 1ns/1ps
// Register file for pipelined MIPS.
// Write on posedge in WB stage; read is combinational with internal WB->ID forwarding
// so an instruction in ID sees the value written by an instruction in WB in the same cycle.
module regfile_pipe (
        input  wire        clk,
        input  wire        rst,
        input  wire        we,
        input  wire [4:0]  ra1,
        input  wire [4:0]  ra2,
        input  wire [4:0]  ra3,
        input  wire [4:0]  wa,
        input  wire [31:0] wd,
        output wire [31:0] rd1,
        output wire [31:0] rd2,
        output wire [31:0] rd3
    );

    reg [31:0] rf [0:31];

    integer n;

    initial begin
        for (n = 0; n < 32; n = n + 1) rf[n] = 32'h0;
        rf[29] = 32'h100;       // $sp default (byte addr 0x100)
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            for (n = 0; n < 32; n = n + 1) rf[n] <= 32'h0;
            rf[29] <= 32'h100;
        end else if (we && (wa != 5'd0)) begin
            rf[wa] <= wd;
        end
    end

    // Combinational reads with WB->ID internal forwarding (same-cycle write visibility).
    assign rd1 = (ra1 == 5'd0)                        ? 32'd0 :
                 (we && (wa == ra1) && (wa != 5'd0))  ? wd    : rf[ra1];
    assign rd2 = (ra2 == 5'd0)                        ? 32'd0 :
                 (we && (wa == ra2) && (wa != 5'd0))  ? wd    : rf[ra2];
    assign rd3 = (ra3 == 5'd0)                        ? 32'd0 :
                 (we && (wa == ra3) && (wa != 5'd0))  ? wd    : rf[ra3];

endmodule
