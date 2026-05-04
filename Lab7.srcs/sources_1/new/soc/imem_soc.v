`timescale 1ns/1ps

module imem_soc (
    input  wire [5:0]  a,
    output wire [31:0] y
);
    // Hard-coded Instruction ROM
    // This removes the need for memfile_soc.dat and guarantees the program is loaded.
    wire [31:0] rom [0:63];

    assign rom[0]  = 32'h20080800; // addi $t0, $0, 0x0800 (GPIO Base)
    assign rom[1]  = 32'h20090a00; // addi $t1, $0, 0x0a00 (Fact Base)
    assign rom[2]  = 32'h200c0900; // addi $t4, $0, 0x0900 (Display Base)
    assign rom[3]  = 32'h200d0001; // addi $t5, $0, 1      (Constant 1)
    
    // wait_for_btn:
    assign rom[4]  = 32'h8d0a0008; // lw   $t2, 8($t0)
    assign rom[5]  = 32'h014d5024; // and  $t2, $t2, $t5
    assign rom[6]  = 32'h1140fffd; // beq  $t2, $0, wait_for_btn
    
    assign rom[7]  = 32'h8d040000; // lw   $a0, 0($t0) (Read switches)
    assign rom[8]  = 32'had000008; // sw   $0, 8($t0)  (Clear button latch)
    assign rom[9]  = 32'had240004; // sw   $a0, 4($t1) (Write N to Fact)
    assign rom[10] = 32'h200a0001; // addi $t2, $0, 1
    assign rom[11] = 32'had2a0000; // sw   $t2, 0($t1) (Write Go=1)
    
    // poll_fact:
    assign rom[12] = 32'h8d2b0000; // lw   $t3, 0($t1)
    assign rom[13] = 32'h016d5824; // and  $t3, $t3, $t5
    assign rom[14] = 32'h1160fffd; // beq  $t3, $0, poll_fact
    
    assign rom[15] = 32'h8d220008; // lw   $v0, 8($t1) (Read Result)
    assign rom[16] = 32'had820000; // sw   $v0, 0($t4) (Display Result)
    assign rom[17] = 32'h08000004; // j    wait_for_btn
    
    // Fill remaining ROM with NOPs
    generate
        genvar i;
        for (i = 18; i < 64; i = i + 1) begin
            assign rom[i] = 32'h0;
        end
    endgenerate

    assign y = rom[a];
endmodule
