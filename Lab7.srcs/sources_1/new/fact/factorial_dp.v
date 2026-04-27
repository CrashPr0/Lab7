module factorial_dp #(
    parameter integer N_W = 4,
    parameter integer P_W = 32
)(
    input  wire                 clk,
    input  wire                 rst,

    // control signals
    input  wire                 ld_n,
    input  wire                 en_n,
    input  wire                 ld_p,
    input  wire                 sel_p_init,

    // data input
    input  wire [N_W-1:0]       n_in,

    // status outputs
    output wire                 n_gt_1,
    output wire [N_W-1:0]       n_val,
    output wire [P_W-1:0]       product
);
    // Counter for n
    reg [N_W-1:0] n_reg;
    always @(posedge clk) begin
        if (rst) begin
            n_reg <= {N_W{1'b0}};
        end else if (ld_n) begin
            n_reg <= n_in;
        end else if (en_n) begin
            if (n_reg != {N_W{1'b0}})
                n_reg <= n_reg - {{(N_W-1){1'b0}},1'b1};
        end
    end
    assign n_val = n_reg;

    assign n_gt_1 = (n_reg > {{(N_W-1){1'b0}},1'b1});

    // Product register
    reg [P_W-1:0] p_reg;
    wire [P_W-1:0] mul_res;
    assign mul_res = p_reg * {{(P_W-N_W){1'b0}}, n_reg};

    wire [P_W-1:0] p_next = sel_p_init ? {{(P_W-1){1'b0}},1'b1} : mul_res;

    always @(posedge clk) begin
        if (rst) begin
            p_reg <= {{(P_W-1){1'b0}},1'b1};
        end else if (ld_p) begin
            p_reg <= p_next;
        end
    end
    assign product = p_reg;

endmodule
