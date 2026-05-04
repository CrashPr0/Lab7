`timescale 1ns/1ps

module debounce_pulse (
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  pulse_out
);
    // Simple 2-stage synchronizer
    reg sync_0, sync_1;
    always @(posedge clk) begin
        sync_0 <= btn_in;
        sync_1 <= sync_0;
    end

    // Shift register for debouncing (requires button to be high for 16 consecutive clock cycles)
    // This is extremely robust against noisy mechanical switches and won't get "stuck"
    reg [15:0] shift_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 16'b0;
        end else begin
            shift_reg <= {shift_reg[14:0], sync_1};
        end
    end

    wire btn_stable_high = (shift_reg == 16'hFFFF);
    
    // Pulse generator
    reg btn_prev;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_prev <= 1'b0;
            pulse_out <= 1'b0;
        end else begin
            btn_prev <= btn_stable_high;
            pulse_out <= (btn_stable_high && !btn_prev);
        end
    end
endmodule
