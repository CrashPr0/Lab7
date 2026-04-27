module factorial_cu #(
    parameter integer N_W = 4
)(
    input  wire           clk,
    input  wire           rst,     // synchronous, active-high
    input  wire           go,
    input  wire [N_W-1:0] n_in,

    // datapath status
    input  wire           n_gt_1,

    // datapath controls
    output reg            ld_n,
    output reg            en_n,
    output reg            ld_p,
    output reg            sel_p_init,

    // status outputs
    output reg            done,
    output reg            error
);

    // states
    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_CHECK  = 3'd2;
    localparam S_MUL    = 3'd3;
    localparam S_DEC    = 3'd4;
    localparam S_DONE   = 3'd5;
    localparam S_ERROR  = 3'd6;

    reg [2:0] state, state_n;

    // simple "n > 12" check (works for N_W>=4)
    wire n_gt_12 = (n_in > 4'd12);

    // next-state logic
    always @(*) begin
        state_n = state;
        case (state)
            S_IDLE:  if (go) state_n = S_LOAD;
            S_LOAD:  if (n_gt_12) state_n = S_ERROR;
                     else state_n = S_CHECK;
            S_CHECK: if (n_gt_1) state_n = S_MUL;
                     else state_n = S_DONE;
            S_MUL:   state_n = S_DEC;
            S_DEC:   state_n = S_CHECK;
            S_DONE:  if (!go) state_n = S_IDLE;
            S_ERROR: if (!go) state_n = S_IDLE;
            default: state_n = S_IDLE;
        endcase
    end

    // state register
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= state_n;
        end
    end

    // output logic
    always @(*) begin
        // defaults
        ld_n       = 1'b0;
        en_n       = 1'b0;
        ld_p       = 1'b0;
        sel_p_init = 1'b0;
        done       = 1'b0;
        error      = 1'b0;

        case (state)
            S_LOAD: begin
                ld_n       = 1'b1;  // load n into counter
                ld_p       = 1'b1;  // init product to 1
                sel_p_init = 1'b1;
            end
            S_MUL: begin
                ld_p       = 1'b1;  // product = product * n
                sel_p_init = 1'b0;
            end
            S_DEC: begin
                en_n       = 1'b1;  // n = n - 1
            end
            S_DONE: begin
                done       = 1'b1;
            end
            S_ERROR: begin
                error      = 1'b1;
            end
            default: begin
                // keep defaults
            end
        endcase
    end

endmodule
