`timescale 1ns/1ps

module imem_soc (
    input  wire [5:0]  a,
    output wire [31:0] y
);
    reg [31:0] rom [0:63];

    initial begin
        $readmemh("C:/Users/iSchool Admin/Documents/factorial_vivado_project/vivado/Lab7/Lab7.srcs/sources_1/new/soc/memfile_soc.dat", rom);
    end

    assign y = rom[a];
endmodule
