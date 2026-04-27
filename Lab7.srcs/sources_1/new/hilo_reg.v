module hilo_reg (
    input  wire        clk,
    input  wire        we,
    input  wire [63:0] d,
    output wire [31:0] hi,
    output wire [31:0] lo
);
    reg [31:0] hi_reg;
    reg [31:0] lo_reg;

    always @(posedge clk) begin
        if (we) begin
            hi_reg <= d[63:32];
            lo_reg <= d[31:0];
        end
    end

    assign hi = hi_reg;
    assign lo = lo_reg;
endmodule