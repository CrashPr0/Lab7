`timescale 1ns/1ps

module tb_soc_pipe;
    reg clk;
    reg rst;
    reg [3:0] sw_in;
    wire [31:0] display_out;
    wire [31:0] pc;

    soc_top_pipe dut (
        .clk         (clk),
        .rst         (rst),
        .sw_in       (sw_in),
        .ra3         (5'd0),
        .rd3         (),
        .pc_current  (pc),
        .display_out (display_out)
    );

    // 10ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Correct hierarchical paths for Vivado XSim
    // The regfile array is named 'rf' in regfile_pipe.v
    wire [31:0] v0 = dut.dp.rf.rf[2];
    wire [31:0] a0 = dut.dp.rf.rf[4];
    wire [31:0] fact_res = dut.fact.core.product;
    wire        fact_done = dut.fact.core.done;

    initial begin
        $display("--- SOC Simulation Start (N=5) ---");
        rst = 1;
        sw_in = 4'd5; 
        #22;
        rst = 0;

        // Monitor every 10 cycles
        repeat (100) begin
            #100;
            $display("[Time %0t] PC=%h | $a0=%d | $v0=%d | FactDone=%b | FactRes=%d | Display=%d", 
                     $time, pc, a0, v0, fact_done, fact_res, display_out);
            
            if (pc == 32'h0000003c && display_out == 32'd120) begin
                $display("--- SUCCESS: 5! = 120 found on Display ---");
                $finish;
            end
        end

        $display("--- FAILURE: Timeout or Incorrect Result ---");
        $finish;
    end
endmodule
