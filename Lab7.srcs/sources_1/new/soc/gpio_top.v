module gpio_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [1:0]  a,      // offset: 0x0=sw, 0x4=leds (not used directly, mapped via bridge)
    input  wire [31:0] wd,
    input  wire [3:0]  sw_in,
    output wire [31:0] rd,
    output reg  [31:0] display_reg
);
    // Write LED register
    always @(posedge clk) begin
        if (rst) begin
            display_reg <= 32'h0;
        end else if (we) begin
            display_reg <= wd;
        end
    end

    // Read switches
    assign rd = {28'h0, sw_in};

endmodule
