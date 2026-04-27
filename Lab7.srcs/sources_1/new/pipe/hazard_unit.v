`timescale 1ns/1ps
// Load-use hazard detection.
// If the instruction in EX is a LW whose rt is consumed by the instruction in ID,
// stall by one cycle: freeze PC and IF/ID, and inject a bubble into ID/EX.
module hazard_unit (
        input  wire       lw_inE,        // 1 if instruction currently in EX is a LW
        input  wire [4:0] rtE,           // LW destination register (rt)

        input  wire [4:0] rsD,
        input  wire [4:0] rtD,

        output wire       stall
    );

    assign stall = lw_inE && (rtE != 5'd0) &&
                   ((rtE == rsD) || (rtE == rtD));
endmodule
