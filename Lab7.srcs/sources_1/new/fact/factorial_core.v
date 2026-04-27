module factorial_core #(
    parameter integer N_W = 4,
    parameter integer P_W = 32
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 go,
    input  wire [N_W-1:0]       n,

    output wire [P_W-1:0]       product,
    output wire                 done,
    output wire                 error
);
    wire ld_n, en_n, ld_p, sel_p_init;
    wire n_gt_1;
    wire [N_W-1:0] n_val;

    factorial_dp #(.N_W(N_W), .P_W(P_W)) dp (
        .clk(clk), .rst(rst),
        .ld_n(ld_n), .en_n(en_n),
        .ld_p(ld_p), .sel_p_init(sel_p_init),
        .n_in(n),
        .n_gt_1(n_gt_1),
        .n_val(n_val),
        .product(product)
    );

    factorial_cu #(.N_W(N_W)) cu (
        .clk(clk), .rst(rst),
        .go(go), .n_in(n),
        .n_gt_1(n_gt_1),
        .ld_n(ld_n), .en_n(en_n), .ld_p(ld_p), .sel_p_init(sel_p_init),
        .done(done), .error(error)
    );

endmodule
