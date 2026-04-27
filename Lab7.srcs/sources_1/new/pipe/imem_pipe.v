`timescale 1ns/1ps
// Instruction memory for pipelined MIPS.
// Reads program from hex file at simulation start.
module imem_pipe (
        input  wire [5:0]  a,          // word address (pc[7:2])
        output wire [31:0] y
    );

    reg [31:0] rom [0:63];

    initial begin
        // Change this path if you relocate the memfile.
        $readmemh ("C:/Users/iSchool Admin/Documents/factorial_vivado_project/vivado/Lab7/Lab7.srcs/sources_1/new/pipe/memfile_pipe.dat", rom);
    end

    assign y = rom[a];
endmodule
