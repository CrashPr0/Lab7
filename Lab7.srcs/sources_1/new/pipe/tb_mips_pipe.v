`timescale 1ns/1ps
// =============================================================================
//  Testbench for the pipelined MIPS (Lab 8, week 2 waveform demo)
//
//  Program: iterative factorial of 4  (expected result M[0] = 24 = 0x18).
//
//  Instructions exercised:
//    ADDI, BEQ, MULTU, MFLO, J, SW.
//  With forwarding between ADDI->MULTU and MFLO->ADDI back-to-back, this shows
//  hazard handling and the branch/jump flush behaviour.
//
//  Signals to add to waveform:
//    clk, rst, pc_current, instrD, instrE, instrM, instrW,
//    alu_outM, we_dm, wd_dm, rd3 (<- reads $v0 live via ra3=5'd2)
// =============================================================================
`timescale 1ns/1ps

module tb_mips_pipe;

    reg         clk;
    reg         rst;
    wire        we_dm;
    wire [31:0] pc_current;
    wire [31:0] instrD, instrE, instrM, instrW;
    wire [31:0] alu_outM;
    wire [31:0] wd_dm;
    wire [31:0] rd_dm;
    wire [31:0] rd3;

    // ra3 = 2 reads $v0 live from the regfile every cycle (debug tap).
    mips_top_pipe DUT (
        .clk        (clk),
        .rst        (rst),
        .ra3        (5'd2),
        .we_dm      (we_dm),
        .pc_current (pc_current),
        .instrD     (instrD),
        .instrE     (instrE),
        .instrM     (instrM),
        .instrW     (instrW),
        .alu_outM   (alu_outM),
        .wd_dm      (wd_dm),
        .rd_dm      (rd_dm),
        .rd3        (rd3)
    );

    // 10 ns clock (100 MHz)
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // Reset + run
    integer cycle_count;

    initial begin
        cycle_count = 0;
        rst = 1'b1;
        #22;                    // a few cycles of reset
        rst = 1'b0;

        // Run until PC parks on the 'end: j end' infinite loop (PC = 0x24)
        // or a safety cap of 200 cycles, whichever comes first.
        while (pc_current !== 32'h00000024 && cycle_count < 200) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        // Give the pipeline a few more cycles so the final SW is fully retired
        // and the last writeback settles.
        repeat (8) @(posedge clk);

        $display("========================================================");
        $display(" Pipelined MIPS simulation finished.");
        $display(" cycle_count   = %0d", cycle_count);
        $display(" final PC      = 0x%08h", pc_current);
        $display(" M[0] (live rd_dm when dm_addr==0) observed at run-time.");
        $display(" final $v0     = %0d   (expect 24 = 4!)", rd3);
        $display("========================================================");

        if (rd3 === 32'd24)
            $display("PASS: $v0 == 24");
        else
            $display("FAIL: $v0 = %0d, expected 24", rd3);

        $finish;
    end

    // Trace writes to data memory (very handy during sim)
    always @(posedge clk) begin
        if (we_dm) begin
            $display("[cycle %0d]  SW  dmem[%0d] <= 0x%08h",
                     cycle_count, alu_outM[7:2], wd_dm);
        end
    end
endmodule
