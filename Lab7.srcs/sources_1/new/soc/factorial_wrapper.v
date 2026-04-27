module factorial_wrapper (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [2:0]  a,      // offset: 0x0=ctrl, 0x4=n, 0x8=res
    input  wire [31:0] wd,
    output reg  [31:0] rd
);
    reg [3:0] n_reg;
    reg       go_reg;

    wire [31:0] product;
    wire        done;
    wire        error;

    factorial_core core (
        .clk     (clk),
        .rst     (rst),
        .go      (go_reg),
        .n       (n_reg),
        .product (product),
        .done    (done),
        .error   (error)
    );

    // Control registers logic
    always @(posedge clk) begin
        if (rst) begin
            n_reg  <= 4'h0;
            go_reg <= 1'b0;
        end else if (we) begin
            case (a)
                3'b000: go_reg <= wd[0];
                3'b001: n_reg  <= wd[3:0];
                default: ;
            endcase
        end else begin
            // Auto-clear go_reg after 1 cycle to prevent double-start
            go_reg <= 1'b0;
        end
    end

    // Read logic
    always @(*) begin
        case (a)
            3'b000: rd = {30'h0, error, done};
            3'b010: rd = product;
            default: rd = 32'h0;
        endcase
    end

endmodule
