`timescale 1ns/1ps

module debounce_pulse (
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  pulse_out
);
    reg [19:0] count;
    reg btn_sync_0, btn_sync_1;
    reg btn_stable;

    // Synchronize the asynchronous button input
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // Debounce: Wait for button to be stable for ~10ms (1 million cycles at 100MHz)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            btn_stable <= 0;
        end else begin
            if (btn_sync_1 != btn_stable) begin
                count <= count + 1;
                if (count == 20'hFFFFF) begin
                    btn_stable <= btn_sync_1;
                    count <= 0;
                end
            end else begin
                count <= 0;
            end
        end
    end

    // Pulse Generator: Create a single clock cycle pulse on rising edge of stable button
    reg btn_prev;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_prev <= 0;
            pulse_out <= 0;
        end else begin
            btn_prev <= btn_stable;
            pulse_out <= (btn_stable && !btn_prev);
        end
    end
endmodule
