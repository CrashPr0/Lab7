`timescale 1ns/1ps

module disp_hex_mux (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] hex_in,
    output wire [3:0]  an,      // Anodes (LEDSEL)
    output wire [7:0]  sseg     // Cathodes (LEDOUT)
);

    // Dummy wire to suppress synthesis warning about unconnected upper 16 bits
    wire [15:0] unused_hex_in = hex_in[31:16];

    // Refresh rate counter
    // 100 MHz clock divided down to ~1 kHz refresh rate per digit
    reg [19:0] q_reg;
    wire [19:0] q_next;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    assign q_next = q_reg + 1;

    // Use top 2 bits of the counter to select the active digit
    wire [1:0] sel = q_reg[19:18];
    reg [3:0] hex_digit;
    reg [3:0] an_reg;

    // Multiplexer to select the 4-bit nibble from the 32-bit input
    // We only care about the bottom 16 bits (4 hex digits) for the Basys3 display
    always @* begin
        case (sel)
            2'b00: begin
                an_reg = 4'b1110;       // Enable rightmost digit
                hex_digit = hex_in[3:0];
            end
            2'b01: begin
                an_reg = 4'b1101;       // Enable 2nd digit from right
                hex_digit = hex_in[7:4];
            end
            2'b10: begin
                an_reg = 4'b1011;       // Enable 3rd digit from right
                hex_digit = hex_in[11:8];
            end
            2'b11: begin
                an_reg = 4'b0111;       // Enable leftmost digit
                hex_digit = hex_in[15:12];
            end
        endcase
    end

    assign an = an_reg;

    // Hex to 7-segment decoder (Active Low Cathodes)
    reg [6:0] sseg_reg;
    always @* begin
        case (hex_digit)
            4'h0: sseg_reg = 7'b1000000;
            4'h1: sseg_reg = 7'b1111001;
            4'h2: sseg_reg = 7'b0100100;
            4'h3: sseg_reg = 7'b0110000;
            4'h4: sseg_reg = 7'b0011001;
            4'h5: sseg_reg = 7'b0010010;
            4'h6: sseg_reg = 7'b0000010;
            4'h7: sseg_reg = 7'b1111000;
            4'h8: sseg_reg = 7'b0000000;
            4'h9: sseg_reg = 7'b0010000;
            4'ha: sseg_reg = 7'b0001000;
            4'hb: sseg_reg = 7'b0000011;
            4'hc: sseg_reg = 7'b1000110;
            4'hd: sseg_reg = 7'b0100001;
            4'he: sseg_reg = 7'b0000110;
            4'hf: sseg_reg = 7'b0001110;
            default: sseg_reg = 7'b1111111; // Blank if unknown
        endcase
    end

    // Concatenate the 7 segments with the Decimal Point (DP) set to off (high)
    assign sseg = {1'b1, sseg_reg};

endmodule
