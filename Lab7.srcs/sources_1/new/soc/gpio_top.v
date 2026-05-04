module gpio_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [1:0]  a,      // offset: 0x0=sw, 0x4=leds, 0x8=button
    input  wire [31:0] wd,
    input  wire [3:0]  sw_in,
    input  wire        btn_pulse,
    output wire [31:0] rd,
    output reg  [31:0] display_reg
);
    reg btn_reg;

    // Latch the button pulse until the CPU reads it
    always @(posedge clk) begin
        if (rst) begin
            btn_reg <= 1'b0;
        end else if (btn_pulse) begin
            btn_reg <= 1'b1;
        end else if (we && (a == 2'b10)) begin // Clear on write to 0x808
            btn_reg <= 1'b0;
        end
    end

    // Write LED register
    always @(posedge clk) begin
        if (rst) begin
            display_reg <= 32'h0;
        end else if (we && (a == 2'b01)) begin
            display_reg <= wd;
        end
    end

    // Read logic
    assign rd = (a == 2'b00) ? {28'h0, sw_in} :
                (a == 2'b10) ? {31'h0, btn_reg} :
                32'h0;

endmodule
