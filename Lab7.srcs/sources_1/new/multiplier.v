module multiplier (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] y
);
    assign y = a * b;
endmodule