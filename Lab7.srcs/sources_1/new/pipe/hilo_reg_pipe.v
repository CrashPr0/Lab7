`timescale 1ns/1ps
module hilo_reg_pipe (
        input  wire        clk,
        input  wire        rst,
        input  wire        we,
        input  wire [63:0] d,
        output wire [31:0] hi,
        output wire [31:0] lo
    );
    reg [31:0] hi_reg;
    reg [31:0] lo_reg;

    initial begin
        hi_reg = 32'h0;
        lo_reg = 32'h0;
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            hi_reg <= 32'h0;
            lo_reg <= 32'h0;
        end else if (we) begin
            hi_reg <= d[63:32];
            lo_reg <= d[31:0];
        end
    end

    assign hi = hi_reg;
    assign lo = lo_reg;
endmodule
