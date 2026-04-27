`timescale 1ns/1ps
// =============================================================================
//  5-Stage Pipelined MIPS Datapath  (CMPE 140 Lab 8)
//
//  Stages:  IF -> ID -> EX -> MEM -> WB
//  Pipeline registers inline:  if_id / id_ex / ex_mem / mem_wb
//
//  Control flow:
//    - J / JAL    : resolved in ID (1-slot penalty - flush IF).
//    - BEQ / JR   : resolved in EX (2-slot penalty - flush IF and ID).
//
//  Hazards:
//    - Load-use   : 1-cycle stall via hazard_unit (freeze PC + IF/ID, bubble ID/EX).
//    - Other RAW  : forwarding_unit drives EX-stage muxes (EX/MEM, MEM/WB -> EX).
//    - HI/LO      : no forwarding needed; written in MEM, read in WB.
//    - Reg file   : same-cycle WB->ID handled inside regfile_pipe.
// =============================================================================
module datapath_pipe (
        input  wire        clk,
        input  wire        rst,
        input  wire [4:0]  ra3,                // debug read port
        input  wire [31:0] instr_from_imem,
        input  wire [31:0] rd_dm,

        output wire        we_dm,
        output wire [31:0] dm_addr,
        output wire [31:0] wd_dm,
        output wire [31:0] pc_current,
        output wire [31:0] instrD_out,         // instr currently in ID  (debug)
        output wire [31:0] instrE_out,         // instr currently in EX  (debug)
        output wire [31:0] instrM_out,         // instr currently in MEM (debug)
        output wire [31:0] instrW_out,         // instr currently in WB  (debug)
        output wire [31:0] alu_outM_dbg,
        output wire [31:0] rd3
    );

    // =========================================================================
    //  IF stage
    // =========================================================================
    reg  [31:0] PC;
    wire [31:0] pc_plus4 = PC + 32'd4;

    // =========================================================================
    //  IF/ID
    // =========================================================================
    reg  [31:0] instrD, pc_plus4D;

    // =========================================================================
    //  ID stage
    // =========================================================================
    wire        jumpD, jalD;
    wire [3:0]  c_alu_ctrl;
    wire        c_alu_src;
    wire [1:0]  c_reg_dst;
    wire        c_branch;
    wire        c_jr;
    wire        c_shift_sel;
    wire        c_we_dm;
    wire        c_hilo_we;
    wire        c_we_reg;
    wire [2:0]  c_wd_rf_sel;

    controlunit_pipe cu (
        .opcode     (instrD[31:26]),
        .funct      (instrD[5:0]),
        .jumpD      (jumpD),
        .jalD       (jalD),
        .alu_ctrlE  (c_alu_ctrl),
        .alu_srcE   (c_alu_src),
        .reg_dstE   (c_reg_dst),
        .branchE    (c_branch),
        .jrE        (c_jr),
        .shift_selE (c_shift_sel),
        .we_dmM     (c_we_dm),
        .hilo_weM   (c_hilo_we),
        .we_regW    (c_we_reg),
        .wd_rf_selW (c_wd_rf_sel)
    );

    wire [4:0]  rsD = instrD[25:21];
    wire [4:0]  rtD = instrD[20:16];
    wire [4:0]  rdD = instrD[15:11];

    // regfile write from WB (declared later)
    wire        we_regW_final;
    wire [4:0]  rf_waW;
    wire [31:0] wd_rfW;

    wire [31:0] rd1D, rd2D;
    regfile_pipe rf (
        .clk (clk),
        .rst (rst),
        .we  (we_regW_final),
        .ra1 (rsD),
        .ra2 (rtD),
        .ra3 (ra3),
        .wa  (rf_waW),
        .wd  (wd_rfW),
        .rd1 (rd1D),
        .rd2 (rd2D),
        .rd3 (rd3)
    );

    wire [31:0] sext_immD;
    signext_pipe se (.a (instrD[15:0]), .y (sext_immD));

    wire [31:0] jta_D = {pc_plus4D[31:28], instrD[25:0], 2'b00};

    // =========================================================================
    //  ID/EX register + EX-stage state
    // =========================================================================
    reg  [31:0] instrE, pc_plus4E;
    reg  [31:0] rd1E, rd2E, sext_immE;
    reg  [4:0]  rsE, rtE, rdE;

    reg  [3:0]  alu_ctrlE;
    reg         alu_srcE;
    reg  [1:0]  reg_dstE;
    reg         branchE;
    reg         jrE;
    reg         shift_selE;

    // control signals carried forward
    reg         we_dmM_sig;
    reg         hilo_weM_sig;
    reg         we_regW_sig;
    reg  [2:0]  wd_rf_selW_sig;

    // =========================================================================
    //  EX/MEM register
    // =========================================================================
    reg  [31:0] instrM;
    reg  [31:0] alu_outM;
    reg  [31:0] wd_dmM;            // rt value (for SW data)
    reg  [63:0] mult_outM;
    reg  [31:0] pc_plus4M;
    reg  [4:0]  rf_waM;
    reg         we_dmM_reg;
    reg         hilo_weM_reg;
    reg         we_regW_M_reg;
    reg  [2:0]  wd_rf_selW_M_reg;

    // =========================================================================
    //  MEM/WB register
    // =========================================================================
    reg  [31:0] instrW;
    reg  [31:0] alu_outW;
    reg  [31:0] rd_dmW;
    reg  [31:0] pc_plus4W;
    reg  [31:0] hiW, loW;
    reg  [4:0]  rf_waW_reg;
    reg         we_regW_reg;
    reg  [2:0]  wd_rf_selW_W;

    // =========================================================================
    //  Hazard (load-use) detection
    // =========================================================================
    wire lw_inE    = we_regW_sig && (wd_rf_selW_sig == 3'b001);
    wire stall;
    hazard_unit hu (
        .lw_inE (lw_inE),
        .rtE    (rtE),
        .rsD    (rsD),
        .rtD    (rtD),
        .stall  (stall)
    );

    // =========================================================================
    //  Forwarding unit
    // =========================================================================
    wire [1:0] fwd_a, fwd_b;
    forwarding_unit fu (
        .rsE     (rsE),
        .rtE     (rtE),
        .we_regM (we_regW_M_reg),
        .rf_waM  (rf_waM),
        .we_regW (we_regW_reg),
        .rf_waW  (rf_waW_reg),
        .fwd_a   (fwd_a),
        .fwd_b   (fwd_b)
    );

    // WB-stage write-back data mux  (wd_rfW).  Also used as the MEM/WB
    // forwarding source into EX.
    wire [31:0] wd_rfW_mux = (wd_rf_selW_W == 3'b001) ? rd_dmW  :
                             (wd_rf_selW_W == 3'b010) ? hiW     :
                             (wd_rf_selW_W == 3'b011) ? loW     :
                             (wd_rf_selW_W == 3'b100) ? pc_plus4W :
                                                         alu_outW;

    // Forwarded EX operands
    wire [31:0] alu_src_a_fwd = (fwd_a == 2'b10) ? alu_outM :
                                (fwd_a == 2'b01) ? wd_rfW_mux :
                                                    rd1E;
    wire [31:0] alu_src_b_fwd = (fwd_b == 2'b10) ? alu_outM :
                                (fwd_b == 2'b01) ? wd_rfW_mux :
                                                    rd2E;

    // Shift shamt trick: feed instruction word into ALU A for SLL/SRL
    wire [31:0] alu_a_in = shift_selE ? instrE : alu_src_a_fwd;
    // ALU B: sign-ext imm or forwarded rt
    wire [31:0] alu_b_in = alu_srcE    ? sext_immE : alu_src_b_fwd;

    wire        alu_zeroE;
    wire [31:0] alu_yE;
    alu_pipe alu (
        .op   (alu_ctrlE),
        .a    (alu_a_in),
        .b    (alu_b_in),
        .zero (alu_zeroE),
        .y    (alu_yE)
    );

    wire [63:0] mult_outE;
    multiplier_pipe mult (
        .a (alu_src_a_fwd),
        .b (alu_src_b_fwd),
        .y (mult_outE)
    );

    // Branch target / JR target
    wire [31:0] bta_E     = pc_plus4E + {sext_immE[29:0], 2'b00};
    wire [31:0] jr_target = alu_src_a_fwd;

    // Write-register selection (EX -> EX/MEM)
    wire [4:0] rf_waE = (reg_dstE == 2'b10) ? 5'd31 :    // JAL
                        (reg_dstE == 2'b01) ? rdE    :    // R-type
                                              rtE;        // I-type (ADDI/LW)

    // =========================================================================
    //  HI/LO register  (written in MEM stage by MULTU, read in WB)
    // =========================================================================
    wire [31:0] hi_out, lo_out;
    hilo_reg_pipe hilo (
        .clk (clk),
        .rst (rst),
        .we  (hilo_weM_reg),
        .d   (mult_outM),
        .hi  (hi_out),
        .lo  (lo_out)
    );

    // =========================================================================
    //  Control-flow redirect + flush/stall
    // =========================================================================
    wire        ex_redirect = (branchE && alu_zeroE) || jrE;
    wire        id_redirect = jumpD;

    wire [31:0] pc_next = ex_redirect ? (jrE ? jr_target : bta_E) :
                          id_redirect ?  jta_D :
                                         pc_plus4;

    wire pc_hold     = stall && !ex_redirect;
    wire ifid_hold   = stall && !ex_redirect;
    wire flush_ifid  = ex_redirect || (id_redirect && !ex_redirect);
    wire bubble_idex = ex_redirect || stall;

    // =========================================================================
    //  Outputs to imem/dmem and debug
    // =========================================================================
    assign we_dm        = we_dmM_reg;
    assign dm_addr      = alu_outM;
    assign wd_dm        = wd_dmM;
    assign pc_current   = PC;

    assign instrD_out   = instrD;
    assign instrE_out   = instrE;
    assign instrM_out   = instrM;
    assign instrW_out   = instrW;
    assign alu_outM_dbg = alu_outM;

    // WB stage output (writeback into regfile)
    assign wd_rfW        = wd_rfW_mux;
    assign rf_waW        = rf_waW_reg;
    assign we_regW_final = we_regW_reg;

    // =========================================================================
    //  Sequential: every pipeline register and the PC
    // =========================================================================
    integer i;
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            PC             <= 32'h0;

            instrD         <= 32'h0;
            pc_plus4D      <= 32'h0;

            instrE         <= 32'h0;
            pc_plus4E      <= 32'h0;
            rd1E           <= 32'h0;
            rd2E           <= 32'h0;
            sext_immE      <= 32'h0;
            rsE            <= 5'h0;
            rtE            <= 5'h0;
            rdE            <= 5'h0;
            alu_ctrlE      <= 4'h0;
            alu_srcE       <= 1'b0;
            reg_dstE       <= 2'h0;
            branchE        <= 1'b0;
            jrE            <= 1'b0;
            shift_selE     <= 1'b0;
            we_dmM_sig     <= 1'b0;
            hilo_weM_sig   <= 1'b0;
            we_regW_sig    <= 1'b0;
            wd_rf_selW_sig <= 3'h0;

            instrM            <= 32'h0;
            alu_outM          <= 32'h0;
            wd_dmM            <= 32'h0;
            mult_outM         <= 64'h0;
            pc_plus4M         <= 32'h0;
            rf_waM            <= 5'h0;
            we_dmM_reg        <= 1'b0;
            hilo_weM_reg      <= 1'b0;
            we_regW_M_reg     <= 1'b0;
            wd_rf_selW_M_reg  <= 3'h0;

            instrW        <= 32'h0;
            alu_outW      <= 32'h0;
            rd_dmW        <= 32'h0;
            pc_plus4W     <= 32'h0;
            hiW           <= 32'h0;
            loW           <= 32'h0;
            rf_waW_reg    <= 5'h0;
            we_regW_reg   <= 1'b0;
            wd_rf_selW_W  <= 3'h0;
        end else begin
            // -------------------- PC --------------------
            if (!pc_hold) PC <= pc_next;

            // -------------------- IF/ID -----------------
            if (!ifid_hold) begin
                if (flush_ifid) begin
                    instrD    <= 32'h0;
                    pc_plus4D <= 32'h0;
                end else begin
                    instrD    <= instr_from_imem;
                    pc_plus4D <= pc_plus4;
                end
            end

            // -------------------- ID/EX -----------------
            if (bubble_idex) begin
                instrE         <= 32'h0;
                pc_plus4E      <= 32'h0;
                rd1E           <= 32'h0;
                rd2E           <= 32'h0;
                sext_immE      <= 32'h0;
                rsE            <= 5'h0;
                rtE            <= 5'h0;
                rdE            <= 5'h0;
                alu_ctrlE      <= 4'h0;
                alu_srcE       <= 1'b0;
                reg_dstE       <= 2'h0;
                branchE        <= 1'b0;
                jrE            <= 1'b0;
                shift_selE     <= 1'b0;
                we_dmM_sig     <= 1'b0;
                hilo_weM_sig   <= 1'b0;
                we_regW_sig    <= 1'b0;
                wd_rf_selW_sig <= 3'h0;
            end else begin
                instrE         <= instrD;
                pc_plus4E      <= pc_plus4D;
                rd1E           <= rd1D;
                rd2E           <= rd2D;
                sext_immE      <= sext_immD;
                rsE            <= rsD;
                rtE            <= rtD;
                rdE            <= rdD;
                alu_ctrlE      <= c_alu_ctrl;
                alu_srcE       <= c_alu_src;
                reg_dstE       <= c_reg_dst;
                branchE        <= c_branch;
                jrE            <= c_jr;
                shift_selE     <= c_shift_sel;
                we_dmM_sig     <= c_we_dm;
                hilo_weM_sig   <= c_hilo_we;
                we_regW_sig    <= c_we_reg;
                wd_rf_selW_sig <= c_wd_rf_sel;
            end

            // -------------------- EX/MEM ----------------
            instrM            <= instrE;
            alu_outM          <= alu_yE;
            wd_dmM            <= alu_src_b_fwd;  // forwarded rt for SW
            mult_outM         <= mult_outE;
            pc_plus4M         <= pc_plus4E;
            rf_waM            <= rf_waE;
            we_dmM_reg        <= we_dmM_sig;
            hilo_weM_reg      <= hilo_weM_sig;
            we_regW_M_reg     <= we_regW_sig;
            wd_rf_selW_M_reg  <= wd_rf_selW_sig;

            // -------------------- MEM/WB ----------------
            instrW        <= instrM;
            alu_outW      <= alu_outM;
            rd_dmW        <= rd_dm;
            pc_plus4W     <= pc_plus4M;
            hiW           <= hi_out;
            loW           <= lo_out;
            rf_waW_reg    <= rf_waM;
            we_regW_reg   <= we_regW_M_reg;
            wd_rf_selW_W  <= wd_rf_selW_M_reg;
        end
    end
endmodule
