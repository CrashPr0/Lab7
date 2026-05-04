`timescale 1ns/1ps

module tb_soc;
    reg clk;
    reg rst;
    reg [3:0] sw_in;
    wire [31:0] display_out;

    // Instantiate the single-cycle SoC Top
    soc_top dut (
        .clk         (clk),
        .rst         (rst),
        .sw_in       (sw_in),
        .display_out (display_out)
    );

    // 10ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Signals for monitoring
    wire [31:0] pc = dut.pc_current;
    wire [31:0] fact_res = dut.fact.core.product;
    wire        fact_done = dut.fact.core.done;

    initial begin
        $display("--- Single-Cycle SOC Simulation Start (N=5) ---");
        rst = 1;
        sw_in = 4'd5; // Calculate 5!
        #22;
        rst = 0;

        // Monitor every 10 cycles
        repeat (100) begin
            #100;
            $display("[Time %0t] PC=%h | FactDone=%b | FactRes=%d | Display=%d", 
                     $time, pc, fact_done, fact_res, display_out);
            
            // If the assembly program hits the infinite loop and the display shows 120 (5!)
            if (pc == 32'h0000003c && display_out == 32'd120) begin
                $display("--- SUCCESS: 5! = 120 found on Display ---");
                $finish;
            end
        end

        $display("--- FAILURE: Timeout or Incorrect Result ---");
        $finish;
    end
endmodule
