`timescale 1ns / 1ps
`include "defines.v"

module frontend_ctrl #(
    parameter integer BR_PRED_INDEX_BITS = `BR_PRED_INDEX_BITS,
    parameter integer BR_PRED_PC_CANON_BITS = `BR_PRED_PC_CANON_BITS
)(
    input  wire [31:0] if_instr,
    input  wire [31:0] if_instr_addr,
    input  wire        if_jtb_hit,
    input  wire [31:0] if_jtb_target,
    input  wire        if_branch_hit,
    input  wire        if_branch_pred_taken,

    input  wire [31:0] if_pre_instr,
    input  wire [31:0] if_pre_instr_addr,
    input  wire        if_pre_jtb_hit,
    input  wire [31:0] if_pre_jtb_target,
    input  wire        if_pre_branch_hit,
    input  wire        if_pre_branch_pred_taken,
    input  wire        if_pre_valid,

    input  wire        ras_valid,
    input  wire [14:0] ras_top_target_low,
    input  wire        ras_slot1_valid_shadow,
    input  wire [14:0] ras_slot1_top_target_shadow_low,

    input  wire        pipeline_block_if,
    input  wire        frontend_redirect_kill_q,
    input  wire        ex_mispredict,
    input  wire [14:0] ex_redirect_addr,

    output wire        if_is_b,
    output wire        if_is_call,
    output wire        if_is_ret,
    output wire [31:0] if_b_imm,
    output wire [BR_PRED_INDEX_BITS-1:0] if_branch_hash,
    output wire        if_branch_pred_taken_eff,
    output wire        if_pred_taken_eff,
    output wire [31:0] if_pred_target_eff,

    output wire        if_pre_is_b,
    output wire        if_pre_is_call,
    output wire        if_pre_is_ret,
    output wire [BR_PRED_INDEX_BITS-1:0] if_pre_branch_hash,
    output wire        if_pre_pred_taken_eff,
    output wire [31:0] if_pre_pred_target_eff,

    output wire        frontend_issue_ok,
    output wire        slot0_jump_pred_base,
    output wire        slot0_ctrl_redirect,
    output wire        slot1_pred_redirect,
    output wire        frontend_redirect_flag,
    output wire [14:0] frontend_redirect_addr
);

    wire        if_is_jal;
    wire        if_is_jalr;
    wire [10:1] if_b_imm_lo;
    wire [14:0] if_b_target_low;
    wire [31:0] if_jal_imm;
    wire [14:0] if_jal_target_low;
    wire        if_jalr_pred_hit;
    wire [14:0] if_jalr_pred_target_low;
    wire [14:0] if_pred_target_low;
    wire        slot0_ctrl_pred_base;
    wire        slot1_pred_base;

    wire        if_pre_is_jal;
    wire        if_pre_is_jalr;
    wire [10:1] if_pre_b_imm_lo;
    wire [31:0] if_pre_b_imm;
    wire [14:0] if_pre_b_target_low;
    wire        if_pre_branch_pred_taken_eff;
    wire [31:0] if_pre_jal_imm;
    wire [14:0] if_pre_jal_target_low;
    wire        if_pre_jalr_pred_hit;
    wire [14:0] if_pre_jalr_pred_target_low;
    wire [14:0] if_pre_pred_target_low;

    assign if_is_b               = (if_instr[6:2] == 5'b11000);
    assign if_is_jal             = (if_instr[6:2] == 5'b11011);
    assign if_is_jalr            = (if_instr[6:2] == 5'b11001);
    assign if_is_call            = (if_is_jal || if_is_jalr)
                                 && ((if_instr[11:7] == 5'd1) || (if_instr[11:7] == 5'd5));
    assign if_is_ret             = if_is_jalr
                                 && (if_instr[11:7] == 5'd0)
                                 && ((if_instr[19:15] == 5'd1) || (if_instr[19:15] == 5'd5))
                                 && (if_instr[31:20] == 12'b0);
    assign if_b_imm_lo           = {if_instr[7], if_instr[30:25], if_instr[11:8]};
    assign if_b_imm              = {{20{if_instr[31]}}, if_b_imm_lo, 1'b0};
    assign if_b_target_low       = if_instr_addr[14:0] + if_b_imm[14:0];
    assign if_branch_pred_taken_eff = if_branch_hit ? if_branch_pred_taken : if_b_imm[31];
    assign if_jal_imm            = {{12{if_instr[31]}}, if_instr[19:12], if_instr[20], if_instr[30:21], 1'b0};
    assign if_jal_target_low     = if_instr_addr[14:0] + if_jal_imm[14:0];
    assign if_jalr_pred_hit      = if_is_ret ? ras_valid : if_jtb_hit;
    assign if_jalr_pred_target_low = if_is_ret ? ras_top_target_low : if_jtb_target[14:0];
    assign if_pred_target_low    = if_is_jal ? if_jal_target_low
                                  : (if_is_jalr ? if_jalr_pred_target_low
                                  : (if_is_b ? if_b_target_low : 15'b0));
    assign if_pred_target_eff    = {17'b0, if_pred_target_low};

    assign if_pre_is_b           = (if_pre_instr[6:2] == 5'b11000);
    assign if_pre_is_jal         = (if_pre_instr[6:2] == 5'b11011);
    assign if_pre_is_jalr        = (if_pre_instr[6:2] == 5'b11001);
    assign if_pre_b_imm_lo       = {if_pre_instr[7], if_pre_instr[30:25], if_pre_instr[11:8]};
    assign if_pre_b_imm          = {{20{if_pre_instr[31]}}, if_pre_b_imm_lo, 1'b0};
    assign if_pre_b_target_low   = if_pre_instr_addr[14:0] + if_pre_b_imm[14:0];
    assign if_pre_branch_pred_taken_eff = if_pre_branch_hit ? if_pre_branch_pred_taken : if_pre_b_imm[31];
    assign if_pre_is_call        = if_pre_is_jalr
                                 && ((if_pre_instr[11:7] == 5'd1) || (if_pre_instr[11:7] == 5'd5));
    assign if_pre_is_ret         = if_pre_is_jalr
                                 && (if_pre_instr[11:7] == 5'd0)
                                 && ((if_pre_instr[19:15] == 5'd1) || (if_pre_instr[19:15] == 5'd5))
                                 && (if_pre_instr[31:20] == 12'b0);
    assign if_pre_jal_imm        = {{12{if_pre_instr[31]}}, if_pre_instr[19:12], if_pre_instr[20], if_pre_instr[30:21], 1'b0};
    assign if_pre_jal_target_low = if_pre_instr_addr[14:0] + if_pre_jal_imm[14:0];
    assign if_pre_jalr_pred_hit  = if_pre_is_ret ? ras_slot1_valid_shadow
                                  : (if_pre_is_call ? if_pre_jtb_hit : 1'b0);
    assign if_pre_jalr_pred_target_low = if_pre_is_ret ? ras_slot1_top_target_shadow_low
                                         : if_pre_jtb_target[14:0];
    assign if_pre_pred_taken_eff = if_pre_is_jal ? 1'b1
                                  : (if_pre_is_jalr ? if_pre_jalr_pred_hit
                                  : (if_pre_is_b ? if_pre_branch_pred_taken_eff : 1'b0));
    assign if_pre_pred_target_low= if_pre_is_jal ? if_pre_jal_target_low
                                  : (if_pre_is_jalr ? if_pre_jalr_pred_target_low
                                  : (if_pre_is_b ? if_pre_b_target_low : 15'b0));
    assign if_pre_pred_target_eff= {17'b0, if_pre_pred_target_low};

    assign frontend_issue_ok      = !pipeline_block_if && !frontend_redirect_kill_q;
    assign slot0_jump_pred_base   = if_is_jal || (if_is_jalr && if_jalr_pred_hit);
    assign slot0_ctrl_pred_base   = slot0_jump_pred_base || if_branch_pred_taken_eff;
    assign slot1_pred_base        = if_pre_valid && if_pre_pred_taken_eff;
    assign slot0_ctrl_redirect    = frontend_issue_ok && slot0_ctrl_pred_base;
    assign slot1_pred_redirect    = frontend_issue_ok && slot1_pred_base;
    assign if_pred_taken_eff      = slot0_ctrl_redirect;
    assign frontend_redirect_flag = ex_mispredict | slot0_ctrl_redirect | slot1_pred_redirect;
    assign frontend_redirect_addr = ex_mispredict        ? ex_redirect_addr
                                  : slot0_ctrl_redirect ? if_pred_target_low
                                  :                       if_pre_pred_target_low;

    branch_hash_mix #(
        .INDEX_BITS    (BR_PRED_INDEX_BITS),
        .PC_CANON_BITS (BR_PRED_PC_CANON_BITS)
    ) u_if_branch_hash (
        .pc_value    (if_instr_addr),
        .imm_lo_value(if_b_imm_lo),
        .hash_value  (if_branch_hash)
    );

    branch_hash_mix #(
        .INDEX_BITS    (BR_PRED_INDEX_BITS),
        .PC_CANON_BITS (BR_PRED_PC_CANON_BITS)
    ) u_if_pre_branch_hash (
        .pc_value    (if_pre_instr_addr),
        .imm_lo_value(if_pre_b_imm_lo),
        .hash_value  (if_pre_branch_hash)
    );

endmodule
