`timescale 1ns/1ps
module dmem_pipe (
        input  wire        clk,
        input  wire        rst,
        input  wire        we,
        input  wire [5:0]  a,          // word address
        input  wire [31:0] d,
        output wire [31:0] q
    );

    reg [31:0] ram [0:63];

    integer n;

    initial begin
        for (n = 0; n < 64; n = n + 1) ram[n] = 32'hFFFFFFFF;
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            for (n = 0; n < 64; n = n + 1) ram[n] <= 32'hFFFFFFFF;
        end else if (we) begin
            ram[a] <= d;
        end
    end

    assign q = ram[a];
endmodule
