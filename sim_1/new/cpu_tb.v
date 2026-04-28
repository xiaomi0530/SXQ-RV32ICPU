`timescale 1ns / 1ps
`include "../../sources_1/new/defines.v"

module cpu_tb;

    localparam BP_STATS_ENABLE = `TB_BP_STATS_ENABLE;
    localparam PERIODIC_STATS_ENABLE = `TB_PERIODIC_STATS_ENABLE;
    localparam [31:0] MMIO_TIMER_LO_ADDR = `MMIO_TIMER_LO_ADDR;
    localparam [31:0] MMIO_TIMER_HI_ADDR = `MMIO_TIMER_HI_ADDR;
    localparam [31:0] MMIO_INSTRET_LO_ADDR = `MMIO_INSTRET_LO_ADDR;
    localparam [31:0] MMIO_INSTRET_HI_ADDR = `MMIO_INSTRET_HI_ADDR;
    localparam integer BRANCH_PC_STAT_SLOTS = `TB_BRANCH_PC_STAT_SLOTS;
    localparam integer JALR_PC_STAT_SLOTS = `TB_JALR_PC_STAT_SLOTS;
    localparam integer SLOT1_TRACK_SLOTS = `TB_SLOT1_TRACK_SLOTS;
    localparam [2:0] SLOT1_TYPE_B = `TB_SLOT1_TYPE_B;
    localparam [2:0] SLOT1_TYPE_JAL = `TB_SLOT1_TYPE_JAL;
    localparam [2:0] SLOT1_TYPE_JALR = `TB_SLOT1_TYPE_JALR;
    localparam [2:0] SLOT1_TYPE_RET = `TB_SLOT1_TYPE_RET;
    localparam [2:0] SLOT1_TYPE_CALL_JALR = `TB_SLOT1_TYPE_CALL_JALR;
    localparam [2:0] SLOT1_TYPE_INDIRECT_JALR = `TB_SLOT1_TYPE_INDIRECT_JALR;
    localparam integer BHT_STAT_ENTRY_NUM  = `BR_PRED_ENTRY_NUM;
    localparam integer BHT_STAT_INDEX_BITS = `BR_PRED_INDEX_BITS;
    localparam integer BHT_STAT_PC_BITS    = `BR_PRED_PC_CANON_BITS;
    localparam integer BHT_STAT_TAG_BITS   = `BR_PRED_TAG_BITS;
    localparam integer TB_IMEM_PAD_BITS    = `CPU_ADDR_BITS - `IMEM_ADDR_BITS;
    localparam integer TB_CPU_FREQ_HZ      = `CPU_CLK_FREQ_HZ;
    localparam integer TB_CPU_FREQ_MHZ     = `CPU_CLK_FREQ_HZ / 1000000;
    localparam integer TB_DHRY_RUNS        = 1800;
    localparam integer UART_BENCH_PARSE_WAIT_C    = 0;
    localparam integer UART_BENCH_PARSE_WAIT_C_EQ = 1;
    localparam integer UART_BENCH_PARSE_CAP_C     = 2;
    localparam integer UART_BENCH_PARSE_WAIT_I    = 3;
    localparam integer UART_BENCH_PARSE_WAIT_I_EQ = 4;
    localparam integer UART_BENCH_PARSE_CAP_I     = 5;

    reg  clk;
    reg  rst_n;
    wire [15:0] led;

    integer dhry_key_pos;
    integer dhry_dps_accum;
    integer dhry_dps_value;
    reg     dhry_capture_active;
    reg     dhry_seen_digit;
    reg     dhry_dps_valid;
    integer uart_ipc_key_pos;
    integer uart_bench_parse_state;
    reg     uart_bench_c_seen_digit;
    reg     uart_bench_i_seen_digit;
    reg [63:0] uart_bench_c_accum;
    reg [63:0] uart_bench_i_accum;
    reg [63:0] uart_bench_cycle_value;
    reg [63:0] uart_bench_instret_value;
    reg     uart_bench_cycle_valid;
    reg     uart_bench_instret_valid;

    integer cycle_count;
    integer stat_cycle_total;
    integer timer_req_count;
    reg     stat_active;
    reg [63:0] tb_retire_total;
    reg        tb_wb_instret_hi_q;
    reg        tb_wb_instret_lo_q;
    integer    tb_instret_snap_state;
    integer    tb_instret_snap_count;
    reg        tb_instret_start_valid;
    reg        tb_instret_stop_valid;
    reg [63:0] tb_instret_start_retire;
    reg [63:0] tb_instret_stop_retire;

    integer instr_total;
    integer flush_total;
    integer load_stall_total;
    integer false_load_stall_total;
    integer lduse3_base_total;
    integer lduse3_i2_dep_i0_total;
    integer lduse3_i2_dep_i1_total;
    integer lduse3_i2_dep_both_total;
    integer mul_hold_total;
    integer other_bubble_total;
    integer wb_commit_total;
    integer branch_total;
    integer branch_taken_total;
    integer branch_both_taken_total;
    integer jal_total;
    integer jal_pred_total;
    integer jal_correct_total;
    integer jalr_total;
    integer jalr_pred_total;
    integer jalr_correct_total;
    integer ret_total;
    integer ret_pred_total;
    integer ret_correct_total;
    integer call_jalr_total;
    integer call_jalr_pred_total;
    integer call_jalr_correct_total;
    integer indirect_jalr_total;
    integer indirect_jalr_pred_total;
    integer indirect_jalr_correct_total;
    integer jalr_prev_wr_rs1_total;
    integer ret_prev_wr_rs1_total;
    integer call_jalr_prev_wr_rs1_total;
    integer indirect_jalr_prev_wr_rs1_total;
    integer auipc_jalr_total;
    integer auipc_ret_total;
    integer auipc_call_jalr_total;
    integer auipc_indirect_jalr_total;
    integer pred_taken_total;
    integer dir_correct_total;
    integer target_correct_total;
    integer mispredict_total;
    integer branch_miss_taken_total;
    integer branch_miss_nt_total;
    integer branch_hit_forward_total;
    integer branch_hit_backward_total;
    integer branch_miss_forward_total;
    integer branch_miss_backward_total;
    integer if_branch_hit_total;
    integer if_branch_nohit_total;
    integer if_branch_nohit_back_total;
    integer if_branch_nohit_back_ok_total;
    integer if_branch_nohit_back_redirect_total;
    integer slot1_redirect_total;
    integer slot1_branch_seen_total;
    integer slot1_branch_issue_total;
    integer slot1_branch_back_total;
    integer slot1_branch_issue_back_total;
    integer slot1_ctrl_track_total;
    integer slot1_ctrl_match_total;
    integer slot1_ctrl_drop_total;
    integer slot1_pred_effective_total;
    integer slot1_pred_without_valid_total;
    integer slot1_raw_invalid_total;
    integer slot1_b_exec_total;
    integer slot1_b_pred_total;
    integer slot1_b_correct_total;
    integer slot1_b_taken_total;
    integer slot1_b_nt_total;
    integer slot1_b_fwd_total;
    integer slot1_b_fwd_taken_total;
    integer slot1_b_fwd_nt_total;
    integer slot1_b_back_total;
    integer slot1_b_back_taken_total;
    integer slot1_b_back_nt_total;
    integer slot1_jal_exec_total;
    integer slot1_jal_pred_total;
    integer slot1_jal_correct_total;
    integer slot1_jalr_exec_total;
    integer slot1_jalr_pred_total;
    integer slot1_jalr_correct_total;
    integer slot1_ret_exec_total;
    integer slot1_ret_pred_total;
    integer slot1_ret_correct_total;
    integer slot1_call_jalr_exec_total;
    integer slot1_call_jalr_pred_total;
    integer slot1_call_jalr_correct_total;
    integer slot1_indirect_jalr_exec_total;
    integer slot1_indirect_jalr_pred_total;
    integer slot1_indirect_jalr_correct_total;
    integer bht_tag_alias_total;
    integer bht_store_total;
    integer bht_store_conflict_total;
    integer bht_store_imm_overlap_total;
    integer mul_exec_total;
    integer mul_follow_slot_total;
    integer mul_dep_slot_total;
    integer mul_dep_d1_total;
    integer mul_dep_d2_total;
    integer mul_dep_d3_total;
    integer slot1_track_i;
    integer slot1_match_slot;
    integer slot1_free_slot;
    integer slot1_match_type;
    integer slot1_match_pred_taken;
    integer slot1_match_branch_backward;
    integer slot1_match_correct;
    reg         slot1_pending_valid [0:SLOT1_TRACK_SLOTS-1];
    reg [31:0]  slot1_pending_pc [0:SLOT1_TRACK_SLOTS-1];
    reg [31:0]  slot1_pending_instr [0:SLOT1_TRACK_SLOTS-1];
    reg         slot1_pending_pred_taken [0:SLOT1_TRACK_SLOTS-1];
    reg [31:0]  slot1_pending_pred_target [0:SLOT1_TRACK_SLOTS-1];
    reg [2:0]   slot1_pending_type [0:SLOT1_TRACK_SLOTS-1];

    integer cycle_snap;

    integer instr_snap;
    integer flush_snap;
    integer load_stall_snap;
    integer false_load_stall_snap;
    integer mul_hold_snap;
    integer other_bubble_snap;
    integer wb_commit_snap;
    integer branch_snap;
    integer branch_taken_snap;
    integer branch_both_taken_snap;
    integer jal_snap;
    integer jal_pred_snap;
    integer jal_correct_snap;
    integer jalr_snap;
    integer jalr_pred_snap;
    integer jalr_correct_snap;
    integer ret_snap;
    integer ret_pred_snap;
    integer ret_correct_snap;
    integer call_jalr_snap;
    integer call_jalr_pred_snap;
    integer call_jalr_correct_snap;
    integer indirect_jalr_snap;
    integer indirect_jalr_pred_snap;
    integer indirect_jalr_correct_snap;
    integer jalr_prev_wr_rs1_snap;
    integer ret_prev_wr_rs1_snap;
    integer call_jalr_prev_wr_rs1_snap;
    integer indirect_jalr_prev_wr_rs1_snap;
    integer auipc_jalr_snap;
    integer auipc_ret_snap;
    integer auipc_call_jalr_snap;
    integer auipc_indirect_jalr_snap;
    integer pred_taken_snap;
    integer dir_correct_snap;
    integer target_correct_snap;
    integer mispredict_snap;
    integer branch_miss_taken_snap;
    integer branch_miss_nt_snap;
    integer branch_hit_forward_snap;
    integer branch_hit_backward_snap;
    integer branch_miss_forward_snap;
    integer branch_miss_backward_snap;
    integer if_branch_hit_snap;
    integer if_branch_nohit_snap;
    integer if_branch_nohit_back_snap;
    integer if_branch_nohit_back_ok_snap;
    integer if_branch_nohit_back_redirect_snap;
    integer slot1_redirect_snap;
    integer bht_tag_alias_snap;
    integer bht_store_snap;
    integer bht_store_conflict_snap;
    integer bht_store_imm_overlap_snap;

    integer instr_now;
    integer flush_now;
    integer load_stall_now;
    integer false_load_stall_now;
    integer lduse3_base_now;
    integer lduse3_i2_dep_i0_now;
    integer lduse3_i2_dep_i1_now;
    integer lduse3_i2_dep_both_now;
    integer mul_hold_now;
    integer other_bubble_now;
    integer wb_commit_now;
    integer branch_now;
    integer branch_taken_now;
    integer branch_both_taken_now;
    integer jal_now;
    integer jal_pred_now;
    integer jal_correct_now;
    integer jalr_now;
    integer jalr_pred_now;
    integer jalr_correct_now;
    integer ret_now;
    integer ret_pred_now;
    integer ret_correct_now;
    integer call_jalr_now;
    integer call_jalr_pred_now;
    integer call_jalr_correct_now;
    integer indirect_jalr_now;
    integer indirect_jalr_pred_now;
    integer indirect_jalr_correct_now;
    integer jalr_prev_wr_rs1_now;
    integer ret_prev_wr_rs1_now;
    integer call_jalr_prev_wr_rs1_now;
    integer indirect_jalr_prev_wr_rs1_now;
    integer auipc_jalr_now;
    integer auipc_ret_now;
    integer auipc_call_jalr_now;
    integer auipc_indirect_jalr_now;
    integer pred_taken_now;
    integer dir_correct_now;
    integer target_correct_now;
    integer mispredict_now;
    integer branch_miss_taken_now;
    integer branch_miss_nt_now;
    integer branch_hit_forward_now;
    integer branch_hit_backward_now;
    integer branch_miss_forward_now;
    integer branch_miss_backward_now;
    integer if_branch_hit_now;
    integer if_branch_nohit_now;
    integer if_branch_nohit_back_now;
    integer if_branch_nohit_back_ok_now;
    integer if_branch_nohit_back_redirect_now;
    integer slot1_redirect_now;
    integer slot1_branch_seen_now;
    integer slot1_branch_issue_now;
    integer slot1_branch_back_now;
    integer slot1_branch_issue_back_now;
    integer bht_tag_alias_now;
    integer bht_store_now;
    integer bht_store_conflict_now;
    integer bht_store_imm_overlap_now;

    integer cycle_win;
    integer stat_cycle_win;
    integer init_i;
    integer branch_pc_i;
    integer branch_pc_slot;
    integer branch_pc_free;
    integer jalr_pc_i;
    integer jalr_pc_slot;
    integer jalr_pc_free;
    integer mul_follow_inc;
    integer mul_dep_slot_inc;
    integer mul_dep_d1_inc;
    integer mul_dep_d2_inc;
    integer mul_dep_d3_inc;
    integer mul_exec_inc;

    integer instr_win;
    integer flush_win;
    integer load_stall_win;
    integer false_load_stall_win;
    integer mul_hold_win;
    integer other_bubble_win;
    integer wb_commit_win;
    integer branch_win;
    integer branch_taken_win;
    integer branch_both_taken_win;
    integer jal_win;
    integer jal_pred_win;
    integer jal_correct_win;
    integer jalr_win;
    integer jalr_pred_win;
    integer jalr_correct_win;
    integer ret_win;
    integer ret_pred_win;
    integer ret_correct_win;
    integer call_jalr_win;
    integer call_jalr_pred_win;
    integer call_jalr_correct_win;
    integer indirect_jalr_win;
    integer indirect_jalr_pred_win;
    integer indirect_jalr_correct_win;
    integer jalr_prev_wr_rs1_win;
    integer ret_prev_wr_rs1_win;
    integer call_jalr_prev_wr_rs1_win;
    integer indirect_jalr_prev_wr_rs1_win;
    integer auipc_jalr_win;
    integer auipc_ret_win;
    integer auipc_call_jalr_win;
    integer auipc_indirect_jalr_win;
    integer pred_taken_win;
    integer dir_correct_win;
    integer target_correct_win;
    integer mispredict_win;
    integer branch_miss_taken_win;
    integer branch_miss_nt_win;
    integer branch_hit_forward_win;
    integer branch_hit_backward_win;
    integer branch_miss_forward_win;
    integer branch_miss_backward_win;
    integer if_branch_hit_win;
    integer if_branch_nohit_win;
    integer if_branch_nohit_back_win;
    integer if_branch_nohit_back_ok_win;
    integer if_branch_nohit_back_redirect_win;
    integer slot1_redirect_win;
    integer bht_tag_alias_win;
    integer bht_store_win;
    integer bht_store_conflict_win;
    integer bht_store_imm_overlap_win;

    reg         prev_issue_valid;
    reg         prev_issue_we;
    reg  [4:0]  prev_issue_rd;
    reg  [31:0] prev_issue_instr;
    reg         lduse3_seq0_valid;
    reg         lduse3_seq0_load;
    reg  [4:0]  lduse3_seq0_rd;
    reg         lduse3_seq1_valid;
    reg         lduse3_seq1_load;
    reg         lduse3_seq1_we;
    reg  [4:0]  lduse3_seq1_rd;
    reg         lduse3_seq1_rs1_used;
    reg         lduse3_seq1_rs2_used;
    reg  [4:0]  lduse3_seq1_rs1_addr;
    reg  [4:0]  lduse3_seq1_rs2_addr;
    reg         mul_dep1_valid;
    reg         mul_dep2_valid;
    reg         mul_dep3_valid;
    reg  [4:0]  mul_dep1_rd;
    reg  [4:0]  mul_dep2_rd;
    reg  [4:0]  mul_dep3_rd;
    reg         tb_mem_branch_nohit;
    reg         tb_mem_call_flag;
    reg         jalr_pc_valid [0:JALR_PC_STAT_SLOTS-1];
    reg  [31:0] jalr_pc_addr  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_exec  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_pred  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_ok    [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_ret   [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_call  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_other [0:JALR_PC_STAT_SLOTS-1];
    reg         branch_pc_valid [0:BRANCH_PC_STAT_SLOTS-1];
    reg  [31:0] branch_pc_addr  [0:BRANCH_PC_STAT_SLOTS-1];
    integer     branch_pc_exec  [0:BRANCH_PC_STAT_SLOTS-1];
    integer     branch_pc_pred  [0:BRANCH_PC_STAT_SLOTS-1];
    integer     branch_pc_dir_ok[0:BRANCH_PC_STAT_SLOTS-1];
    integer     branch_pc_mis   [0:BRANCH_PC_STAT_SLOTS-1];
    integer     branch_pc_taken [0:BRANCH_PC_STAT_SLOTS-1];
    reg         bht_meta_valid   [0:BHT_STAT_ENTRY_NUM-1];
    reg  [31:0] bht_meta_pc      [0:BHT_STAT_ENTRY_NUM-1];
    reg  [31:0] bht_meta_imm_abs [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_if_lookup [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_if_hit    [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_if_nohit  [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_if_pred   [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_alias     [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_exec   [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_taken  [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_pred   [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_dir_ok [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_mis    [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_ex_nohit  [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_fwd       [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_back      [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_store     [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_conflict  [0:BHT_STAT_ENTRY_NUM-1];
    integer     bht_entry_imm_ovlp  [0:BHT_STAT_ENTRY_NUM-1];

    wire jalr_prev_wr_rs1_fire = stat_cycle_win
                              && issue_instr_fire
                              && u_cpu.id_jalr_flag
                              && prev_issue_valid
                              && prev_issue_we
                              && (prev_issue_rd != 5'd0)
                              && (prev_issue_rd == u_cpu.id_rs1_addr);
    wire prev_issue_is_auipc   = prev_issue_instr[6:0] == 7'b0010111;
    wire auipc_jalr_fire       = stat_cycle_win
                              && issue_instr_fire
                              && u_cpu.id_jalr_flag
                              && prev_issue_valid
                              && prev_issue_is_auipc;
    wire [6:0] issue_opcode     = u_cpu.id_instr[6:0];
    wire       issue_rs1_used   = issue_instr_fire
                               && !(issue_opcode == 7'b0110111)
                               && !(issue_opcode == 7'b0010111)
                               && !(issue_opcode == 7'b1101111);
    wire       issue_rs2_used   = issue_instr_fire
                               && ((issue_opcode == 7'b0110011)
                                || (issue_opcode == 7'b0100011)
                                || (issue_opcode == 7'b1100011));
    wire       issue_is_mul     = issue_instr_fire
                               && (issue_opcode == 7'b0110011)
                               && (u_cpu.id_instr[31:25] == 7'b0000001);
    wire       issue_is_load    = issue_instr_fire
                               && (issue_opcode == 7'b0000011);
    wire       issue_dep_lduse3_seq0 = lduse3_seq0_valid
                                    && (lduse3_seq0_rd != 5'd0)
                                    && (((issue_rs1_used && (u_cpu.id_rs1_addr == lduse3_seq0_rd))
                                      || (issue_rs2_used && (u_cpu.id_rs2_addr == lduse3_seq0_rd))));
    wire       issue_dep_lduse3_seq1 = lduse3_seq1_valid
                                    && lduse3_seq1_we
                                    && (lduse3_seq1_rd != 5'd0)
                                    && (((issue_rs1_used && (u_cpu.id_rs1_addr == lduse3_seq1_rd))
                                      || (issue_rs2_used && (u_cpu.id_rs2_addr == lduse3_seq1_rd))));
    wire       lduse3_seq1_dep_seq0 = lduse3_seq1_valid
                                   && lduse3_seq0_valid
                                   && lduse3_seq0_load
                                   && (lduse3_seq0_rd != 5'd0)
                                   && (((lduse3_seq1_rs1_used && (lduse3_seq1_rs1_addr == lduse3_seq0_rd))
                                     || (lduse3_seq1_rs2_used && (lduse3_seq1_rs2_addr == lduse3_seq0_rd))));
    wire       lduse3_base_fire = stat_cycle_win
                               && issue_instr_fire
                               && lduse3_seq1_dep_seq0;
    wire       lduse3_i2_dep_i0_fire = lduse3_base_fire
                                    && issue_dep_lduse3_seq0;
    wire       lduse3_i2_dep_i1_fire = lduse3_base_fire
                                    && issue_dep_lduse3_seq1;
    wire       lduse3_i2_dep_both_fire = lduse3_i2_dep_i0_fire
                                      && lduse3_i2_dep_i1_fire;
    wire [6:0] stall_opcode     = u_cpu.id_instr[6:0];
    wire       stall_rs1_used   = !(stall_opcode == 7'b0110111)
                               && !(stall_opcode == 7'b0010111)
                               && !(stall_opcode == 7'b1101111);
    wire       stall_rs2_used   = (stall_opcode == 7'b0110011)
                               || (stall_opcode == 7'b0100011)
                               || (stall_opcode == 7'b1100011);
    wire       stall_cycle_fire = !issue_instr_fire
                               && u_cpu.pipeline_stall
                               && !u_cpu.pipeline_flush;
    wire       stall_need_rs1   = u_cpu.ex_dmem_re
                               && (u_cpu.ex_regs_w_addr != 5'd0)
                               && stall_rs1_used
                               && (u_cpu.id_rs1_addr == u_cpu.ex_regs_w_addr);
    wire       stall_need_rs2   = u_cpu.ex_dmem_re
                               && (u_cpu.ex_regs_w_addr != 5'd0)
                               && stall_rs2_used
                               && (u_cpu.id_rs2_addr == u_cpu.ex_regs_w_addr);
    wire       stall_need_real  = stall_need_rs1 || stall_need_rs2;
    wire       false_load_stall_fire = stat_cycle_win
                                    && stall_cycle_fire
                                    && !stall_need_real;
    wire       mul_dep_hit_d1   = issue_instr_fire
                               && mul_dep1_valid
                               && (((issue_rs1_used && (u_cpu.id_rs1_addr == mul_dep1_rd)))
                                || ((issue_rs2_used && (u_cpu.id_rs2_addr == mul_dep1_rd))));
    wire       mul_dep_hit_d2   = issue_instr_fire
                               && mul_dep2_valid
                               && (((issue_rs1_used && (u_cpu.id_rs1_addr == mul_dep2_rd)))
                                || ((issue_rs2_used && (u_cpu.id_rs2_addr == mul_dep2_rd))));
    wire       mul_dep_hit_d3   = issue_instr_fire
                               && mul_dep3_valid
                               && (((issue_rs1_used && (u_cpu.id_rs1_addr == mul_dep3_rd)))
                                || ((issue_rs2_used && (u_cpu.id_rs2_addr == mul_dep3_rd))));
    wire [BHT_STAT_INDEX_BITS-1:0] if_bht_idx = u_cpu.if_instr_addr[BHT_STAT_INDEX_BITS+1:2] ^ u_cpu.if_branch_hash;
    wire       if_bht_lookup_fire = stat_cycle_win
                                 && u_cpu.if_is_b;
    wire       if_bht_alias_hit = stat_cycle_win
                               && u_cpu.if_is_b
                               && u_cpu.if_branch_hit
                               && bht_meta_valid[if_bht_idx]
                               && (bht_meta_pc[if_bht_idx] != u_cpu.if_instr_addr);
    wire       if_branch_nohit_fire = stat_cycle_win
                                   && u_cpu.if_is_b
                                   && !u_cpu.if_branch_hit;
    wire       if_branch_nohit_back_fire = if_branch_nohit_fire
                                        && u_cpu.if_b_imm[31];
    wire       if_branch_nohit_back_ok_fire = if_branch_nohit_back_fire
                                           && u_cpu.frontend_issue_ok
                                           && !u_cpu.ctrl_resolve_mispredict;
    wire       if_branch_nohit_back_redirect_fire = if_branch_nohit_back_fire
                                                 && u_cpu.slot0_ctrl_redirect
                                                 && !u_cpu.ctrl_resolve_mispredict;
    function [BHT_STAT_TAG_BITS-1:0] tb_pack_bht_tag;
        input [31:0] pc_value;
        integer bit_idx;
        begin
            tb_pack_bht_tag = {BHT_STAT_TAG_BITS{1'b0}};
            for (bit_idx = 0; bit_idx < BHT_STAT_TAG_BITS; bit_idx = bit_idx + 1) begin
                if ((BHT_STAT_INDEX_BITS + 2 + bit_idx) < BHT_STAT_PC_BITS)
                    tb_pack_bht_tag[bit_idx] = pc_value[BHT_STAT_INDEX_BITS + 2 + bit_idx];
            end
        end
    endfunction
    wire [BHT_STAT_INDEX_BITS-1:0] ex_bht_idx = u_cpu.ex_instr_addr[BHT_STAT_INDEX_BITS+1:2] ^ u_cpu.ex_branch_hash;
    wire [BHT_STAT_TAG_BITS-1:0]   ex_bht_tag = tb_pack_bht_tag(u_cpu.ex_instr_addr);
    wire       ex_bht_hit_meta = u_cpu.u_branch_predictor.branch_valid[ex_bht_idx]
                              && (u_cpu.u_branch_predictor.branch_tag[ex_bht_idx] == ex_bht_tag);
    wire [31:0] ex_pred_target_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.ex_pred_target};
    wire [31:0] ex_actual_jump_addr_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.ex_actual_jump_addr};
    wire [31:0] ex_branch_imm_raw = u_cpu.ex_branch_jump_addr - u_cpu.ex_instr_addr;
    wire [31:0] ex_branch_imm_abs = ex_branch_imm_raw[31] ? (~ex_branch_imm_raw + 32'd1) : ex_branch_imm_raw;
    wire       ex_ctrl_stat_fire = stat_cycle_win
                                && !u_cpu.mem_ctrl_mispredict
                                && !u_cpu.ex_ctrl_defer
                                && (u_cpu.ex_branch_flag || u_cpu.ex_jump_flag);
    wire       ex_branch_stat_fire = ex_ctrl_stat_fire && u_cpu.ex_branch_flag;
    wire       ex_jal_stat_fire = ex_ctrl_stat_fire
                               && u_cpu.ex_jump_flag
                               && !u_cpu.ex_jalr_flag;
    wire       ex_jalr_stat_fire = ex_ctrl_stat_fire
                                && u_cpu.ex_jump_flag
                                && u_cpu.ex_jalr_flag;
    wire       ex_bht_store_fire = ex_branch_stat_fire
                                && u_cpu.ex_actual_jump_flag
                                && !ex_bht_hit_meta;
    wire       ex_bht_store_conflict = ex_bht_store_fire && bht_meta_valid[ex_bht_idx];
    wire       ex_bht_store_imm_overlap = ex_bht_store_conflict
                                       && (bht_meta_imm_abs[ex_bht_idx] == ex_branch_imm_abs);
    wire       ex_branch_is_backward = ex_branch_imm_raw[31];
    wire [31:0] mem_ctrl_pc_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.mem_ctrl_pc_low};
    wire [31:0] mem_ctrl_pred_target_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.mem_ctrl_pred_target_low};
    wire [31:0] mem_ctrl_actual_jump_addr_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.mem_ctrl_actual_jump_addr_low};
    wire [31:0] mem_ctrl_branch_target_full = {{TB_IMEM_PAD_BITS{1'b0}}, u_cpu.mem_ctrl_branch_target_low};
    wire       mem_ctrl_stat_fire = stat_cycle_win && u_cpu.mem_ctrl_resolve_en;
    wire       mem_branch_stat_fire = mem_ctrl_stat_fire && u_cpu.mem_branch_flag;
    wire       mem_jalr_stat_fire = mem_ctrl_stat_fire && u_cpu.mem_jalr_flag;
    wire [BHT_STAT_INDEX_BITS-1:0] mem_bht_idx = mem_ctrl_pc_full[BHT_STAT_INDEX_BITS+1:2] ^ u_cpu.mem_branch_hash;
    wire [BHT_STAT_TAG_BITS-1:0]   mem_bht_tag = tb_pack_bht_tag(mem_ctrl_pc_full);
    wire       mem_bht_hit_meta = u_cpu.u_branch_predictor.branch_valid[mem_bht_idx]
                               && (u_cpu.u_branch_predictor.branch_tag[mem_bht_idx] == mem_bht_tag);
    wire [31:0] mem_branch_imm_raw = mem_ctrl_branch_target_full - mem_ctrl_pc_full;
    wire [31:0] mem_branch_imm_abs = mem_branch_imm_raw[31] ? (~mem_branch_imm_raw + 32'd1) : mem_branch_imm_raw;
    wire       mem_branch_is_backward = mem_branch_imm_raw[31];
    wire       mem_bht_store_fire = mem_branch_stat_fire
                                 && u_cpu.mem_ctrl_actual_jump_flag
                                 && !mem_bht_hit_meta;
    wire       mem_bht_store_conflict = mem_bht_store_fire && bht_meta_valid[mem_bht_idx];
    wire       mem_bht_store_imm_overlap = mem_bht_store_conflict
                                        && (bht_meta_imm_abs[mem_bht_idx] == mem_branch_imm_abs);

    function integer pct_x100;
        input integer numer;
        input integer denom;
        reg [63:0] scaled_value;
        reg [63:0] rounded_value;
        begin
            if (denom != 0) begin
                scaled_value = numer;
                rounded_value = scaled_value * 64'd10000 + (denom / 2);
                pct_x100 = rounded_value / denom;
            end else
                pct_x100 = 0;
        end
    endfunction

    function integer ratio_x1000;
        input integer numer;
        input integer denom;
        reg [63:0] scaled_value;
        reg [63:0] rounded_value;
        begin
            if (denom != 0) begin
                scaled_value = numer;
                rounded_value = scaled_value * 64'd1000 + (denom / 2);
                ratio_x1000 = rounded_value / denom;
            end else
                ratio_x1000 = 0;
        end
    endfunction

    function [7:0] dhry_key_char;
        input integer idx;
        begin
            case (idx)
                0:  dhry_key_char = "D";
                1:  dhry_key_char = "h";
                2:  dhry_key_char = "r";
                3:  dhry_key_char = "y";
                4:  dhry_key_char = "s";
                5:  dhry_key_char = "t";
                6:  dhry_key_char = "o";
                7:  dhry_key_char = "n";
                8:  dhry_key_char = "e";
                9:  dhry_key_char = "s";
                10: dhry_key_char = " ";
                11: dhry_key_char = "p";
                12: dhry_key_char = "e";
                13: dhry_key_char = "r";
                14: dhry_key_char = " ";
                15: dhry_key_char = "S";
                16: dhry_key_char = "e";
                17: dhry_key_char = "c";
                18: dhry_key_char = "o";
                19: dhry_key_char = "n";
                20: dhry_key_char = "d";
                21: dhry_key_char = ":";
                default: dhry_key_char = 8'd0;
            endcase
        end
    endfunction

    function [7:0] ipc_key_char;
        input integer idx;
        begin
            case (idx)
                0: ipc_key_char = "I";
                1: ipc_key_char = "P";
                2: ipc_key_char = "C";
                3: ipc_key_char = "=";
                default: ipc_key_char = 8'd0;
            endcase
        end
    endfunction

    task print_bench_ipc_crosscheck;
        reg [63:0] tb_retire_delta;
        reg [63:0] sw_ipc_x1000;
        reg [63:0] tb_ipc_x1000;
        begin
            if (tb_instret_start_valid && tb_instret_stop_valid)
                tb_retire_delta = tb_instret_stop_retire - tb_instret_start_retire;
            else
                tb_retire_delta = 64'd0;

            if (uart_bench_cycle_valid && (uart_bench_cycle_value != 0)) begin
                sw_ipc_x1000 = (uart_bench_instret_value * 64'd1000 + (uart_bench_cycle_value / 2))
                             / uart_bench_cycle_value;
                tb_ipc_x1000 = (tb_retire_delta * 64'd1000 + (uart_bench_cycle_value / 2))
                             / uart_bench_cycle_value;
            end else begin
                sw_ipc_x1000 = 64'd0;
                tb_ipc_x1000 = 64'd0;
            end

            if (uart_bench_cycle_valid && uart_bench_instret_valid
                    && tb_instret_start_valid && tb_instret_stop_valid) begin
                if (tb_retire_delta == uart_bench_instret_value)
                    $display("[TBCHK] IPC raw : SW_C=%0d  SW_I=%0d  TB_retire=%0d  match=YES",
                             uart_bench_cycle_value, uart_bench_instret_value, tb_retire_delta);
                else
                    $display("[TBCHK] IPC raw : SW_C=%0d  SW_I=%0d  TB_retire=%0d  match=NO",
                             uart_bench_cycle_value, uart_bench_instret_value, tb_retire_delta);

                $display("[TBCHK] IPC cmp : SW_IPC=%0d.%03d  TB_IPC=%0d.%03d",
                         sw_ipc_x1000 / 1000, sw_ipc_x1000 % 1000,
                         tb_ipc_x1000 / 1000, tb_ipc_x1000 % 1000);
            end else begin
                $display("[TBCHK] IPC raw : capture incomplete  swC=%0d swI=%0d tbStart=%0d tbStop=%0d",
                         uart_bench_cycle_valid, uart_bench_instret_valid,
                         tb_instret_start_valid, tb_instret_stop_valid);
            end
        end
    endtask

    task print_compact_report_stats;
        input integer show_cycle;
        input integer total_instr;
        input integer total_branch;
        input integer total_branch_both_taken;
        input integer total_jal;
        input integer total_jal_pred;
        input integer total_jal_correct;
        input integer total_jalr;
        input integer total_jalr_pred;
        input integer total_jalr_correct;
        input integer total_dir_correct;
        input integer total_target_correct;
        input integer total_mispredict;
        input integer total_flush;
        input integer total_load_stall;
        input integer total_mul_hold;
        input integer total_other_bubble;
        integer ipc_x1000;
        integer cpi_x1000;
        integer jal_acc_x100;
        integer jal_tgt_acc_x100;
        integer jalr_acc_x100;
        integer jalr_tgt_acc_x100;
        integer b_dir_acc_x100;
        integer b_tgt_acc_x100;
        integer b_acc_x100;
        integer overall_ctrl_total;
        integer overall_ctrl_correct;
        integer overall_acc_x100;
        integer overall_miss_x100;
        integer total_loss;
        integer total_loss_pct_x100;
        integer total_flush_share_x100;
        integer total_load_stall_share_x100;
        integer total_mul_hold_share_x100;
        integer total_other_bubble_share_x100;
        integer dmips_x1000;
        integer dmips_per_mhz_x1000;
        integer dps_display_value;
        reg [63:0] dps_scaled_num;
        reg [63:0] dmips_scaled_num;
        reg [63:0] dmips_scaled_den;
        begin
            ipc_x1000 = ratio_x1000(total_instr, show_cycle);
            cpi_x1000 = ratio_x1000(show_cycle, total_instr);

            jal_acc_x100      = pct_x100(total_jal_correct, total_jal);
            jal_tgt_acc_x100  = pct_x100(total_jal_correct, total_jal_pred);
            jalr_acc_x100     = pct_x100(total_jalr_correct, total_jalr);
            jalr_tgt_acc_x100 = pct_x100(total_jalr_correct, total_jalr_pred);
            b_dir_acc_x100    = pct_x100(total_dir_correct, total_branch);
            b_tgt_acc_x100    = pct_x100(total_target_correct, total_branch_both_taken);
            b_acc_x100        = pct_x100(total_branch - total_mispredict, total_branch);

            overall_ctrl_total   = total_branch + total_jal + total_jalr;
            overall_ctrl_correct = (total_branch - total_mispredict) + total_jal_correct + total_jalr_correct;
            overall_acc_x100     = pct_x100(overall_ctrl_correct, overall_ctrl_total);
            overall_miss_x100    = pct_x100(overall_ctrl_total - overall_ctrl_correct, overall_ctrl_total);

            total_loss                   = show_cycle - total_instr;
            total_loss_pct_x100          = pct_x100(total_loss, show_cycle);
            total_flush_share_x100       = pct_x100(total_flush, total_loss);
            total_load_stall_share_x100  = pct_x100(total_load_stall, total_loss);
            total_mul_hold_share_x100    = pct_x100(total_mul_hold, total_loss);
            total_other_bubble_share_x100 = pct_x100(total_other_bubble, total_loss);

            $display("");
            $display("[STAT][%0d cyc] PERF : IPC=%0d.%03d  CPI=%0d.%03d",
                     show_cycle,
                     ipc_x1000 / 1000, ipc_x1000 % 1000,
                     cpi_x1000 / 1000, cpi_x1000 % 1000);
            $display("[STAT][%0d cyc] JAL  : acc=%0d.%02d%%  tgt_acc=%0d.%02d%%",
                     show_cycle,
                     jal_acc_x100 / 100, jal_acc_x100 % 100,
                     jal_tgt_acc_x100 / 100, jal_tgt_acc_x100 % 100);
            $display("[STAT][%0d cyc] JALR : acc=%0d.%02d%%  tgt_acc=%0d.%02d%%",
                     show_cycle,
                     jalr_acc_x100 / 100, jalr_acc_x100 % 100,
                     jalr_tgt_acc_x100 / 100, jalr_tgt_acc_x100 % 100);
            $display("[STAT][%0d cyc] B    : dir_acc=%0d.%02d%%  tgt_acc=%0d.%02d%%  total_acc=%0d.%02d%%",
                     show_cycle,
                     b_dir_acc_x100 / 100, b_dir_acc_x100 % 100,
                     b_tgt_acc_x100 / 100, b_tgt_acc_x100 % 100,
                     b_acc_x100 / 100, b_acc_x100 % 100);
            $display("[STAT][%0d cyc] ALL  : total_acc=%0d.%02d%%  miss=%0d.%02d%%",
                     show_cycle,
                     overall_acc_x100 / 100, overall_acc_x100 % 100,
                     overall_miss_x100 / 100, overall_miss_x100 % 100);
            if (dhry_dps_valid && (dhry_dps_value != 0)) begin
                dps_display_value = dhry_dps_value;
                dmips_x1000 = ratio_x1000(dhry_dps_value, 1757);
                dmips_per_mhz_x1000 = (TB_CPU_FREQ_MHZ != 0)
                                    ? ((dmips_x1000 + (TB_CPU_FREQ_MHZ / 2)) / TB_CPU_FREQ_MHZ)
                                    : 0;
                $display("[STAT][%0d cyc] DHRY : dps=%0d  DMIPS/MHz=%0d.%03d",
                         show_cycle,
                         dps_display_value,
                         dmips_per_mhz_x1000 / 1000, dmips_per_mhz_x1000 % 1000);
            end else if (show_cycle != 0) begin
                dps_scaled_num    = 64'd1 * TB_CPU_FREQ_HZ * TB_DHRY_RUNS + (show_cycle / 2);
                dps_display_value = dps_scaled_num / show_cycle;
                dmips_scaled_num  = 64'd1000000000 * TB_DHRY_RUNS;
                dmips_scaled_den  = (64'd1757 * show_cycle);
                dmips_per_mhz_x1000 = (dmips_scaled_den != 0)
                                    ? ((dmips_scaled_num + (dmips_scaled_den / 2)) / dmips_scaled_den)
                                    : 0;
                $display("[STAT][%0d cyc] DHRY : dps=%0d  DMIPS/MHz=%0d.%03d (derived)",
                         show_cycle,
                         dps_display_value,
                         dmips_per_mhz_x1000 / 1000, dmips_per_mhz_x1000 % 1000);
            end else begin
                $display("[STAT][%0d cyc] DHRY : DMIPS/MHz=N/A",
                         show_cycle);
            end
            $display("[STAT][%0d cyc] LOSS : total=%0d(%0d.%02d%% cyc)  flush=%0d(%0d.%02d%%)  ld=%0d(%0d.%02d%%)  mul=%0d(%0d.%02d%%)  bub=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_loss, total_loss_pct_x100 / 100, total_loss_pct_x100 % 100,
                     total_flush, total_flush_share_x100 / 100, total_flush_share_x100 % 100,
                     total_load_stall, total_load_stall_share_x100 / 100, total_load_stall_share_x100 % 100,
                     total_mul_hold, total_mul_hold_share_x100 / 100, total_mul_hold_share_x100 % 100,
                     total_other_bubble, total_other_bubble_share_x100 / 100, total_other_bubble_share_x100 % 100);
        end
    endtask

    task write_heat_bar;
        input integer file_desc;
        input integer value;
        input integer max_value;
        integer bar_idx;
        integer bar_len;
        begin
            if (max_value != 0)
                bar_len = (value * 40 + (max_value / 2)) / max_value;
            else
                bar_len = 0;

            for (bar_idx = 0; bar_idx < 40; bar_idx = bar_idx + 1) begin
                if (bar_idx < bar_len)
                    $fwrite(file_desc, "#");
                else
                    $fwrite(file_desc, ".");
            end
        end
    endtask

    wire issue_instr_fire = !u_cpu.pipeline_flush
                         && !u_cpu.pipeline_stall
                         && !u_cpu.pipeline_hold
                         && (u_cpu.id_instr != 32'b0);
    wire timer_req_fire = u_cpu.ex_dmem_re
                       && ((u_cpu.ex_dmem_wr_addr == MMIO_TIMER_LO_ADDR)
                        || (u_cpu.ex_dmem_wr_addr == MMIO_TIMER_HI_ADDR));
    wire mem_instret_lo_fire = u_cpu.mem_valid
                            && u_cpu.mem_dmem_re
                            && (u_cpu.mem_dmem_wr_addr == MMIO_INSTRET_LO_ADDR);
    wire mem_instret_hi_fire = u_cpu.mem_valid
                            && u_cpu.mem_dmem_re
                            && (u_cpu.mem_dmem_wr_addr == MMIO_INSTRET_HI_ADDR);
    wire slot1_branch_seen_fire = stat_active
                               && u_cpu.if_pre_valid
                               && (u_cpu.if_pre_instr[6:2] == 5'b11000);
    wire slot1_branch_issue_fire = slot1_branch_seen_fire
                                && u_cpu.frontend_issue_ok
                                && !u_cpu.slot0_ctrl_redirect
                                && !u_cpu.ctrl_resolve_mispredict;
    wire slot1_branch_back_fire = slot1_branch_seen_fire
                               && u_cpu.if_pre_instr[31];
    wire slot1_branch_issue_back_fire = slot1_branch_issue_fire
                                     && u_cpu.if_pre_instr[31];
    wire slot1_ctrl_candidate_fire = stat_active
                                  && u_cpu.if_pre_valid
                                  && u_cpu.frontend_issue_ok
                                  && !u_cpu.slot0_ctrl_redirect
                                  && !u_cpu.ctrl_resolve_mispredict
                                  && ((u_cpu.if_pre_instr[6:2] == 5'b11000)
                                   || (u_cpu.if_pre_instr[6:2] == 5'b11011)
                                   || (u_cpu.if_pre_instr[6:2] == 5'b11001));
    wire slot1_pred_effective_fire = stat_active
                                   && u_cpu.slot1_pred_redirect
                                   && !u_cpu.slot0_ctrl_redirect
                                   && !u_cpu.ctrl_resolve_mispredict;
    wire slot1_pred_without_valid_fire = stat_active
                                      && u_cpu.slot1_pred_redirect
                                      && !u_cpu.if_pre_valid
                                      && !u_cpu.slot0_ctrl_redirect
                                      && !u_cpu.ctrl_resolve_mispredict;
    wire slot1_raw_invalid_fire = stat_active
                               && !u_cpu.if_pre_valid
                               && u_cpu.if_pre_pred_taken_eff;
    wire [2:0] slot1_candidate_type = (u_cpu.if_pre_instr[6:2] == 5'b11000) ? SLOT1_TYPE_B :
                                      (u_cpu.if_pre_instr[6:2] == 5'b11011) ? SLOT1_TYPE_JAL :
                                      (u_cpu.if_pre_is_ret)                  ? SLOT1_TYPE_RET :
                                      (u_cpu.if_pre_is_call)                 ? SLOT1_TYPE_CALL_JALR :
                                                                               SLOT1_TYPE_INDIRECT_JALR;

    task print_bp_stats;
        input integer show_cycle;
        input integer total_instr;
        input integer total_flush;
        input integer total_load_stall;
        input integer total_false_load_stall;
        input integer total_mul_hold;
        input integer total_other_bubble;
        input integer total_branch;
        input integer total_branch_taken;
        input integer total_branch_both_taken;
        input integer total_jal;
        input integer total_jal_pred;
        input integer total_jal_correct;
        input integer total_jalr;
        input integer total_jalr_pred;
        input integer total_jalr_correct;
        input integer total_ret;
        input integer total_ret_pred;
        input integer total_ret_correct;
        input integer total_call_jalr;
        input integer total_call_jalr_pred;
        input integer total_call_jalr_correct;
        input integer total_indirect_jalr;
        input integer total_indirect_jalr_pred;
        input integer total_indirect_jalr_correct;
        input integer total_pred_taken;
        input integer total_dir_correct;
        input integer total_target_correct;
        input integer total_mispredict;
        input integer total_branch_miss_taken;
        input integer total_branch_miss_nt;
        input integer total_branch_hit_forward;
        input integer total_branch_hit_backward;
        input integer total_branch_miss_forward;
        input integer total_branch_miss_backward;
        input integer total_if_branch_hit;
        input integer total_if_branch_nohit;
        input integer total_if_branch_nohit_back;
        input integer total_if_branch_nohit_back_ok;
        input integer total_if_branch_nohit_back_redirect;
        input integer total_slot1_redirect;
        input integer total_wb_commit;
        input integer total_bht_tag_alias;
        input integer total_bht_store;
        input integer total_bht_store_conflict;
        input integer total_bht_store_imm_overlap;
        input integer total_mul_exec;
        input integer total_mul_follow_slot;
        input integer total_mul_dep_slot;
        input integer total_mul_dep_d1;
        input integer total_mul_dep_d2;
        input integer total_mul_dep_d3;
        integer total_dir_acc_x100;
        integer total_taken_prec_x100;
        integer total_taken_recall_x100;
        integer total_target_acc_x100;
        integer total_pred_cov_x100;
        integer total_miss_rate_x100;
        integer total_ctrl_share_x100;
        integer total_ipc_x1000;
        integer total_jal_acc_x100;
        integer total_jal_pred_rate_x100;
        integer total_jalr_acc_x100;
        integer total_jalr_pred_rate_x100;
        integer total_ret_acc_x100;
        integer total_ret_pred_rate_x100;
        integer total_call_jalr_acc_x100;
        integer total_call_jalr_pred_rate_x100;
        integer total_indirect_jalr_acc_x100;
        integer total_indirect_jalr_pred_rate_x100;
        integer total_dir_wrong;
        integer total_target_wrong;
        integer total_branch_nt;
        integer total_ctrl_total;
        integer total_nohit_exec;
        integer total_nohit_taken_pct_x100;
        integer total_nohit_nt_pct_x100;
        integer total_nohit_forward_pct_x100;
        integer total_nohit_backward_pct_x100;
        integer total_loss;
        integer total_loss_pct_x100;
        integer total_flush_share_x100;
        integer total_load_stall_share_x100;
        integer total_false_load_stall_pct_x100;
        integer total_mul_hold_share_x100;
        integer total_other_bubble_share_x100;
        integer total_bht_alias_hit_pct_x100;
        integer total_bht_alias_lookup_pct_x100;
        integer total_bht_store_conflict_pct_x100;
        integer total_bht_store_imm_overlap_pct_x100;
        integer total_if_branch_nohit_pct_x100;
        integer total_if_branch_nohit_back_pct_x100;
        integer total_if_branch_nohit_back_ok_pct_x100;
        integer total_if_branch_nohit_back_redirect_pct_x100;
        integer total_mul_dep_pct_x100;
        integer total_mul_dep_d1_pct_x100;
        integer total_mul_dep_d2_pct_x100;
        integer total_mul_dep_d3_pct_x100;
        integer total_lookup;
        integer total_hit_rate_x100;
        integer total_nohit_rate_x100;
        integer total_jal_tgt_acc_x100;
        integer total_jalr_tgt_acc_x100;
        integer total_nonret_jalr;
        integer total_nonret_jalr_pred;
        integer total_nonret_jalr_correct;
        integer total_nonret_jalr_pred_rate_x100;
        integer total_nonret_jalr_acc_x100;
        begin
            total_dir_acc_x100      = pct_x100(total_dir_correct, total_branch);
            total_taken_prec_x100   = pct_x100(total_target_correct, total_pred_taken);
            total_taken_recall_x100 = pct_x100(total_target_correct, total_branch_taken);
            total_target_acc_x100   = pct_x100(total_target_correct, total_branch_both_taken);
            total_pred_cov_x100     = pct_x100(total_pred_taken, total_branch);
            total_miss_rate_x100    = pct_x100(total_mispredict, total_branch);
            total_ctrl_total        = total_branch + total_jal + total_jalr;
            total_ctrl_share_x100   = pct_x100(total_ctrl_total, total_instr);
            total_ipc_x1000         = (show_cycle != 0) ? ((total_instr * 1000 + (show_cycle / 2)) / show_cycle) : 0;
            total_jal_acc_x100      = pct_x100(total_jal_correct, total_jal);
            total_jal_pred_rate_x100= pct_x100(total_jal_pred, total_jal);
            total_jalr_acc_x100     = pct_x100(total_jalr_correct, total_jalr);
            total_jalr_pred_rate_x100 = pct_x100(total_jalr_pred, total_jalr);
            total_ret_acc_x100      = pct_x100(total_ret_correct, total_ret);
            total_ret_pred_rate_x100= pct_x100(total_ret_pred, total_ret);
            total_call_jalr_acc_x100 = pct_x100(total_call_jalr_correct, total_call_jalr);
            total_call_jalr_pred_rate_x100 = pct_x100(total_call_jalr_pred, total_call_jalr);
            total_indirect_jalr_acc_x100 = pct_x100(total_indirect_jalr_correct, total_indirect_jalr);
            total_indirect_jalr_pred_rate_x100 = pct_x100(total_indirect_jalr_pred, total_indirect_jalr);
            total_dir_wrong         = total_branch - total_dir_correct;
            total_target_wrong      = total_branch_both_taken - total_target_correct;
            total_branch_nt         = total_branch - total_branch_taken;
            total_nohit_exec            = total_branch_miss_taken + total_branch_miss_nt;
            total_nohit_taken_pct_x100  = pct_x100(total_branch_miss_taken, total_nohit_exec);
            total_nohit_nt_pct_x100     = pct_x100(total_branch_miss_nt, total_nohit_exec);
            total_nohit_forward_pct_x100 = pct_x100(total_branch_miss_forward, total_nohit_exec);
            total_nohit_backward_pct_x100 = pct_x100(total_branch_miss_backward, total_nohit_exec);
            total_loss              = show_cycle - total_instr;
            total_loss_pct_x100     = pct_x100(total_loss, show_cycle);
            total_flush_share_x100      = pct_x100(total_flush, total_loss);
            total_load_stall_share_x100 = pct_x100(total_load_stall, total_loss);
            total_false_load_stall_pct_x100 = pct_x100(total_false_load_stall, total_load_stall);
            total_mul_hold_share_x100   = pct_x100(total_mul_hold, total_loss);
            total_other_bubble_share_x100 = pct_x100(total_other_bubble, total_loss);
            total_bht_alias_hit_pct_x100 = pct_x100(total_bht_tag_alias, total_if_branch_hit);
            total_bht_alias_lookup_pct_x100 = pct_x100(total_bht_tag_alias, total_branch);
            total_bht_store_conflict_pct_x100 = pct_x100(total_bht_store_conflict, total_bht_store);
            total_bht_store_imm_overlap_pct_x100 = pct_x100(total_bht_store_imm_overlap, total_bht_store_conflict);
            total_if_branch_nohit_pct_x100 = pct_x100(total_if_branch_nohit, show_cycle);
            total_if_branch_nohit_back_pct_x100 = pct_x100(total_if_branch_nohit_back, total_if_branch_nohit);
            total_if_branch_nohit_back_ok_pct_x100 = pct_x100(total_if_branch_nohit_back_ok, total_if_branch_nohit_back);
            total_if_branch_nohit_back_redirect_pct_x100 = pct_x100(total_if_branch_nohit_back_redirect, total_if_branch_nohit_back);
            total_mul_dep_pct_x100   = pct_x100(total_mul_dep_slot, total_mul_follow_slot);
            total_mul_dep_d1_pct_x100 = pct_x100(total_mul_dep_d1, total_mul_exec);
            total_mul_dep_d2_pct_x100 = pct_x100(total_mul_dep_d2, total_mul_exec);
            total_mul_dep_d3_pct_x100 = pct_x100(total_mul_dep_d3, total_mul_exec);
            total_lookup             = total_if_branch_hit + total_if_branch_nohit;
            total_hit_rate_x100      = pct_x100(total_if_branch_hit, total_lookup);
            total_nohit_rate_x100    = pct_x100(total_if_branch_nohit, total_lookup);
            total_jal_tgt_acc_x100   = pct_x100(total_jal_correct, total_jal_pred);
            total_jalr_tgt_acc_x100  = pct_x100(total_jalr_correct, total_jalr_pred);
            total_nonret_jalr        = total_call_jalr + total_indirect_jalr;
            total_nonret_jalr_pred   = total_call_jalr_pred + total_indirect_jalr_pred;
            total_nonret_jalr_correct = total_call_jalr_correct + total_indirect_jalr_correct;
            total_nonret_jalr_pred_rate_x100 = pct_x100(total_nonret_jalr_pred, total_nonret_jalr);
            total_nonret_jalr_acc_x100       = pct_x100(total_nonret_jalr_correct, total_nonret_jalr);

            $display("");
            $display("[STAT][%0d cyc] KEY total: IPC=%0d.%03d  CTRL=%0d.%02d%%  |  BR dir_acc=%0d.%02d%%  taken_ok_prec=%0d.%02d%%  taken_ok_rec=%0d.%02d%%  miss=%0d.%02d%%",
                     show_cycle,
                     total_ipc_x1000 / 1000, total_ipc_x1000 % 1000,
                     total_ctrl_share_x100 / 100, total_ctrl_share_x100 % 100,
                     total_dir_acc_x100 / 100, total_dir_acc_x100 % 100,
                     total_taken_prec_x100 / 100, total_taken_prec_x100 % 100,
                     total_taken_recall_x100 / 100, total_taken_recall_x100 % 100,
                     total_miss_rate_x100 / 100, total_miss_rate_x100 % 100);
            $display("[STAT][%0d cyc] BR  total: all=%0d taken=%0d nt=%0d predT=%0d cover=%0d.%02d%% bothT=%0d dir_ok=%0d dir_bad=%0d tgt_ok=%0d tgt_bad=%0d tgt_acc=%0d.%02d%% mis=%0d",
                     show_cycle,
                     total_branch, total_branch_taken, total_branch_nt, total_pred_taken,
                     total_pred_cov_x100 / 100, total_pred_cov_x100 % 100,
                     total_branch_both_taken, total_dir_correct, total_dir_wrong,
                     total_target_correct, total_target_wrong,
                     total_target_acc_x100 / 100, total_target_acc_x100 % 100,
                     total_mispredict);
            $display("[STAT][%0d cyc] JAL total: exec=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%) tgt_ok=%0d.%02d%%",
                     show_cycle,
                     total_jal,
                     total_jal_pred, total_jal_pred_rate_x100 / 100, total_jal_pred_rate_x100 % 100,
                     total_jal_correct, total_jal_acc_x100 / 100, total_jal_acc_x100 % 100,
                     total_jal_tgt_acc_x100 / 100, total_jal_tgt_acc_x100 % 100);
            $display("[STAT][%0d cyc] JALR total: exec=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%) tgt_ok=%0d.%02d%%",
                     show_cycle,
                     total_jalr,
                     total_jalr_pred, total_jalr_pred_rate_x100 / 100, total_jalr_pred_rate_x100 % 100,
                     total_jalr_correct, total_jalr_acc_x100 / 100, total_jalr_acc_x100 % 100,
                     total_jalr_tgt_acc_x100 / 100, total_jalr_tgt_acc_x100 % 100);
            $display("[STAT][%0d cyc] JTB/RAS  : JTB(non-ret JALR) pred=%0d/%0d(%0d.%02d%%) ok=%0d/%0d(%0d.%02d%%)  |  RAS(RET) pred=%0d/%0d(%0d.%02d%%) ok=%0d/%0d(%0d.%02d%%)",
                     show_cycle,
                     total_nonret_jalr_pred, total_nonret_jalr,
                     total_nonret_jalr_pred_rate_x100 / 100, total_nonret_jalr_pred_rate_x100 % 100,
                     total_nonret_jalr_correct, total_nonret_jalr,
                     total_nonret_jalr_acc_x100 / 100, total_nonret_jalr_acc_x100 % 100,
                     total_ret_pred, total_ret,
                     total_ret_pred_rate_x100 / 100, total_ret_pred_rate_x100 % 100,
                     total_ret_correct, total_ret,
                     total_ret_acc_x100 / 100, total_ret_acc_x100 % 100);
            $display("[STAT][%0d cyc] JALR cls : ret=%0d/%0d/%0d(%0d.%02d%%)  call=%0d/%0d/%0d(%0d.%02d%%)  ind=%0d/%0d/%0d(%0d.%02d%%)",
                     show_cycle,
                     total_ret, total_ret_pred, total_ret_correct,
                     total_ret_acc_x100 / 100, total_ret_acc_x100 % 100,
                     total_call_jalr, total_call_jalr_pred, total_call_jalr_correct,
                     total_call_jalr_acc_x100 / 100, total_call_jalr_acc_x100 % 100,
                     total_indirect_jalr, total_indirect_jalr_pred, total_indirect_jalr_correct,
                     total_indirect_jalr_acc_x100 / 100, total_indirect_jalr_acc_x100 % 100);
            $display("[STAT][%0d cyc] BNOH total: exec=%0d  taken=%0d(%0d.%02d%%)  nt=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_nohit_exec,
                     total_branch_miss_taken,
                     total_nohit_taken_pct_x100 / 100, total_nohit_taken_pct_x100 % 100,
                     total_branch_miss_nt,
                     total_nohit_nt_pct_x100 / 100, total_nohit_nt_pct_x100 % 100);
            $display("[STAT][%0d cyc] BNOH dir : fwd=%0d(%0d.%02d%%)  back=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_branch_miss_forward,
                     total_nohit_forward_pct_x100 / 100, total_nohit_forward_pct_x100 % 100,
                     total_branch_miss_backward,
                     total_nohit_backward_pct_x100 / 100, total_nohit_backward_pct_x100 % 100);
            $display("[STAT][%0d cyc] BHT total: lookup=%0d hit=%0d(%0d.%02d%%) nohit=%0d(%0d.%02d%%) alias=%0d(%0d.%02d%% hit,%0d.%02d%% look)  store=%0d conflict=%0d(%0d.%02d%%) ovlp=%0d(%0d.%02d%% cf)",
                     show_cycle,
                     total_lookup,
                     total_if_branch_hit, total_hit_rate_x100 / 100, total_hit_rate_x100 % 100,
                     total_if_branch_nohit, total_nohit_rate_x100 / 100, total_nohit_rate_x100 % 100,
                     total_bht_tag_alias,
                     total_bht_alias_hit_pct_x100 / 100, total_bht_alias_hit_pct_x100 % 100,
                     total_bht_alias_lookup_pct_x100 / 100, total_bht_alias_lookup_pct_x100 % 100,
                     total_bht_store,
                     total_bht_store_conflict,
                     total_bht_store_conflict_pct_x100 / 100, total_bht_store_conflict_pct_x100 % 100,
                     total_bht_store_imm_overlap,
                     total_bht_store_imm_overlap_pct_x100 / 100, total_bht_store_imm_overlap_pct_x100 % 100);
            $display("[STAT][%0d cyc] FEND/BNOH: back_nohit=%0d(%0d.%02d%% of nohit)  back_ok=%0d(%0d.%02d%%)  back_redirect=%0d(%0d.%02d%%)  slot1_redirect=%0d",
                     show_cycle,
                     total_if_branch_nohit_back,
                     total_if_branch_nohit_back_pct_x100 / 100, total_if_branch_nohit_back_pct_x100 % 100,
                     total_if_branch_nohit_back_ok,
                     total_if_branch_nohit_back_ok_pct_x100 / 100, total_if_branch_nohit_back_ok_pct_x100 % 100,
                     total_if_branch_nohit_back_redirect,
                     total_if_branch_nohit_back_redirect_pct_x100 / 100, total_if_branch_nohit_back_redirect_pct_x100 % 100,
                     total_slot1_redirect);
            $display("[STAT][%0d cyc] LOSS total=%0d (%0d.%02d%% cyc): flush=%0d(%0d.%02d%%) ld=%0d(%0d.%02d%%) mul=%0d(%0d.%02d%%) bub=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_loss, total_loss_pct_x100 / 100, total_loss_pct_x100 % 100,
                     total_flush, total_flush_share_x100 / 100, total_flush_share_x100 % 100,
                     total_load_stall, total_load_stall_share_x100 / 100, total_load_stall_share_x100 % 100,
                     total_mul_hold, total_mul_hold_share_x100 / 100, total_mul_hold_share_x100 % 100,
                     total_other_bubble, total_other_bubble_share_x100 / 100, total_other_bubble_share_x100 % 100);
        end
    endtask

    task print_lduse3_stats;
        input integer show_cycle;
        input integer total_base;
        input integer total_i2_dep_i0;
        input integer total_i2_dep_i1;
        input integer total_both;
        integer base_cycle_pct_x100;
        integer i2_dep_i0_pct_x100;
        integer i2_dep_i1_pct_x100;
        integer both_pct_x100;
        begin
            base_cycle_pct_x100 = pct_x100(total_base, show_cycle);
            i2_dep_i0_pct_x100  = pct_x100(total_i2_dep_i0, total_base);
            i2_dep_i1_pct_x100  = pct_x100(total_i2_dep_i1, total_base);
            both_pct_x100       = pct_x100(total_both, total_base);

            $display("[STAT][%0d cyc] LDUSE3 base=%0d(%0d.%02d%% cyc): I0=LOAD && I1 depends on I0",
                     show_cycle,
                     total_base,
                     base_cycle_pct_x100 / 100, base_cycle_pct_x100 % 100);
            $display("[STAT][%0d cyc] LDUSE3 dep : I2<-I0=%0d(%0d.%02d%%)  I2<-I1=%0d(%0d.%02d%%)  both=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_i2_dep_i0,
                     i2_dep_i0_pct_x100 / 100, i2_dep_i0_pct_x100 % 100,
                     total_i2_dep_i1,
                     i2_dep_i1_pct_x100 / 100, i2_dep_i1_pct_x100 % 100,
                     total_both,
                     both_pct_x100 / 100, both_pct_x100 % 100);
        end
    endtask

    task print_slot1_branch_stats;
        input integer show_cycle;
        input integer total_branch;
        input integer total_slot1_branch_seen;
        input integer total_slot1_branch_issue;
        input integer total_slot1_branch_back;
        input integer total_slot1_branch_issue_back;
        integer seen_cycle_pct_x100;
        integer issue_cycle_pct_x100;
        integer issue_branch_pct_x100;
        integer back_seen_pct_x100;
        integer back_issue_pct_x100;
        begin
            seen_cycle_pct_x100  = pct_x100(total_slot1_branch_seen, show_cycle);
            issue_cycle_pct_x100 = pct_x100(total_slot1_branch_issue, show_cycle);
            issue_branch_pct_x100 = pct_x100(total_slot1_branch_issue, total_branch);
            back_seen_pct_x100   = pct_x100(total_slot1_branch_back, total_slot1_branch_seen);
            back_issue_pct_x100  = pct_x100(total_slot1_branch_issue_back, total_slot1_branch_issue);

            $display("[STAT][%0d cyc] SLOT1-BR seen=%0d(%0d.%02d%% cyc) issuable=%0d(%0d.%02d%% cyc, %0d.%02d%% of BR)",
                     show_cycle,
                     total_slot1_branch_seen,
                     seen_cycle_pct_x100 / 100, seen_cycle_pct_x100 % 100,
                     total_slot1_branch_issue,
                     issue_cycle_pct_x100 / 100, issue_cycle_pct_x100 % 100,
                     issue_branch_pct_x100 / 100, issue_branch_pct_x100 % 100);
            $display("[STAT][%0d cyc] SLOT1-BR bias: backward seen=%0d(%0d.%02d%%) issuable=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_slot1_branch_back,
                     back_seen_pct_x100 / 100, back_seen_pct_x100 % 100,
                     total_slot1_branch_issue_back,
                     back_issue_pct_x100 / 100, back_issue_pct_x100 % 100);
        end
    endtask

    task print_slot1_ctrl_stats;
        input integer show_cycle;
        integer b_acc_x100;
        integer b_pred_rate_x100;
        integer jal_acc_x100;
        integer jal_pred_rate_x100;
        integer jalr_acc_x100;
        integer jalr_pred_rate_x100;
        integer ret_acc_x100;
        integer ret_pred_rate_x100;
        integer call_acc_x100;
        integer call_pred_rate_x100;
        integer indir_acc_x100;
        integer indir_pred_rate_x100;
        integer b_taken_pct_x100;
        integer b_nt_pct_x100;
        integer b_fwd_pct_x100;
        integer b_back_pct_x100;
        integer b_fwd_taken_pct_x100;
        integer b_fwd_nt_pct_x100;
        integer b_back_taken_pct_x100;
        integer b_back_nt_pct_x100;
        integer pred_effective_valid_pct_x100;
        begin
            b_acc_x100 = pct_x100(slot1_b_correct_total, slot1_b_exec_total);
            b_pred_rate_x100 = pct_x100(slot1_b_pred_total, slot1_b_exec_total);
            jal_acc_x100 = pct_x100(slot1_jal_correct_total, slot1_jal_exec_total);
            jal_pred_rate_x100 = pct_x100(slot1_jal_pred_total, slot1_jal_exec_total);
            jalr_acc_x100 = pct_x100(slot1_jalr_correct_total, slot1_jalr_exec_total);
            jalr_pred_rate_x100 = pct_x100(slot1_jalr_pred_total, slot1_jalr_exec_total);
            ret_acc_x100 = pct_x100(slot1_ret_correct_total, slot1_ret_exec_total);
            ret_pred_rate_x100 = pct_x100(slot1_ret_pred_total, slot1_ret_exec_total);
            call_acc_x100 = pct_x100(slot1_call_jalr_correct_total, slot1_call_jalr_exec_total);
            call_pred_rate_x100 = pct_x100(slot1_call_jalr_pred_total, slot1_call_jalr_exec_total);
            indir_acc_x100 = pct_x100(slot1_indirect_jalr_correct_total, slot1_indirect_jalr_exec_total);
            indir_pred_rate_x100 = pct_x100(slot1_indirect_jalr_pred_total, slot1_indirect_jalr_exec_total);
            b_taken_pct_x100 = pct_x100(slot1_b_taken_total, slot1_b_exec_total);
            b_nt_pct_x100 = pct_x100(slot1_b_nt_total, slot1_b_exec_total);
            b_fwd_pct_x100 = pct_x100(slot1_b_fwd_total, slot1_b_exec_total);
            b_back_pct_x100 = pct_x100(slot1_b_back_total, slot1_b_exec_total);
            b_fwd_taken_pct_x100 = pct_x100(slot1_b_fwd_taken_total, slot1_b_fwd_total);
            b_fwd_nt_pct_x100 = pct_x100(slot1_b_fwd_nt_total, slot1_b_fwd_total);
            b_back_taken_pct_x100 = pct_x100(slot1_b_back_taken_total, slot1_b_back_total);
            b_back_nt_pct_x100 = pct_x100(slot1_b_back_nt_total, slot1_b_back_total);
            pred_effective_valid_pct_x100 = pct_x100(slot1_pred_effective_total - slot1_pred_without_valid_total,
                                                      slot1_pred_effective_total);

            $display("[STAT][%0d cyc] SLOT1-USE tracked=%0d matched=%0d dropped=%0d pred_effective=%0d invalid_pred=%0d raw_invalid=%0d valid_use=%0d.%02d%%",
                     show_cycle,
                     slot1_ctrl_track_total, slot1_ctrl_match_total, slot1_ctrl_drop_total,
                     slot1_pred_effective_total, slot1_pred_without_valid_total, slot1_raw_invalid_total,
                     pred_effective_valid_pct_x100 / 100, pred_effective_valid_pct_x100 % 100);
            $display("[STAT][%0d cyc] SLOT1-B  exec=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%) taken=%0d(%0d.%02d%%) nt=%0d(%0d.%02d%%)",
                     show_cycle,
                     slot1_b_exec_total,
                     slot1_b_pred_total, b_pred_rate_x100 / 100, b_pred_rate_x100 % 100,
                     slot1_b_correct_total, b_acc_x100 / 100, b_acc_x100 % 100,
                     slot1_b_taken_total, b_taken_pct_x100 / 100, b_taken_pct_x100 % 100,
                     slot1_b_nt_total, b_nt_pct_x100 / 100, b_nt_pct_x100 % 100);
            $display("[STAT][%0d cyc] SLOT1-BD fwd=%0d(%0d.%02d%%): T=%0d(%0d.%02d%%) NT=%0d(%0d.%02d%%)  back=%0d(%0d.%02d%%): T=%0d(%0d.%02d%%) NT=%0d(%0d.%02d%%)",
                     show_cycle,
                     slot1_b_fwd_total, b_fwd_pct_x100 / 100, b_fwd_pct_x100 % 100,
                     slot1_b_fwd_taken_total, b_fwd_taken_pct_x100 / 100, b_fwd_taken_pct_x100 % 100,
                     slot1_b_fwd_nt_total, b_fwd_nt_pct_x100 / 100, b_fwd_nt_pct_x100 % 100,
                     slot1_b_back_total, b_back_pct_x100 / 100, b_back_pct_x100 % 100,
                     slot1_b_back_taken_total, b_back_taken_pct_x100 / 100, b_back_taken_pct_x100 % 100,
                     slot1_b_back_nt_total, b_back_nt_pct_x100 / 100, b_back_nt_pct_x100 % 100);
            $display("[STAT][%0d cyc] SLOT1-J  JAL exec=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)",
                     show_cycle,
                     slot1_jal_exec_total,
                     slot1_jal_pred_total, jal_pred_rate_x100 / 100, jal_pred_rate_x100 % 100,
                     slot1_jal_correct_total, jal_acc_x100 / 100, jal_acc_x100 % 100);
            $display("[STAT][%0d cyc] SLOT1-JR JALR exec=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)  ret=%0d/%0d/%0d(%0d.%02d%%) call=%0d/%0d/%0d(%0d.%02d%%) ind=%0d/%0d/%0d(%0d.%02d%%)",
                     show_cycle,
                     slot1_jalr_exec_total,
                     slot1_jalr_pred_total, jalr_pred_rate_x100 / 100, jalr_pred_rate_x100 % 100,
                     slot1_jalr_correct_total, jalr_acc_x100 / 100, jalr_acc_x100 % 100,
                     slot1_ret_exec_total, slot1_ret_pred_total, slot1_ret_correct_total,
                     ret_acc_x100 / 100, ret_acc_x100 % 100,
                     slot1_call_jalr_exec_total, slot1_call_jalr_pred_total, slot1_call_jalr_correct_total,
                     call_acc_x100 / 100, call_acc_x100 % 100,
                     slot1_indirect_jalr_exec_total, slot1_indirect_jalr_pred_total, slot1_indirect_jalr_correct_total,
                     indir_acc_x100 / 100, indir_acc_x100 % 100);
        end
    endtask

    task print_branch_pc_stats;
        input integer total_branch_exec;
        integer idx;
        integer order_idx;
        integer pick_idx;
        integer pick_exec;
        integer exec_pct_x100;
        integer taken_rate_x100;
        reg [BRANCH_PC_STAT_SLOTS-1:0] printed_mask;
        begin
            $display("[STAT][%0d cyc] BRANCH PC histogram:", stat_cycle_total);
            printed_mask = {BRANCH_PC_STAT_SLOTS{1'b0}};
            for (order_idx = 0; order_idx < BRANCH_PC_STAT_SLOTS; order_idx = order_idx + 1) begin
                pick_idx  = -1;
                pick_exec = 0;
                for (idx = 0; idx < BRANCH_PC_STAT_SLOTS; idx = idx + 1) begin
                    if (branch_pc_valid[idx] && !printed_mask[idx]
                            && ((pick_idx == -1)
                             || (branch_pc_exec[idx] < pick_exec)
                             || ((branch_pc_exec[idx] == pick_exec) && (branch_pc_addr[idx] < branch_pc_addr[pick_idx])))) begin
                        pick_idx  = idx;
                        pick_exec = branch_pc_exec[idx];
                    end
                end

                if (pick_idx != -1) begin
                    printed_mask[pick_idx] = 1'b1;
                    exec_pct_x100 = pct_x100(branch_pc_exec[pick_idx], total_branch_exec);
                    taken_rate_x100 = pct_x100(branch_pc_taken[pick_idx], branch_pc_exec[pick_idx]);
                    $display("[STAT][%0d cyc]   pc=%08x  exec=%0d(%0d.%02d%% of br)  predT=%0d  dir_ok=%0d  mis=%0d  tk=%0d.%02d%%",
                             stat_cycle_total,
                             branch_pc_addr[pick_idx],
                             branch_pc_exec[pick_idx],
                             exec_pct_x100 / 100,
                             exec_pct_x100 % 100,
                             branch_pc_pred[pick_idx],
                             branch_pc_dir_ok[pick_idx],
                             branch_pc_mis[pick_idx],
                             taken_rate_x100 / 100,
                             taken_rate_x100 % 100);
                end
            end
        end
    endtask

    task print_bht_entry_stats;
        integer idx;
        integer order_idx;
        integer pick_idx;
        integer pick_lookup;
        integer pick_exec;
        integer pick_alias;
        integer touched_entries;
        integer active_entries;
        integer lookup_used_entries;
        integer exec_used_entries;
        integer alias_hot_entries;
        integer conflict_hot_entries;
        integer cold_entries;
        integer total_lookup;
        integer total_exec;
        integer total_alias;
        integer total_conflict;
        integer total_store;
        integer avg_lookup_per_used;
        integer avg_exec_per_used;
        integer max_lookup_idx;
        integer max_lookup;
        integer max_exec_idx;
        integer max_exec;
        integer max_mis_idx;
        integer max_mis;
        integer max_alias_idx;
        integer max_alias;
        integer max_conflict_idx;
        integer max_conflict;
        integer lookup_share_x100;
        integer exec_share_x100;
        integer hit_rate_x100;
        integer nohit_rate_x100;
        integer dir_acc_x100;
        integer taken_rate_x100;
        integer alias_hit_rate_x100;
        integer alias_lookup_rate_x100;
        integer conflict_store_rate_x100;
        integer heat_fd;
        reg [BHT_STAT_ENTRY_NUM-1:0] printed_mask;
        begin
            touched_entries      = 0;
            active_entries       = 0;
            lookup_used_entries  = 0;
            exec_used_entries    = 0;
            alias_hot_entries    = 0;
            conflict_hot_entries = 0;
            cold_entries         = 0;
            total_lookup         = 0;
            total_exec           = 0;
            total_alias          = 0;
            total_conflict       = 0;
            total_store          = 0;
            avg_lookup_per_used  = 0;
            avg_exec_per_used    = 0;
            max_lookup_idx       = -1;
            max_lookup           = 0;
            max_exec_idx         = -1;
            max_exec             = 0;
            max_mis_idx          = -1;
            max_mis              = 0;
            max_alias_idx        = -1;
            max_alias            = 0;
            max_conflict_idx     = -1;
            max_conflict         = 0;

            for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                if (u_cpu.u_branch_predictor.branch_valid[idx])
                    active_entries = active_entries + 1;
                if ((bht_entry_if_lookup[idx] != 0)
                        || (bht_entry_ex_exec[idx] != 0)
                        || (bht_entry_store[idx] != 0)
                        || u_cpu.u_branch_predictor.branch_valid[idx])
                    touched_entries = touched_entries + 1;
                else
                    cold_entries = cold_entries + 1;
                if (bht_entry_if_lookup[idx] != 0)
                    lookup_used_entries = lookup_used_entries + 1;
                if (bht_entry_ex_exec[idx] != 0)
                    exec_used_entries = exec_used_entries + 1;
                if (bht_entry_alias[idx] != 0)
                    alias_hot_entries = alias_hot_entries + 1;
                if (bht_entry_conflict[idx] != 0)
                    conflict_hot_entries = conflict_hot_entries + 1;

                total_lookup   = total_lookup + bht_entry_if_lookup[idx];
                total_exec     = total_exec + bht_entry_ex_exec[idx];
                total_alias    = total_alias + bht_entry_alias[idx];
                total_conflict = total_conflict + bht_entry_conflict[idx];
                total_store    = total_store + bht_entry_store[idx];

                if ((max_lookup_idx == -1)
                        || (bht_entry_if_lookup[idx] > max_lookup)
                        || ((bht_entry_if_lookup[idx] == max_lookup) && (idx < max_lookup_idx))) begin
                    max_lookup_idx = idx;
                    max_lookup     = bht_entry_if_lookup[idx];
                end
                if ((max_exec_idx == -1)
                        || (bht_entry_ex_exec[idx] > max_exec)
                        || ((bht_entry_ex_exec[idx] == max_exec) && (idx < max_exec_idx))) begin
                    max_exec_idx = idx;
                    max_exec     = bht_entry_ex_exec[idx];
                end
                if ((max_mis_idx == -1)
                        || (bht_entry_ex_mis[idx] > max_mis)
                        || ((bht_entry_ex_mis[idx] == max_mis) && (idx < max_mis_idx))) begin
                    max_mis_idx = idx;
                    max_mis     = bht_entry_ex_mis[idx];
                end
                if ((max_alias_idx == -1)
                        || (bht_entry_alias[idx] > max_alias)
                        || ((bht_entry_alias[idx] == max_alias) && (idx < max_alias_idx))) begin
                    max_alias_idx = idx;
                    max_alias     = bht_entry_alias[idx];
                end
                if ((max_conflict_idx == -1)
                        || (bht_entry_conflict[idx] > max_conflict)
                        || ((bht_entry_conflict[idx] == max_conflict) && (idx < max_conflict_idx))) begin
                    max_conflict_idx = idx;
                    max_conflict     = bht_entry_conflict[idx];
                end
            end

            if (lookup_used_entries != 0)
                avg_lookup_per_used = (total_lookup + (lookup_used_entries / 2)) / lookup_used_entries;
            if (exec_used_entries != 0)
                avg_exec_per_used = (total_exec + (exec_used_entries / 2)) / exec_used_entries;

            $display("[STAT][%0d cyc] BHTE total: entry=%0d active=%0d touched=%0d cold=%0d  |  lookup_used=%0d avg=%0d  exec_used=%0d avg=%0d",
                     stat_cycle_total,
                     BHT_STAT_ENTRY_NUM,
                     active_entries,
                     touched_entries,
                     cold_entries,
                     lookup_used_entries,
                     avg_lookup_per_used,
                     exec_used_entries,
                     avg_exec_per_used);
            $display("[STAT][%0d cyc] BHTE hot  : maxLook=idx%0d/%0d  maxExec=idx%0d/%0d  maxMis=idx%0d/%0d  maxChaos=idx%0d/%0d  |  alias_hot=%0d conflict_hot=%0d",
                     stat_cycle_total,
                     max_lookup_idx, max_lookup,
                     max_exec_idx, max_exec,
                     max_mis_idx, max_mis,
                     max_alias_idx, max_alias,
                     alias_hot_entries,
                     conflict_hot_entries);
            $display("[STAT][%0d cyc] BHTE sum  : look=%0d hit=%0d nohit=%0d alias=%0d  |  exec=%0d tk=%0d predT=%0d mis=%0d  |  store=%0d conflict=%0d ovlp=%0d",
                     stat_cycle_total,
                     total_lookup,
                     if_branch_hit_total,
                     if_branch_nohit_total,
                     total_alias,
                     total_exec,
                     branch_taken_total,
                     pred_taken_total,
                     mispredict_total,
                     total_store,
                     total_conflict,
                     bht_store_imm_overlap_total);
            $display("[STAT][%0d cyc] BHTE chaos: same_idx_same_tag=%0d(%0d.%02d%% of hit, %0d.%02d%% of look)  |  repl_conflict=%0d(%0d.%02d%% of store)",
                     stat_cycle_total,
                     total_alias,
                     pct_x100(total_alias, if_branch_hit_total) / 100, pct_x100(total_alias, if_branch_hit_total) % 100,
                     pct_x100(total_alias, total_lookup) / 100, pct_x100(total_alias, total_lookup) % 100,
                     total_conflict,
                     pct_x100(total_conflict, total_store) / 100, pct_x100(total_conflict, total_store) % 100);
            $display("[STAT][%0d cyc] BHTE histogram (hot entries first):", stat_cycle_total);

            printed_mask = {BHT_STAT_ENTRY_NUM{1'b0}};
            for (order_idx = 0; order_idx < BHT_STAT_ENTRY_NUM; order_idx = order_idx + 1) begin
                pick_idx    = -1;
                pick_lookup = -1;
                pick_exec   = -1;
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    if (!printed_mask[idx]
                            && ((bht_entry_if_lookup[idx] != 0)
                             || (bht_entry_ex_exec[idx] != 0)
                             || (bht_entry_store[idx] != 0)
                             || u_cpu.u_branch_predictor.branch_valid[idx])
                            && ((pick_idx == -1)
                             || (bht_entry_if_lookup[idx] > pick_lookup)
                             || ((bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] > pick_exec))
                             || ((bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] == pick_exec) && (idx < pick_idx)))) begin
                        pick_idx    = idx;
                        pick_lookup = bht_entry_if_lookup[idx];
                        pick_exec   = bht_entry_ex_exec[idx];
                    end
                end

                if (pick_idx != -1) begin
                    printed_mask[pick_idx] = 1'b1;
                    lookup_share_x100 = pct_x100(bht_entry_if_lookup[pick_idx], total_lookup);
                    exec_share_x100   = pct_x100(bht_entry_ex_exec[pick_idx], total_exec);
                    hit_rate_x100     = pct_x100(bht_entry_if_hit[pick_idx], bht_entry_if_lookup[pick_idx]);
                    nohit_rate_x100   = pct_x100(bht_entry_ex_nohit[pick_idx], bht_entry_ex_exec[pick_idx]);
                    dir_acc_x100      = pct_x100(bht_entry_ex_dir_ok[pick_idx], bht_entry_ex_exec[pick_idx]);
                    taken_rate_x100   = pct_x100(bht_entry_ex_taken[pick_idx], bht_entry_ex_exec[pick_idx]);
                    alias_hit_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_hit[pick_idx]);
                    alias_lookup_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_lookup[pick_idx]);
                    conflict_store_rate_x100 = pct_x100(bht_entry_conflict[pick_idx], bht_entry_store[pick_idx]);
                    $display("[STAT][%0d cyc]   idx=%0d v=%0d tag=%0x ctr=%02b owner=%08x  |  look=%0d(%0d.%02d%%) hit=%0d(%0d.%02d%%) nohit=%0d predT=%0d chaos=%0d(%0d.%02d%%hit,%0d.%02d%%look)",
                             stat_cycle_total,
                             pick_idx,
                             u_cpu.u_branch_predictor.branch_valid[pick_idx],
                             u_cpu.u_branch_predictor.branch_tag[pick_idx],
                             u_cpu.u_branch_predictor.bht_ctr[pick_idx],
                             bht_meta_pc[pick_idx],
                             bht_entry_if_lookup[pick_idx],
                             lookup_share_x100 / 100, lookup_share_x100 % 100,
                             bht_entry_if_hit[pick_idx],
                             hit_rate_x100 / 100, hit_rate_x100 % 100,
                             bht_entry_if_nohit[pick_idx],
                             bht_entry_if_pred[pick_idx],
                             bht_entry_alias[pick_idx],
                             alias_hit_rate_x100 / 100, alias_hit_rate_x100 % 100,
                             alias_lookup_rate_x100 / 100, alias_lookup_rate_x100 % 100);
                    $display("[STAT][%0d cyc]      exec=%0d(%0d.%02d%%) tk=%0d(%0d.%02d%%) predT=%0d dir_ok=%0d(%0d.%02d%%) mis=%0d nohit=%0d(%0d.%02d%%) dir=f%0d/b%0d  |  st=%0d cf=%0d(%0d.%02d%%st) ov=%0d",
                             stat_cycle_total,
                             bht_entry_ex_exec[pick_idx],
                             exec_share_x100 / 100, exec_share_x100 % 100,
                             bht_entry_ex_taken[pick_idx],
                             taken_rate_x100 / 100, taken_rate_x100 % 100,
                             bht_entry_ex_pred[pick_idx],
                             bht_entry_ex_dir_ok[pick_idx],
                             dir_acc_x100 / 100, dir_acc_x100 % 100,
                             bht_entry_ex_mis[pick_idx],
                             bht_entry_ex_nohit[pick_idx],
                             nohit_rate_x100 / 100, nohit_rate_x100 % 100,
                             bht_entry_fwd[pick_idx],
                             bht_entry_back[pick_idx],
                             bht_entry_store[pick_idx],
                             bht_entry_conflict[pick_idx],
                             conflict_store_rate_x100 / 100, conflict_store_rate_x100 % 100,
                             bht_entry_imm_ovlp[pick_idx]);
                end
            end

            $display("[STAT][%0d cyc] BHTE chaos histogram (same idx+tag first):", stat_cycle_total);
            printed_mask = {BHT_STAT_ENTRY_NUM{1'b0}};
            for (order_idx = 0; order_idx < BHT_STAT_ENTRY_NUM; order_idx = order_idx + 1) begin
                pick_idx    = -1;
                pick_alias  = -1;
                pick_lookup = -1;
                pick_exec   = -1;
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    if (!printed_mask[idx]
                            && ((bht_entry_if_lookup[idx] != 0)
                             || (bht_entry_ex_exec[idx] != 0)
                             || (bht_entry_store[idx] != 0)
                             || u_cpu.u_branch_predictor.branch_valid[idx])
                            && ((pick_idx == -1)
                             || (bht_entry_alias[idx] > pick_alias)
                             || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] > pick_lookup))
                             || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] > pick_exec))
                             || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] == pick_exec) && (idx < pick_idx)))) begin
                        pick_idx    = idx;
                        pick_alias  = bht_entry_alias[idx];
                        pick_lookup = bht_entry_if_lookup[idx];
                        pick_exec   = bht_entry_ex_exec[idx];
                    end
                end

                if (pick_idx != -1) begin
                    printed_mask[pick_idx] = 1'b1;
                    alias_hit_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_hit[pick_idx]);
                    alias_lookup_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_lookup[pick_idx]);
                    conflict_store_rate_x100 = pct_x100(bht_entry_conflict[pick_idx], bht_entry_store[pick_idx]);
                    dir_acc_x100 = pct_x100(bht_entry_ex_dir_ok[pick_idx], bht_entry_ex_exec[pick_idx]);
                    $display("[STAT][%0d cyc]   idx=%0d owner=%08x tag=%0x  |  chaos=%0d(%0d.%02d%%hit,%0d.%02d%%look) cf=%0d(%0d.%02d%%st)  |  look=%0d hit=%0d exec=%0d mis=%0d dir_ok=%0d(%0d.%02d%%)",
                             stat_cycle_total,
                             pick_idx,
                             bht_meta_pc[pick_idx],
                             u_cpu.u_branch_predictor.branch_tag[pick_idx],
                             bht_entry_alias[pick_idx],
                             alias_hit_rate_x100 / 100, alias_hit_rate_x100 % 100,
                             alias_lookup_rate_x100 / 100, alias_lookup_rate_x100 % 100,
                             bht_entry_conflict[pick_idx],
                             conflict_store_rate_x100 / 100, conflict_store_rate_x100 % 100,
                             bht_entry_if_lookup[pick_idx],
                             bht_entry_if_hit[pick_idx],
                             bht_entry_ex_exec[pick_idx],
                             bht_entry_ex_mis[pick_idx],
                             bht_entry_ex_dir_ok[pick_idx],
                             dir_acc_x100 / 100, dir_acc_x100 % 100);
                end
            end

            heat_fd = $fopen("bht_entry_heatmap.txt", "w");
            if (heat_fd != 0) begin
                $fdisplay(heat_fd, "BHT entry heat histogram");
                $fdisplay(heat_fd, "cycle=%0d entry=%0d active=%0d touched=%0d cold=%0d",
                          stat_cycle_total, BHT_STAT_ENTRY_NUM, active_entries, touched_entries, cold_entries);
                $fdisplay(heat_fd, "sum: look=%0d hit=%0d nohit=%0d chaos=%0d exec=%0d mis=%0d store=%0d conflict=%0d",
                          total_lookup, if_branch_hit_total, if_branch_nohit_total, total_alias,
                          total_exec, mispredict_total, total_store, total_conflict);
                $fdisplay(heat_fd, "max: look=idx%0d/%0d exec=idx%0d/%0d mis=idx%0d/%0d chaos=idx%0d/%0d conflict=idx%0d/%0d",
                          max_lookup_idx, max_lookup, max_exec_idx, max_exec,
                          max_mis_idx, max_mis, max_alias_idx, max_alias,
                          max_conflict_idx, max_conflict);
                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "Each bar is normalized to the max value of that metric in this run; width=40.");
                $fdisplay(heat_fd, "Columns: idx owner tag valid ctr value percentage heatbar");
                $fdisplay(heat_fd, "");

                $fdisplay(heat_fd, "[LOOKUP HEAT]");
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    lookup_share_x100 = pct_x100(bht_entry_if_lookup[idx], total_lookup);
                    $fwrite(heat_fd, "idx=%02d owner=%08x tag=%0x v=%0d ctr=%02b look=%6d %3d.%02d%% |",
                            idx, bht_meta_pc[idx], u_cpu.u_branch_predictor.branch_tag[idx],
                            u_cpu.u_branch_predictor.branch_valid[idx], u_cpu.u_branch_predictor.bht_ctr[idx],
                            bht_entry_if_lookup[idx], lookup_share_x100 / 100, lookup_share_x100 % 100);
                    write_heat_bar(heat_fd, bht_entry_if_lookup[idx], max_lookup);
                    $fdisplay(heat_fd, "|");
                end

                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "[EXEC HEAT]");
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    exec_share_x100 = pct_x100(bht_entry_ex_exec[idx], total_exec);
                    $fwrite(heat_fd, "idx=%02d owner=%08x tag=%0x v=%0d ctr=%02b exec=%6d %3d.%02d%% |",
                            idx, bht_meta_pc[idx], u_cpu.u_branch_predictor.branch_tag[idx],
                            u_cpu.u_branch_predictor.branch_valid[idx], u_cpu.u_branch_predictor.bht_ctr[idx],
                            bht_entry_ex_exec[idx], exec_share_x100 / 100, exec_share_x100 % 100);
                    write_heat_bar(heat_fd, bht_entry_ex_exec[idx], max_exec);
                    $fdisplay(heat_fd, "|");
                end

                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "[MISS HEAT]");
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    dir_acc_x100 = pct_x100(bht_entry_ex_dir_ok[idx], bht_entry_ex_exec[idx]);
                    $fwrite(heat_fd, "idx=%02d owner=%08x tag=%0x v=%0d ctr=%02b mis =%6d acc=%3d.%02d%% |",
                            idx, bht_meta_pc[idx], u_cpu.u_branch_predictor.branch_tag[idx],
                            u_cpu.u_branch_predictor.branch_valid[idx], u_cpu.u_branch_predictor.bht_ctr[idx],
                            bht_entry_ex_mis[idx], dir_acc_x100 / 100, dir_acc_x100 % 100);
                    write_heat_bar(heat_fd, bht_entry_ex_mis[idx], max_mis);
                    $fdisplay(heat_fd, "|");
                end

                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "[CHAOS HEAT: same idx + same tag + different owner PC]");
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    alias_hit_rate_x100 = pct_x100(bht_entry_alias[idx], bht_entry_if_hit[idx]);
                    alias_lookup_rate_x100 = pct_x100(bht_entry_alias[idx], bht_entry_if_lookup[idx]);
                    $fwrite(heat_fd, "idx=%02d owner=%08x tag=%0x v=%0d ctr=%02b chaos=%5d %3d.%02d%%hit %3d.%02d%%look |",
                            idx, bht_meta_pc[idx], u_cpu.u_branch_predictor.branch_tag[idx],
                            u_cpu.u_branch_predictor.branch_valid[idx], u_cpu.u_branch_predictor.bht_ctr[idx],
                            bht_entry_alias[idx],
                            alias_hit_rate_x100 / 100, alias_hit_rate_x100 % 100,
                            alias_lookup_rate_x100 / 100, alias_lookup_rate_x100 % 100);
                    write_heat_bar(heat_fd, bht_entry_alias[idx], max_alias);
                    $fdisplay(heat_fd, "|");
                end

                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "[CONFLICT HEAT]");
                for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                    conflict_store_rate_x100 = pct_x100(bht_entry_conflict[idx], bht_entry_store[idx]);
                    $fwrite(heat_fd, "idx=%02d owner=%08x tag=%0x v=%0d ctr=%02b cf=%5d %3d.%02d%%store |",
                            idx, bht_meta_pc[idx], u_cpu.u_branch_predictor.branch_tag[idx],
                            u_cpu.u_branch_predictor.branch_valid[idx], u_cpu.u_branch_predictor.bht_ctr[idx],
                            bht_entry_conflict[idx],
                            conflict_store_rate_x100 / 100, conflict_store_rate_x100 % 100);
                    write_heat_bar(heat_fd, bht_entry_conflict[idx], max_conflict);
                    $fdisplay(heat_fd, "|");
                end

                $fdisplay(heat_fd, "");
                $fdisplay(heat_fd, "[CHAOS HOT ORDER]");
                printed_mask = {BHT_STAT_ENTRY_NUM{1'b0}};
                for (order_idx = 0; order_idx < BHT_STAT_ENTRY_NUM; order_idx = order_idx + 1) begin
                    pick_idx    = -1;
                    pick_alias  = -1;
                    pick_lookup = -1;
                    pick_exec   = -1;
                    for (idx = 0; idx < BHT_STAT_ENTRY_NUM; idx = idx + 1) begin
                        if (!printed_mask[idx]
                                && ((bht_entry_if_lookup[idx] != 0)
                                 || (bht_entry_ex_exec[idx] != 0)
                                 || (bht_entry_store[idx] != 0)
                                 || u_cpu.u_branch_predictor.branch_valid[idx])
                                && ((pick_idx == -1)
                                 || (bht_entry_alias[idx] > pick_alias)
                                 || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] > pick_lookup))
                                 || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] > pick_exec))
                                 || ((bht_entry_alias[idx] == pick_alias) && (bht_entry_if_lookup[idx] == pick_lookup) && (bht_entry_ex_exec[idx] == pick_exec) && (idx < pick_idx)))) begin
                            pick_idx    = idx;
                            pick_alias  = bht_entry_alias[idx];
                            pick_lookup = bht_entry_if_lookup[idx];
                            pick_exec   = bht_entry_ex_exec[idx];
                        end
                    end

                    if (pick_idx != -1) begin
                        printed_mask[pick_idx] = 1'b1;
                        alias_hit_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_hit[pick_idx]);
                        alias_lookup_rate_x100 = pct_x100(bht_entry_alias[pick_idx], bht_entry_if_lookup[pick_idx]);
                        dir_acc_x100 = pct_x100(bht_entry_ex_dir_ok[pick_idx], bht_entry_ex_exec[pick_idx]);
                        $fwrite(heat_fd, "rank=%02d idx=%02d owner=%08x tag=%0x chaos=%5d %3d.%02d%%hit %3d.%02d%%look mis=%5d acc=%3d.%02d%% |",
                                order_idx, pick_idx, bht_meta_pc[pick_idx],
                                u_cpu.u_branch_predictor.branch_tag[pick_idx],
                                bht_entry_alias[pick_idx],
                                alias_hit_rate_x100 / 100, alias_hit_rate_x100 % 100,
                                alias_lookup_rate_x100 / 100, alias_lookup_rate_x100 % 100,
                                bht_entry_ex_mis[pick_idx],
                                dir_acc_x100 / 100, dir_acc_x100 % 100);
                        write_heat_bar(heat_fd, bht_entry_alias[pick_idx], max_alias);
                        $fdisplay(heat_fd, "|");
                    end
                end

                $fclose(heat_fd);
                $display("[STAT][%0d cyc] BHTE heatmap file: bht_entry_heatmap.txt", stat_cycle_total);
            end else begin
                $display("[STAT][%0d cyc] BHTE heatmap file open failed: bht_entry_heatmap.txt", stat_cycle_total);
            end
        end
    endtask

    task print_jalr_pc_stats;
        integer idx;
        integer acc_x100;
        begin
            $display("[STAT][%0d cyc] JALR PC histogram:", stat_cycle_total);
            for (idx = 0; idx < JALR_PC_STAT_SLOTS; idx = idx + 1) begin
                if (jalr_pc_valid[idx]) begin
                    acc_x100 = pct_x100(jalr_pc_ok[idx], jalr_pc_exec[idx]);
                    $display("[STAT][%0d cyc]   pc=%08x  exec=%0d  pred=%0d  ok=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                             stat_cycle_total,
                             jalr_pc_addr[idx],
                             jalr_pc_exec[idx],
                             jalr_pc_pred[idx],
                             jalr_pc_ok[idx],
                             acc_x100 / 100,
                             acc_x100 % 100,
                             jalr_pc_ret[idx],
                             jalr_pc_call[idx],
                             jalr_pc_other[idx]);
                end
            end
        end
    endtask

    cpu u_cpu(
        .clk   (clk  ),
        .rst_n (rst_n),
        .led   (led  )
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        cycle_count = 0;
        stat_cycle_total = 0;
        timer_req_count = 0;
        stat_active = 1'b0;
        dhry_key_pos = 0;
        dhry_dps_accum = 0;
        dhry_dps_value = 0;
        dhry_capture_active = 1'b0;
        dhry_seen_digit = 1'b0;
        dhry_dps_valid = 1'b0;
        uart_ipc_key_pos = 0;
        uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
        uart_bench_c_seen_digit = 1'b0;
        uart_bench_i_seen_digit = 1'b0;
        uart_bench_c_accum = 64'd0;
        uart_bench_i_accum = 64'd0;
        uart_bench_cycle_value = 64'd0;
        uart_bench_instret_value = 64'd0;
        uart_bench_cycle_valid = 1'b0;
        uart_bench_instret_valid = 1'b0;
        tb_retire_total = 64'd0;
        tb_wb_instret_hi_q = 1'b0;
        tb_wb_instret_lo_q = 1'b0;
        tb_instret_snap_state = 0;
        tb_instret_snap_count = 0;
        tb_instret_start_valid = 1'b0;
        tb_instret_stop_valid = 1'b0;
        tb_instret_start_retire = 64'd0;
        tb_instret_stop_retire = 64'd0;

        instr_total = 0;
        flush_total = 0;
        load_stall_total = 0;
        false_load_stall_total = 0;
        lduse3_base_total = 0;
        lduse3_i2_dep_i0_total = 0;
        lduse3_i2_dep_i1_total = 0;
        lduse3_i2_dep_both_total = 0;
        mul_hold_total = 0;
        other_bubble_total = 0;
        wb_commit_total = 0;
        branch_total = 0;
        branch_taken_total = 0;
        branch_both_taken_total = 0;
        jal_total = 0;
        jal_pred_total = 0;
        jal_correct_total = 0;
        jalr_total = 0;
        jalr_pred_total = 0;
        jalr_correct_total = 0;
        ret_total = 0;
        ret_pred_total = 0;
        ret_correct_total = 0;
        call_jalr_total = 0;
        call_jalr_pred_total = 0;
        call_jalr_correct_total = 0;
        indirect_jalr_total = 0;
        indirect_jalr_pred_total = 0;
        indirect_jalr_correct_total = 0;
        jalr_prev_wr_rs1_total = 0;
        ret_prev_wr_rs1_total = 0;
        call_jalr_prev_wr_rs1_total = 0;
        indirect_jalr_prev_wr_rs1_total = 0;
        auipc_jalr_total = 0;
        auipc_ret_total = 0;
        auipc_call_jalr_total = 0;
        auipc_indirect_jalr_total = 0;
        pred_taken_total = 0;
        dir_correct_total = 0;
        target_correct_total = 0;
        mispredict_total = 0;
        branch_miss_taken_total = 0;
        branch_miss_nt_total = 0;
        branch_hit_forward_total = 0;
        branch_hit_backward_total = 0;
        branch_miss_forward_total = 0;
        branch_miss_backward_total = 0;
        if_branch_hit_total = 0;
        if_branch_nohit_total = 0;
        if_branch_nohit_back_total = 0;
        if_branch_nohit_back_ok_total = 0;
        if_branch_nohit_back_redirect_total = 0;
        slot1_redirect_total = 0;
        slot1_branch_seen_total = 0;
        slot1_branch_issue_total = 0;
        slot1_branch_back_total = 0;
        slot1_branch_issue_back_total = 0;
        slot1_ctrl_track_total = 0;
        slot1_ctrl_match_total = 0;
        slot1_ctrl_drop_total = 0;
        slot1_pred_effective_total = 0;
        slot1_pred_without_valid_total = 0;
        slot1_raw_invalid_total = 0;
        slot1_b_exec_total = 0;
        slot1_b_pred_total = 0;
        slot1_b_correct_total = 0;
        slot1_b_taken_total = 0;
        slot1_b_nt_total = 0;
        slot1_b_fwd_total = 0;
        slot1_b_fwd_taken_total = 0;
        slot1_b_fwd_nt_total = 0;
        slot1_b_back_total = 0;
        slot1_b_back_taken_total = 0;
        slot1_b_back_nt_total = 0;
        slot1_jal_exec_total = 0;
        slot1_jal_pred_total = 0;
        slot1_jal_correct_total = 0;
        slot1_jalr_exec_total = 0;
        slot1_jalr_pred_total = 0;
        slot1_jalr_correct_total = 0;
        slot1_ret_exec_total = 0;
        slot1_ret_pred_total = 0;
        slot1_ret_correct_total = 0;
        slot1_call_jalr_exec_total = 0;
        slot1_call_jalr_pred_total = 0;
        slot1_call_jalr_correct_total = 0;
        slot1_indirect_jalr_exec_total = 0;
        slot1_indirect_jalr_pred_total = 0;
        slot1_indirect_jalr_correct_total = 0;
        bht_tag_alias_total = 0;
        bht_store_total = 0;
        bht_store_conflict_total = 0;
        bht_store_imm_overlap_total = 0;
        mul_exec_total = 0;
        mul_follow_slot_total = 0;
        mul_dep_slot_total = 0;
        mul_dep_d1_total = 0;
        mul_dep_d2_total = 0;
        mul_dep_d3_total = 0;

        cycle_snap = 0;
        instr_snap = 0;
        flush_snap = 0;
        load_stall_snap = 0;
        false_load_stall_snap = 0;
        mul_hold_snap = 0;
        other_bubble_snap = 0;
        wb_commit_snap = 0;
        branch_snap = 0;
        branch_taken_snap = 0;
        branch_both_taken_snap = 0;
        jal_snap = 0;
        jal_pred_snap = 0;
        jal_correct_snap = 0;
        jalr_snap = 0;
        jalr_pred_snap = 0;
        jalr_correct_snap = 0;
        ret_snap = 0;
        ret_pred_snap = 0;
        ret_correct_snap = 0;
        call_jalr_snap = 0;
        call_jalr_pred_snap = 0;
        call_jalr_correct_snap = 0;
        indirect_jalr_snap = 0;
        indirect_jalr_pred_snap = 0;
        indirect_jalr_correct_snap = 0;
        jalr_prev_wr_rs1_snap = 0;
        ret_prev_wr_rs1_snap = 0;
        call_jalr_prev_wr_rs1_snap = 0;
        indirect_jalr_prev_wr_rs1_snap = 0;
        auipc_jalr_snap = 0;
        auipc_ret_snap = 0;
        auipc_call_jalr_snap = 0;
        auipc_indirect_jalr_snap = 0;
        pred_taken_snap = 0;
        dir_correct_snap = 0;
        target_correct_snap = 0;
        mispredict_snap = 0;
        branch_miss_taken_snap = 0;
        branch_miss_nt_snap = 0;
        branch_hit_forward_snap = 0;
        branch_hit_backward_snap = 0;
        branch_miss_forward_snap = 0;
        branch_miss_backward_snap = 0;
        if_branch_hit_snap = 0;
        if_branch_nohit_snap = 0;
        if_branch_nohit_back_snap = 0;
        if_branch_nohit_back_ok_snap = 0;
        if_branch_nohit_back_redirect_snap = 0;
        slot1_redirect_snap = 0;
        bht_tag_alias_snap = 0;
        bht_store_snap = 0;
        bht_store_conflict_snap = 0;
        bht_store_imm_overlap_snap = 0;
        prev_issue_valid = 1'b0;
        prev_issue_we = 1'b0;
        prev_issue_rd = 5'd0;
        prev_issue_instr = 32'b0;
        mul_dep1_valid = 1'b0;
        mul_dep2_valid = 1'b0;
        mul_dep3_valid = 1'b0;
        mul_dep1_rd = 5'd0;
        mul_dep2_rd = 5'd0;
        mul_dep3_rd = 5'd0;

        for (init_i = 0; init_i < JALR_PC_STAT_SLOTS; init_i = init_i + 1) begin
            jalr_pc_valid[init_i] = 1'b0;
            jalr_pc_addr[init_i]  = 32'b0;
            jalr_pc_exec[init_i]  = 0;
            jalr_pc_pred[init_i]  = 0;
            jalr_pc_ok[init_i]    = 0;
            jalr_pc_ret[init_i]   = 0;
            jalr_pc_call[init_i]  = 0;
            jalr_pc_other[init_i] = 0;
        end
        for (init_i = 0; init_i < BRANCH_PC_STAT_SLOTS; init_i = init_i + 1) begin
            branch_pc_valid[init_i] = 1'b0;
            branch_pc_addr[init_i]  = 32'b0;
            branch_pc_exec[init_i]  = 0;
            branch_pc_pred[init_i]  = 0;
            branch_pc_dir_ok[init_i]= 0;
            branch_pc_mis[init_i]   = 0;
            branch_pc_taken[init_i] = 0;
        end
        for (init_i = 0; init_i < SLOT1_TRACK_SLOTS; init_i = init_i + 1) begin
            slot1_pending_valid[init_i] = 1'b0;
            slot1_pending_pc[init_i] = 32'b0;
            slot1_pending_instr[init_i] = 32'b0;
            slot1_pending_pred_taken[init_i] = 1'b0;
            slot1_pending_pred_target[init_i] = 32'b0;
            slot1_pending_type[init_i] = 3'b0;
        end

        #100;
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 0;
            dhry_key_pos <= 0;
            dhry_dps_accum <= 0;
            dhry_dps_value <= 0;
            dhry_capture_active <= 1'b0;
            dhry_seen_digit <= 1'b0;
            dhry_dps_valid <= 1'b0;
            uart_ipc_key_pos <= 0;
            uart_bench_parse_state <= UART_BENCH_PARSE_WAIT_C;
            uart_bench_c_seen_digit <= 1'b0;
            uart_bench_i_seen_digit <= 1'b0;
            uart_bench_c_accum <= 64'd0;
            uart_bench_i_accum <= 64'd0;
            uart_bench_cycle_value <= 64'd0;
            uart_bench_instret_value <= 64'd0;
            uart_bench_cycle_valid <= 1'b0;
            uart_bench_instret_valid <= 1'b0;
            tb_retire_total <= 64'd0;
            tb_wb_instret_hi_q <= 1'b0;
            tb_wb_instret_lo_q <= 1'b0;
            tb_instret_snap_state <= 0;
            tb_instret_snap_count <= 0;
            tb_instret_start_valid <= 1'b0;
            tb_instret_stop_valid <= 1'b0;
            tb_instret_start_retire <= 64'd0;
            tb_instret_stop_retire <= 64'd0;
            prev_issue_valid <= 1'b0;
            prev_issue_we    <= 1'b0;
            prev_issue_rd    <= 5'd0;
            prev_issue_instr <= 32'b0;
            lduse3_seq0_valid <= 1'b0;
            lduse3_seq0_load  <= 1'b0;
            lduse3_seq0_rd    <= 5'd0;
            lduse3_seq1_valid <= 1'b0;
            lduse3_seq1_load  <= 1'b0;
            lduse3_seq1_we    <= 1'b0;
            lduse3_seq1_rd    <= 5'd0;
            lduse3_seq1_rs1_used <= 1'b0;
            lduse3_seq1_rs2_used <= 1'b0;
            lduse3_seq1_rs1_addr <= 5'd0;
            lduse3_seq1_rs2_addr <= 5'd0;
            mul_dep1_valid   <= 1'b0;
            mul_dep2_valid   <= 1'b0;
            mul_dep3_valid   <= 1'b0;
            mul_dep1_rd      <= 5'd0;
            mul_dep2_rd      <= 5'd0;
            mul_dep3_rd      <= 5'd0;
            tb_mem_branch_nohit <= 1'b0;
            tb_mem_call_flag    <= 1'b0;
        for (init_i = 0; init_i < JALR_PC_STAT_SLOTS; init_i = init_i + 1) begin
            jalr_pc_valid[init_i] <= 1'b0;
            jalr_pc_addr[init_i]  <= 32'b0;
            jalr_pc_exec[init_i]  <= 0;
            jalr_pc_pred[init_i]  <= 0;
            jalr_pc_ok[init_i]    <= 0;
            jalr_pc_ret[init_i]   <= 0;
            jalr_pc_call[init_i]  <= 0;
            jalr_pc_other[init_i] <= 0;
        end
        for (init_i = 0; init_i < BRANCH_PC_STAT_SLOTS; init_i = init_i + 1) begin
            branch_pc_valid[init_i] <= 1'b0;
            branch_pc_addr[init_i]  <= 32'b0;
            branch_pc_exec[init_i]  <= 0;
            branch_pc_pred[init_i]  <= 0;
            branch_pc_dir_ok[init_i]<= 0;
            branch_pc_mis[init_i]   <= 0;
            branch_pc_taken[init_i] <= 0;
        end
        for (init_i = 0; init_i < BHT_STAT_ENTRY_NUM; init_i = init_i + 1) begin
            bht_meta_valid[init_i]   <= 1'b0;
            bht_meta_pc[init_i]      <= 32'b0;
            bht_meta_imm_abs[init_i] <= 32'b0;
            bht_entry_if_lookup[init_i] <= 0;
            bht_entry_if_hit[init_i]    <= 0;
            bht_entry_if_nohit[init_i]  <= 0;
            bht_entry_if_pred[init_i]   <= 0;
            bht_entry_alias[init_i]     <= 0;
            bht_entry_ex_exec[init_i]   <= 0;
            bht_entry_ex_taken[init_i]  <= 0;
            bht_entry_ex_pred[init_i]   <= 0;
            bht_entry_ex_dir_ok[init_i] <= 0;
            bht_entry_ex_mis[init_i]    <= 0;
            bht_entry_ex_nohit[init_i]  <= 0;
            bht_entry_fwd[init_i]       <= 0;
            bht_entry_back[init_i]      <= 0;
            bht_entry_store[init_i]     <= 0;
            bht_entry_conflict[init_i]  <= 0;
            bht_entry_imm_ovlp[init_i]  <= 0;
            end
            slot1_branch_seen_total <= 0;
            slot1_branch_issue_total <= 0;
            slot1_branch_back_total <= 0;
            slot1_branch_issue_back_total <= 0;
            slot1_ctrl_track_total <= 0;
            slot1_ctrl_match_total <= 0;
            slot1_ctrl_drop_total <= 0;
            slot1_pred_effective_total <= 0;
            slot1_pred_without_valid_total <= 0;
            slot1_raw_invalid_total <= 0;
            slot1_b_exec_total <= 0;
            slot1_b_pred_total <= 0;
            slot1_b_correct_total <= 0;
            slot1_b_taken_total <= 0;
            slot1_b_nt_total <= 0;
            slot1_b_fwd_total <= 0;
            slot1_b_fwd_taken_total <= 0;
            slot1_b_fwd_nt_total <= 0;
            slot1_b_back_total <= 0;
            slot1_b_back_taken_total <= 0;
            slot1_b_back_nt_total <= 0;
            slot1_jal_exec_total <= 0;
            slot1_jal_pred_total <= 0;
            slot1_jal_correct_total <= 0;
            slot1_jalr_exec_total <= 0;
            slot1_jalr_pred_total <= 0;
            slot1_jalr_correct_total <= 0;
            slot1_ret_exec_total <= 0;
            slot1_ret_pred_total <= 0;
            slot1_ret_correct_total <= 0;
            slot1_call_jalr_exec_total <= 0;
            slot1_call_jalr_pred_total <= 0;
            slot1_call_jalr_correct_total <= 0;
            slot1_indirect_jalr_exec_total <= 0;
            slot1_indirect_jalr_pred_total <= 0;
            slot1_indirect_jalr_correct_total <= 0;
        for (init_i = 0; init_i < SLOT1_TRACK_SLOTS; init_i = init_i + 1) begin
            slot1_pending_valid[init_i] <= 1'b0;
            slot1_pending_pc[init_i] <= 32'b0;
            slot1_pending_instr[init_i] <= 32'b0;
            slot1_pending_pred_taken[init_i] <= 1'b0;
            slot1_pending_pred_target[init_i] <= 32'b0;
            slot1_pending_type[init_i] <= 3'b0;
        end
        end else begin
            cycle_count <= cycle_count + 1;
            tb_wb_instret_hi_q <= mem_instret_hi_fire;
            tb_wb_instret_lo_q <= mem_instret_lo_fire;

            if (u_cpu.wb_valid) begin
                tb_retire_total <= tb_retire_total + 64'd1;

                if (tb_wb_instret_hi_q) begin
                    if (tb_instret_snap_state == 0) begin
                        tb_instret_snap_state <= 1;
                    end else if (tb_instret_snap_state == 2) begin
                        tb_instret_snap_state <= 0;
                        tb_instret_snap_count <= tb_instret_snap_count + 1;
                        if (!tb_instret_start_valid) begin
                            tb_instret_start_valid <= 1'b1;
                            tb_instret_start_retire <= tb_retire_total + 64'd1;
                        end else if (!tb_instret_stop_valid) begin
                            tb_instret_stop_valid <= 1'b1;
                            tb_instret_stop_retire <= tb_retire_total + 64'd1;
                        end
                    end else begin
                        tb_instret_snap_state <= 1;
                    end
                end else if (tb_wb_instret_lo_q) begin
                    if (tb_instret_snap_state == 1)
                        tb_instret_snap_state <= 2;
                end
            end

            if (timer_req_fire) begin
                if (timer_req_count == 2)
                    stat_active <= 1'b1;
                else if (timer_req_count == 3)
                    stat_active <= 1'b0;
                timer_req_count <= timer_req_count + 1;
            end

            stat_cycle_win = stat_active ? 1 : 0;

            if (u_cpu.mem_ctrl_mispredict) begin
                tb_mem_branch_nohit <= 1'b0;
                tb_mem_call_flag    <= 1'b0;
            end else if (!u_cpu.pipeline_hold) begin
                tb_mem_branch_nohit <= u_cpu.ex_branch_nohit;
                tb_mem_call_flag    <= u_cpu.ex_call_flag;
            end

            instr_now          = instr_total          + ((stat_cycle_win && issue_instr_fire) ? 1 : 0);
            flush_now          = flush_total          + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_flush) ? 1 : 0);
            load_stall_now     = load_stall_total     + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_stall && !u_cpu.pipeline_flush) ? 1 : 0);
            false_load_stall_now = false_load_stall_total + (false_load_stall_fire ? 1 : 0);
            mul_hold_now       = mul_hold_total       + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_hold && !u_cpu.pipeline_flush && !u_cpu.pipeline_stall) ? 1 : 0);
            other_bubble_now   = other_bubble_total   + ((stat_cycle_win && !issue_instr_fire && !u_cpu.pipeline_flush && !u_cpu.pipeline_stall && !u_cpu.pipeline_hold) ? 1 : 0);
            wb_commit_now      = wb_commit_total      + ((stat_cycle_win && u_cpu.wb_regs_we) ? 1 : 0);
            if_branch_hit_now  = if_branch_hit_total  + ((stat_cycle_win && u_cpu.if_branch_hit) ? 1 : 0);
            if_branch_nohit_now = if_branch_nohit_total + (if_branch_nohit_fire ? 1 : 0);
            if_branch_nohit_back_now = if_branch_nohit_back_total + (if_branch_nohit_back_fire ? 1 : 0);
            if_branch_nohit_back_ok_now = if_branch_nohit_back_ok_total + (if_branch_nohit_back_ok_fire ? 1 : 0);
            if_branch_nohit_back_redirect_now = if_branch_nohit_back_redirect_total + (if_branch_nohit_back_redirect_fire ? 1 : 0);
            slot1_redirect_now = slot1_redirect_total + (slot1_pred_effective_fire ? 1 : 0);
            slot1_branch_seen_now = slot1_branch_seen_total + (slot1_branch_seen_fire ? 1 : 0);
            slot1_branch_issue_now = slot1_branch_issue_total + (slot1_branch_issue_fire ? 1 : 0);
            slot1_branch_back_now = slot1_branch_back_total + (slot1_branch_back_fire ? 1 : 0);
            slot1_branch_issue_back_now = slot1_branch_issue_back_total + (slot1_branch_issue_back_fire ? 1 : 0);
            bht_tag_alias_now  = bht_tag_alias_total  + (if_bht_alias_hit ? 1 : 0);
            bht_store_now      = bht_store_total      + (ex_bht_store_fire ? 1 : 0) + (mem_bht_store_fire ? 1 : 0);
            bht_store_conflict_now = bht_store_conflict_total + (ex_bht_store_conflict ? 1 : 0) + (mem_bht_store_conflict ? 1 : 0);
            bht_store_imm_overlap_now = bht_store_imm_overlap_total + (ex_bht_store_imm_overlap ? 1 : 0) + (mem_bht_store_imm_overlap ? 1 : 0);

            if (if_bht_lookup_fire) begin
                bht_entry_if_lookup[if_bht_idx] <= bht_entry_if_lookup[if_bht_idx] + 1;
                if (u_cpu.if_branch_hit) begin
                    bht_entry_if_hit[if_bht_idx] <= bht_entry_if_hit[if_bht_idx] + 1;
                    if (u_cpu.if_branch_pred_taken_eff)
                        bht_entry_if_pred[if_bht_idx] <= bht_entry_if_pred[if_bht_idx] + 1;
                end else begin
                    bht_entry_if_nohit[if_bht_idx] <= bht_entry_if_nohit[if_bht_idx] + 1;
                end
                if (if_bht_alias_hit)
                    bht_entry_alias[if_bht_idx] <= bht_entry_alias[if_bht_idx] + 1;
            end

            if (slot1_pred_effective_fire)
                slot1_pred_effective_total = slot1_pred_effective_total + 1;
            if (slot1_pred_without_valid_fire)
                slot1_pred_without_valid_total = slot1_pred_without_valid_total + 1;
            if (slot1_raw_invalid_fire)
                slot1_raw_invalid_total = slot1_raw_invalid_total + 1;

            slot1_match_slot = -1;
            if (mem_branch_stat_fire || mem_jalr_stat_fire) begin
                for (slot1_track_i = 0; slot1_track_i < SLOT1_TRACK_SLOTS; slot1_track_i = slot1_track_i + 1) begin
                    if (slot1_pending_valid[slot1_track_i]
                            && (slot1_pending_pc[slot1_track_i] == mem_ctrl_pc_full)
                            && (slot1_match_slot == -1))
                        slot1_match_slot = slot1_track_i;
                end

                if (slot1_match_slot != -1) begin
                    slot1_match_type = slot1_pending_type[slot1_match_slot];
                    slot1_match_pred_taken = slot1_pending_pred_taken[slot1_match_slot];
                    slot1_match_branch_backward = slot1_pending_instr[slot1_match_slot][31];
                    slot1_match_correct = (slot1_match_type == SLOT1_TYPE_B)
                                        ? ((slot1_pending_pred_taken[slot1_match_slot] == u_cpu.mem_ctrl_actual_jump_flag)
                                           && (!slot1_pending_pred_taken[slot1_match_slot]
                                               || (slot1_pending_pred_target[slot1_match_slot] == mem_ctrl_actual_jump_addr_full)))
                                        : (!u_cpu.mem_ctrl_mispredict);

                    slot1_ctrl_match_total = slot1_ctrl_match_total + 1;
                    slot1_pending_valid[slot1_match_slot] = 1'b0;

                    if (slot1_match_type == SLOT1_TYPE_B) begin
                        slot1_b_exec_total = slot1_b_exec_total + 1;
                        if (slot1_match_pred_taken)
                            slot1_b_pred_total = slot1_b_pred_total + 1;
                        if (slot1_match_correct)
                            slot1_b_correct_total = slot1_b_correct_total + 1;
                        if (u_cpu.mem_ctrl_actual_jump_flag)
                            slot1_b_taken_total = slot1_b_taken_total + 1;
                        else
                            slot1_b_nt_total = slot1_b_nt_total + 1;

                        if (slot1_match_branch_backward) begin
                            slot1_b_back_total = slot1_b_back_total + 1;
                            if (u_cpu.mem_ctrl_actual_jump_flag)
                                slot1_b_back_taken_total = slot1_b_back_taken_total + 1;
                            else
                                slot1_b_back_nt_total = slot1_b_back_nt_total + 1;
                        end else begin
                            slot1_b_fwd_total = slot1_b_fwd_total + 1;
                            if (u_cpu.mem_ctrl_actual_jump_flag)
                                slot1_b_fwd_taken_total = slot1_b_fwd_taken_total + 1;
                            else
                                slot1_b_fwd_nt_total = slot1_b_fwd_nt_total + 1;
                        end
                    end else begin
                        slot1_jalr_exec_total = slot1_jalr_exec_total + 1;
                        if (slot1_match_pred_taken)
                            slot1_jalr_pred_total = slot1_jalr_pred_total + 1;
                        if (slot1_match_correct)
                            slot1_jalr_correct_total = slot1_jalr_correct_total + 1;

                        if (slot1_match_type == SLOT1_TYPE_RET) begin
                            slot1_ret_exec_total = slot1_ret_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_ret_pred_total = slot1_ret_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_ret_correct_total = slot1_ret_correct_total + 1;
                        end else if (slot1_match_type == SLOT1_TYPE_CALL_JALR) begin
                            slot1_call_jalr_exec_total = slot1_call_jalr_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_call_jalr_pred_total = slot1_call_jalr_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_call_jalr_correct_total = slot1_call_jalr_correct_total + 1;
                        end else begin
                            slot1_indirect_jalr_exec_total = slot1_indirect_jalr_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_indirect_jalr_pred_total = slot1_indirect_jalr_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_indirect_jalr_correct_total = slot1_indirect_jalr_correct_total + 1;
                        end
                    end
                end
            end

            slot1_match_slot = -1;
            if (ex_branch_stat_fire || ex_jal_stat_fire || ex_jalr_stat_fire) begin
                for (slot1_track_i = 0; slot1_track_i < SLOT1_TRACK_SLOTS; slot1_track_i = slot1_track_i + 1) begin
                    if (slot1_pending_valid[slot1_track_i]
                            && (slot1_pending_pc[slot1_track_i] == u_cpu.ex_instr_addr)
                            && (slot1_match_slot == -1))
                        slot1_match_slot = slot1_track_i;
                end

                if (slot1_match_slot != -1) begin
                    slot1_match_type = slot1_pending_type[slot1_match_slot];
                    slot1_match_pred_taken = slot1_pending_pred_taken[slot1_match_slot];
                    slot1_match_branch_backward = slot1_pending_instr[slot1_match_slot][31];
                    slot1_match_correct = (slot1_match_type == SLOT1_TYPE_B)
                                        ? ((slot1_pending_pred_taken[slot1_match_slot] == u_cpu.ex_actual_jump_flag)
                                           && (!slot1_pending_pred_taken[slot1_match_slot]
                                               || (slot1_pending_pred_target[slot1_match_slot] == ex_actual_jump_addr_full)))
                                        : (!u_cpu.ex_mispredict);

                    slot1_ctrl_match_total = slot1_ctrl_match_total + 1;
                    slot1_pending_valid[slot1_match_slot] = 1'b0;

                    if (slot1_match_type == SLOT1_TYPE_B) begin
                        slot1_b_exec_total = slot1_b_exec_total + 1;
                        if (slot1_match_pred_taken)
                            slot1_b_pred_total = slot1_b_pred_total + 1;
                        if (slot1_match_correct)
                            slot1_b_correct_total = slot1_b_correct_total + 1;
                        if (u_cpu.ex_actual_jump_flag)
                            slot1_b_taken_total = slot1_b_taken_total + 1;
                        else
                            slot1_b_nt_total = slot1_b_nt_total + 1;

                        if (slot1_match_branch_backward) begin
                            slot1_b_back_total = slot1_b_back_total + 1;
                            if (u_cpu.ex_actual_jump_flag)
                                slot1_b_back_taken_total = slot1_b_back_taken_total + 1;
                            else
                                slot1_b_back_nt_total = slot1_b_back_nt_total + 1;
                        end else begin
                            slot1_b_fwd_total = slot1_b_fwd_total + 1;
                            if (u_cpu.ex_actual_jump_flag)
                                slot1_b_fwd_taken_total = slot1_b_fwd_taken_total + 1;
                            else
                                slot1_b_fwd_nt_total = slot1_b_fwd_nt_total + 1;
                        end
                    end else if (slot1_match_type == SLOT1_TYPE_JAL) begin
                        slot1_jal_exec_total = slot1_jal_exec_total + 1;
                        if (slot1_match_pred_taken)
                            slot1_jal_pred_total = slot1_jal_pred_total + 1;
                        if (slot1_match_correct)
                            slot1_jal_correct_total = slot1_jal_correct_total + 1;
                    end else begin
                        slot1_jalr_exec_total = slot1_jalr_exec_total + 1;
                        if (slot1_match_pred_taken)
                            slot1_jalr_pred_total = slot1_jalr_pred_total + 1;
                        if (slot1_match_correct)
                            slot1_jalr_correct_total = slot1_jalr_correct_total + 1;

                        if (slot1_match_type == SLOT1_TYPE_RET) begin
                            slot1_ret_exec_total = slot1_ret_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_ret_pred_total = slot1_ret_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_ret_correct_total = slot1_ret_correct_total + 1;
                        end else if (slot1_match_type == SLOT1_TYPE_CALL_JALR) begin
                            slot1_call_jalr_exec_total = slot1_call_jalr_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_call_jalr_pred_total = slot1_call_jalr_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_call_jalr_correct_total = slot1_call_jalr_correct_total + 1;
                        end else begin
                            slot1_indirect_jalr_exec_total = slot1_indirect_jalr_exec_total + 1;
                            if (slot1_match_pred_taken)
                                slot1_indirect_jalr_pred_total = slot1_indirect_jalr_pred_total + 1;
                            if (slot1_match_correct)
                                slot1_indirect_jalr_correct_total = slot1_indirect_jalr_correct_total + 1;
                        end
                    end
                end
            end

            if (u_cpu.pipeline_flush) begin
                for (slot1_track_i = 0; slot1_track_i < SLOT1_TRACK_SLOTS; slot1_track_i = slot1_track_i + 1)
                    slot1_pending_valid[slot1_track_i] = 1'b0;
            end

            if (slot1_ctrl_candidate_fire) begin
                slot1_free_slot = -1;
                for (slot1_track_i = 0; slot1_track_i < SLOT1_TRACK_SLOTS; slot1_track_i = slot1_track_i + 1) begin
                    if (!slot1_pending_valid[slot1_track_i] && (slot1_free_slot == -1))
                        slot1_free_slot = slot1_track_i;
                end

                if (slot1_free_slot != -1) begin
                    slot1_ctrl_track_total = slot1_ctrl_track_total + 1;
                    slot1_pending_valid[slot1_free_slot] = 1'b1;
                    slot1_pending_pc[slot1_free_slot] = u_cpu.if_pre_instr_addr;
                    slot1_pending_instr[slot1_free_slot] = u_cpu.if_pre_instr;
                    slot1_pending_pred_taken[slot1_free_slot] = u_cpu.if_pre_pred_taken_eff;
                    slot1_pending_pred_target[slot1_free_slot] = u_cpu.if_pre_pred_target_eff;
                    slot1_pending_type[slot1_free_slot] = slot1_candidate_type;
                end else begin
                    slot1_ctrl_drop_total = slot1_ctrl_drop_total + 1;
                end
            end

            branch_now         = branch_total;
            branch_taken_now   = branch_taken_total;
            branch_both_taken_now = branch_both_taken_total;
            jal_now            = jal_total;
            jal_pred_now       = jal_pred_total;
            jal_correct_now    = jal_correct_total;
            jalr_now           = jalr_total;
            jalr_pred_now      = jalr_pred_total;
            jalr_correct_now   = jalr_correct_total;
            ret_now            = ret_total;
            ret_pred_now       = ret_pred_total;
            ret_correct_now    = ret_correct_total;
            call_jalr_now      = call_jalr_total;
            call_jalr_pred_now = call_jalr_pred_total;
            call_jalr_correct_now = call_jalr_correct_total;
            indirect_jalr_now  = indirect_jalr_total;
            indirect_jalr_pred_now = indirect_jalr_pred_total;
            indirect_jalr_correct_now = indirect_jalr_correct_total;
            jalr_prev_wr_rs1_now = jalr_prev_wr_rs1_total;
            ret_prev_wr_rs1_now = ret_prev_wr_rs1_total;
            call_jalr_prev_wr_rs1_now = call_jalr_prev_wr_rs1_total;
            indirect_jalr_prev_wr_rs1_now = indirect_jalr_prev_wr_rs1_total;
            lduse3_base_now = lduse3_base_total;
            lduse3_i2_dep_i0_now = lduse3_i2_dep_i0_total;
            lduse3_i2_dep_i1_now = lduse3_i2_dep_i1_total;
            lduse3_i2_dep_both_now = lduse3_i2_dep_both_total;
            auipc_jalr_now = auipc_jalr_total;
            auipc_ret_now = auipc_ret_total;
            auipc_call_jalr_now = auipc_call_jalr_total;
            auipc_indirect_jalr_now = auipc_indirect_jalr_total;
            pred_taken_now     = pred_taken_total;
            dir_correct_now    = dir_correct_total;
            target_correct_now = target_correct_total;
            mispredict_now     = mispredict_total;
            branch_miss_taken_now = branch_miss_taken_total;
            branch_miss_nt_now = branch_miss_nt_total;
            branch_hit_forward_now = branch_hit_forward_total;
            branch_hit_backward_now = branch_hit_backward_total;
            branch_miss_forward_now = branch_miss_forward_total;
            branch_miss_backward_now = branch_miss_backward_total;

            if (ex_branch_stat_fire) begin
                branch_now = branch_now + 1;

                if (u_cpu.ex_actual_jump_flag)
                    branch_taken_now = branch_taken_now + 1;

                if (u_cpu.ex_pred_taken)
                    pred_taken_now = pred_taken_now + 1;

                if (u_cpu.ex_pred_taken == u_cpu.ex_actual_jump_flag)
                    dir_correct_now = dir_correct_now + 1;

                if (u_cpu.ex_pred_taken && u_cpu.ex_actual_jump_flag) begin
                    branch_both_taken_now = branch_both_taken_now + 1;
                    if (u_cpu.ex_pred_target == u_cpu.ex_actual_jump_addr)
                        target_correct_now = target_correct_now + 1;
                end

                if (u_cpu.ex_mispredict)
                    mispredict_now = mispredict_now + 1;

                if (u_cpu.ex_branch_nohit) begin
                    if (u_cpu.ex_actual_jump_flag)
                        branch_miss_taken_now = branch_miss_taken_now + 1;
                    else
                        branch_miss_nt_now = branch_miss_nt_now + 1;

                    if (ex_branch_is_backward)
                        branch_miss_backward_now = branch_miss_backward_now + 1;
                    else
                        branch_miss_forward_now = branch_miss_forward_now + 1;
                end else if (ex_branch_is_backward) begin
                    branch_hit_backward_now = branch_hit_backward_now + 1;
                end else begin
                    branch_hit_forward_now = branch_hit_forward_now + 1;
                end

                bht_entry_ex_exec[ex_bht_idx] = bht_entry_ex_exec[ex_bht_idx] + 1;
                if (u_cpu.ex_actual_jump_flag)
                    bht_entry_ex_taken[ex_bht_idx] = bht_entry_ex_taken[ex_bht_idx] + 1;
                if (u_cpu.ex_pred_taken)
                    bht_entry_ex_pred[ex_bht_idx] = bht_entry_ex_pred[ex_bht_idx] + 1;
                if (u_cpu.ex_pred_taken == u_cpu.ex_actual_jump_flag)
                    bht_entry_ex_dir_ok[ex_bht_idx] = bht_entry_ex_dir_ok[ex_bht_idx] + 1;
                if (u_cpu.ex_mispredict)
                    bht_entry_ex_mis[ex_bht_idx] = bht_entry_ex_mis[ex_bht_idx] + 1;
                if (u_cpu.ex_branch_nohit)
                    bht_entry_ex_nohit[ex_bht_idx] = bht_entry_ex_nohit[ex_bht_idx] + 1;
                if (ex_branch_is_backward)
                    bht_entry_back[ex_bht_idx] = bht_entry_back[ex_bht_idx] + 1;
                else
                    bht_entry_fwd[ex_bht_idx] = bht_entry_fwd[ex_bht_idx] + 1;

                branch_pc_slot = -1;
                branch_pc_free = -1;
                for (branch_pc_i = 0; branch_pc_i < BRANCH_PC_STAT_SLOTS; branch_pc_i = branch_pc_i + 1) begin
                    if (branch_pc_valid[branch_pc_i] && (branch_pc_addr[branch_pc_i] == u_cpu.ex_instr_addr))
                        branch_pc_slot = branch_pc_i;
                    else if (!branch_pc_valid[branch_pc_i] && (branch_pc_free == -1))
                        branch_pc_free = branch_pc_i;
                end

                if (branch_pc_slot == -1)
                    branch_pc_slot = branch_pc_free;

                if (branch_pc_slot != -1) begin
                    if (!branch_pc_valid[branch_pc_slot]) begin
                        branch_pc_valid[branch_pc_slot] = 1'b1;
                        branch_pc_addr[branch_pc_slot]  = u_cpu.ex_instr_addr;
                        branch_pc_exec[branch_pc_slot]  = 0;
                        branch_pc_pred[branch_pc_slot]  = 0;
                        branch_pc_dir_ok[branch_pc_slot]= 0;
                        branch_pc_mis[branch_pc_slot]   = 0;
                        branch_pc_taken[branch_pc_slot] = 0;
                    end

                    branch_pc_exec[branch_pc_slot] = branch_pc_exec[branch_pc_slot] + 1;
                    if (u_cpu.ex_pred_taken)
                        branch_pc_pred[branch_pc_slot] = branch_pc_pred[branch_pc_slot] + 1;
                    if (u_cpu.ex_pred_taken == u_cpu.ex_actual_jump_flag)
                        branch_pc_dir_ok[branch_pc_slot] = branch_pc_dir_ok[branch_pc_slot] + 1;
                    if (u_cpu.ex_mispredict)
                        branch_pc_mis[branch_pc_slot] = branch_pc_mis[branch_pc_slot] + 1;
                    if (u_cpu.ex_actual_jump_flag)
                        branch_pc_taken[branch_pc_slot] = branch_pc_taken[branch_pc_slot] + 1;
                end
            end

            if (mem_branch_stat_fire) begin
                branch_now = branch_now + 1;

                if (u_cpu.mem_ctrl_actual_jump_flag)
                    branch_taken_now = branch_taken_now + 1;

                if (u_cpu.mem_pred_taken)
                    pred_taken_now = pred_taken_now + 1;

                if (u_cpu.mem_pred_taken == u_cpu.mem_ctrl_actual_jump_flag)
                    dir_correct_now = dir_correct_now + 1;

                if (u_cpu.mem_pred_taken && u_cpu.mem_ctrl_actual_jump_flag) begin
                    branch_both_taken_now = branch_both_taken_now + 1;
                    if (mem_ctrl_pred_target_full == mem_ctrl_actual_jump_addr_full)
                        target_correct_now = target_correct_now + 1;
                end

                if (u_cpu.mem_ctrl_mispredict)
                    mispredict_now = mispredict_now + 1;

                if (tb_mem_branch_nohit) begin
                    if (u_cpu.mem_ctrl_actual_jump_flag)
                        branch_miss_taken_now = branch_miss_taken_now + 1;
                    else
                        branch_miss_nt_now = branch_miss_nt_now + 1;

                    if (mem_branch_is_backward)
                        branch_miss_backward_now = branch_miss_backward_now + 1;
                    else
                        branch_miss_forward_now = branch_miss_forward_now + 1;
                end else if (mem_branch_is_backward) begin
                    branch_hit_backward_now = branch_hit_backward_now + 1;
                end else begin
                    branch_hit_forward_now = branch_hit_forward_now + 1;
                end

                bht_entry_ex_exec[mem_bht_idx] = bht_entry_ex_exec[mem_bht_idx] + 1;
                if (u_cpu.mem_ctrl_actual_jump_flag)
                    bht_entry_ex_taken[mem_bht_idx] = bht_entry_ex_taken[mem_bht_idx] + 1;
                if (u_cpu.mem_pred_taken)
                    bht_entry_ex_pred[mem_bht_idx] = bht_entry_ex_pred[mem_bht_idx] + 1;
                if (u_cpu.mem_pred_taken == u_cpu.mem_ctrl_actual_jump_flag)
                    bht_entry_ex_dir_ok[mem_bht_idx] = bht_entry_ex_dir_ok[mem_bht_idx] + 1;
                if (u_cpu.mem_ctrl_mispredict)
                    bht_entry_ex_mis[mem_bht_idx] = bht_entry_ex_mis[mem_bht_idx] + 1;
                if (tb_mem_branch_nohit)
                    bht_entry_ex_nohit[mem_bht_idx] = bht_entry_ex_nohit[mem_bht_idx] + 1;
                if (mem_branch_is_backward)
                    bht_entry_back[mem_bht_idx] = bht_entry_back[mem_bht_idx] + 1;
                else
                    bht_entry_fwd[mem_bht_idx] = bht_entry_fwd[mem_bht_idx] + 1;

                branch_pc_slot = -1;
                branch_pc_free = -1;
                for (branch_pc_i = 0; branch_pc_i < BRANCH_PC_STAT_SLOTS; branch_pc_i = branch_pc_i + 1) begin
                    if (branch_pc_valid[branch_pc_i] && (branch_pc_addr[branch_pc_i] == mem_ctrl_pc_full))
                        branch_pc_slot = branch_pc_i;
                    else if (!branch_pc_valid[branch_pc_i] && (branch_pc_free == -1))
                        branch_pc_free = branch_pc_i;
                end

                if (branch_pc_slot == -1)
                    branch_pc_slot = branch_pc_free;

                if (branch_pc_slot != -1) begin
                    if (!branch_pc_valid[branch_pc_slot]) begin
                        branch_pc_valid[branch_pc_slot] = 1'b1;
                        branch_pc_addr[branch_pc_slot]  = mem_ctrl_pc_full;
                        branch_pc_exec[branch_pc_slot]  = 0;
                        branch_pc_pred[branch_pc_slot]  = 0;
                        branch_pc_dir_ok[branch_pc_slot]= 0;
                        branch_pc_mis[branch_pc_slot]   = 0;
                        branch_pc_taken[branch_pc_slot] = 0;
                    end

                    branch_pc_exec[branch_pc_slot] = branch_pc_exec[branch_pc_slot] + 1;
                    if (u_cpu.mem_pred_taken)
                        branch_pc_pred[branch_pc_slot] = branch_pc_pred[branch_pc_slot] + 1;
                    if (u_cpu.mem_pred_taken == u_cpu.mem_ctrl_actual_jump_flag)
                        branch_pc_dir_ok[branch_pc_slot] = branch_pc_dir_ok[branch_pc_slot] + 1;
                    if (u_cpu.mem_ctrl_mispredict)
                        branch_pc_mis[branch_pc_slot] = branch_pc_mis[branch_pc_slot] + 1;
                    if (u_cpu.mem_ctrl_actual_jump_flag)
                        branch_pc_taken[branch_pc_slot] = branch_pc_taken[branch_pc_slot] + 1;
                end
            end

            if (ex_jalr_stat_fire) begin
                if (u_cpu.ex_jalr_flag) begin
                    jalr_now = jalr_now + 1;
                    if (u_cpu.ex_ret_flag)
                        ret_now = ret_now + 1;
                    else if (u_cpu.ex_call_flag)
                        call_jalr_now = call_jalr_now + 1;
                    else
                        indirect_jalr_now = indirect_jalr_now + 1;

                    if (u_cpu.ex_pred_taken) begin
                        jalr_pred_now = jalr_pred_now + 1;
                        if (u_cpu.ex_ret_flag)
                            ret_pred_now = ret_pred_now + 1;
                        else if (u_cpu.ex_call_flag)
                            call_jalr_pred_now = call_jalr_pred_now + 1;
                        else
                            indirect_jalr_pred_now = indirect_jalr_pred_now + 1;
                    end
                    if (!u_cpu.ex_mispredict) begin
                        jalr_correct_now = jalr_correct_now + 1;
                        if (u_cpu.ex_ret_flag)
                            ret_correct_now = ret_correct_now + 1;
                        else if (u_cpu.ex_call_flag)
                            call_jalr_correct_now = call_jalr_correct_now + 1;
                        else
                            indirect_jalr_correct_now = indirect_jalr_correct_now + 1;
                    end
                end else begin
                    jal_now = jal_now + 1;
                    if (u_cpu.ex_pred_taken)
                        jal_pred_now = jal_pred_now + 1;
                    if (!u_cpu.ex_mispredict)
                        jal_correct_now = jal_correct_now + 1;
                end
            end

            if (mem_jalr_stat_fire) begin
                jalr_now = jalr_now + 1;
                if (u_cpu.mem_ret_flag)
                    ret_now = ret_now + 1;
                else if (tb_mem_call_flag)
                    call_jalr_now = call_jalr_now + 1;
                else
                    indirect_jalr_now = indirect_jalr_now + 1;

                if (u_cpu.mem_pred_taken) begin
                    jalr_pred_now = jalr_pred_now + 1;
                    if (u_cpu.mem_ret_flag)
                        ret_pred_now = ret_pred_now + 1;
                    else if (tb_mem_call_flag)
                        call_jalr_pred_now = call_jalr_pred_now + 1;
                    else
                        indirect_jalr_pred_now = indirect_jalr_pred_now + 1;
                end
                if (!u_cpu.mem_ctrl_mispredict) begin
                    jalr_correct_now = jalr_correct_now + 1;
                    if (u_cpu.mem_ret_flag)
                        ret_correct_now = ret_correct_now + 1;
                    else if (tb_mem_call_flag)
                        call_jalr_correct_now = call_jalr_correct_now + 1;
                    else
                        indirect_jalr_correct_now = indirect_jalr_correct_now + 1;
                end
            end

            if (ex_jal_stat_fire) begin
                jal_now = jal_now + 1;
                if (u_cpu.ex_pred_taken)
                    jal_pred_now = jal_pred_now + 1;
                if (!u_cpu.ex_mispredict)
                    jal_correct_now = jal_correct_now + 1;
            end

            if (jalr_prev_wr_rs1_fire) begin
                jalr_prev_wr_rs1_now = jalr_prev_wr_rs1_now + 1;
                if (u_cpu.id_ret_flag)
                    ret_prev_wr_rs1_now = ret_prev_wr_rs1_now + 1;
                else if (u_cpu.id_call_flag)
                    call_jalr_prev_wr_rs1_now = call_jalr_prev_wr_rs1_now + 1;
                else
                    indirect_jalr_prev_wr_rs1_now = indirect_jalr_prev_wr_rs1_now + 1;
            end

            if (lduse3_base_fire) begin
                lduse3_base_now = lduse3_base_now + 1;
                if (lduse3_i2_dep_i0_fire)
                    lduse3_i2_dep_i0_now = lduse3_i2_dep_i0_now + 1;
                if (lduse3_i2_dep_i1_fire)
                    lduse3_i2_dep_i1_now = lduse3_i2_dep_i1_now + 1;
                if (lduse3_i2_dep_both_fire)
                    lduse3_i2_dep_both_now = lduse3_i2_dep_both_now + 1;
            end

            if (auipc_jalr_fire) begin
                auipc_jalr_now = auipc_jalr_now + 1;
                if (u_cpu.id_ret_flag)
                    auipc_ret_now = auipc_ret_now + 1;
                else if (u_cpu.id_call_flag)
                    auipc_call_jalr_now = auipc_call_jalr_now + 1;
                else
                    auipc_indirect_jalr_now = auipc_indirect_jalr_now + 1;
            end

            if (ex_jalr_stat_fire) begin
                jalr_pc_slot = -1;
                jalr_pc_free = -1;
                for (jalr_pc_i = 0; jalr_pc_i < JALR_PC_STAT_SLOTS; jalr_pc_i = jalr_pc_i + 1) begin
                    if (jalr_pc_valid[jalr_pc_i] && (jalr_pc_addr[jalr_pc_i] == u_cpu.ex_instr_addr))
                        jalr_pc_slot = jalr_pc_i;
                    else if (!jalr_pc_valid[jalr_pc_i] && (jalr_pc_free == -1))
                        jalr_pc_free = jalr_pc_i;
                end

                if (jalr_pc_slot == -1)
                    jalr_pc_slot = jalr_pc_free;

                if (jalr_pc_slot != -1) begin
                    if (!jalr_pc_valid[jalr_pc_slot]) begin
                        jalr_pc_valid[jalr_pc_slot] = 1'b1;
                        jalr_pc_addr[jalr_pc_slot]  = u_cpu.ex_instr_addr;
                        jalr_pc_exec[jalr_pc_slot]  = 0;
                        jalr_pc_pred[jalr_pc_slot]  = 0;
                        jalr_pc_ok[jalr_pc_slot]    = 0;
                        jalr_pc_ret[jalr_pc_slot]   = 0;
                        jalr_pc_call[jalr_pc_slot]  = 0;
                        jalr_pc_other[jalr_pc_slot] = 0;
                    end

                    jalr_pc_exec[jalr_pc_slot] = jalr_pc_exec[jalr_pc_slot] + 1;
                    if (u_cpu.ex_pred_taken)
                        jalr_pc_pred[jalr_pc_slot] = jalr_pc_pred[jalr_pc_slot] + 1;
                    if (!u_cpu.ex_mispredict)
                        jalr_pc_ok[jalr_pc_slot] = jalr_pc_ok[jalr_pc_slot] + 1;
                    if (u_cpu.ex_ret_flag)
                        jalr_pc_ret[jalr_pc_slot] = jalr_pc_ret[jalr_pc_slot] + 1;
                    else if (u_cpu.ex_call_flag)
                        jalr_pc_call[jalr_pc_slot] = jalr_pc_call[jalr_pc_slot] + 1;
                    else
                        jalr_pc_other[jalr_pc_slot] = jalr_pc_other[jalr_pc_slot] + 1;
                end
            end

            if (mem_jalr_stat_fire) begin
                jalr_pc_slot = -1;
                jalr_pc_free = -1;
                for (jalr_pc_i = 0; jalr_pc_i < JALR_PC_STAT_SLOTS; jalr_pc_i = jalr_pc_i + 1) begin
                    if (jalr_pc_valid[jalr_pc_i] && (jalr_pc_addr[jalr_pc_i] == mem_ctrl_pc_full))
                        jalr_pc_slot = jalr_pc_i;
                    else if (!jalr_pc_valid[jalr_pc_i] && (jalr_pc_free == -1))
                        jalr_pc_free = jalr_pc_i;
                end

                if (jalr_pc_slot == -1)
                    jalr_pc_slot = jalr_pc_free;

                if (jalr_pc_slot != -1) begin
                    if (!jalr_pc_valid[jalr_pc_slot]) begin
                        jalr_pc_valid[jalr_pc_slot] = 1'b1;
                        jalr_pc_addr[jalr_pc_slot]  = mem_ctrl_pc_full;
                        jalr_pc_exec[jalr_pc_slot]  = 0;
                        jalr_pc_pred[jalr_pc_slot]  = 0;
                        jalr_pc_ok[jalr_pc_slot]    = 0;
                        jalr_pc_ret[jalr_pc_slot]   = 0;
                        jalr_pc_call[jalr_pc_slot]  = 0;
                        jalr_pc_other[jalr_pc_slot] = 0;
                    end

                    jalr_pc_exec[jalr_pc_slot] = jalr_pc_exec[jalr_pc_slot] + 1;
                    if (u_cpu.mem_pred_taken)
                        jalr_pc_pred[jalr_pc_slot] = jalr_pc_pred[jalr_pc_slot] + 1;
                    if (!u_cpu.mem_ctrl_mispredict)
                        jalr_pc_ok[jalr_pc_slot] = jalr_pc_ok[jalr_pc_slot] + 1;
                    if (u_cpu.mem_ret_flag)
                        jalr_pc_ret[jalr_pc_slot] = jalr_pc_ret[jalr_pc_slot] + 1;
                    else if (tb_mem_call_flag)
                        jalr_pc_call[jalr_pc_slot] = jalr_pc_call[jalr_pc_slot] + 1;
                    else
                        jalr_pc_other[jalr_pc_slot] = jalr_pc_other[jalr_pc_slot] + 1;
                end
            end

            stat_cycle_total     <= stat_cycle_total + stat_cycle_win;
            instr_total          <= instr_now;
            flush_total          <= flush_now;
            load_stall_total     <= load_stall_now;
            false_load_stall_total <= false_load_stall_now;
            mul_hold_total       <= mul_hold_now;
            other_bubble_total   <= other_bubble_now;
            wb_commit_total      <= wb_commit_now;
            if_branch_hit_total  <= if_branch_hit_now;
            if_branch_nohit_total <= if_branch_nohit_now;
            if_branch_nohit_back_total <= if_branch_nohit_back_now;
            if_branch_nohit_back_ok_total <= if_branch_nohit_back_ok_now;
            if_branch_nohit_back_redirect_total <= if_branch_nohit_back_redirect_now;
            slot1_redirect_total <= slot1_redirect_now;
            slot1_branch_seen_total <= slot1_branch_seen_now;
            slot1_branch_issue_total <= slot1_branch_issue_now;
            slot1_branch_back_total <= slot1_branch_back_now;
            slot1_branch_issue_back_total <= slot1_branch_issue_back_now;
            bht_tag_alias_total  <= bht_tag_alias_now;
            bht_store_total      <= bht_store_now;
            bht_store_conflict_total <= bht_store_conflict_now;
            bht_store_imm_overlap_total <= bht_store_imm_overlap_now;
            branch_total         <= branch_now;
            branch_taken_total   <= branch_taken_now;
            branch_both_taken_total <= branch_both_taken_now;
            jal_total            <= jal_now;
            jal_pred_total       <= jal_pred_now;
            jal_correct_total    <= jal_correct_now;
            jalr_total           <= jalr_now;
            jalr_pred_total      <= jalr_pred_now;
            jalr_correct_total   <= jalr_correct_now;
            ret_total            <= ret_now;
            ret_pred_total       <= ret_pred_now;
            ret_correct_total    <= ret_correct_now;
            call_jalr_total      <= call_jalr_now;
            call_jalr_pred_total <= call_jalr_pred_now;
            call_jalr_correct_total <= call_jalr_correct_now;
            indirect_jalr_total  <= indirect_jalr_now;
            indirect_jalr_pred_total <= indirect_jalr_pred_now;
            indirect_jalr_correct_total <= indirect_jalr_correct_now;
            jalr_prev_wr_rs1_total <= jalr_prev_wr_rs1_now;
            ret_prev_wr_rs1_total <= ret_prev_wr_rs1_now;
            call_jalr_prev_wr_rs1_total <= call_jalr_prev_wr_rs1_now;
            indirect_jalr_prev_wr_rs1_total <= indirect_jalr_prev_wr_rs1_now;
            lduse3_base_total <= lduse3_base_now;
            lduse3_i2_dep_i0_total <= lduse3_i2_dep_i0_now;
            lduse3_i2_dep_i1_total <= lduse3_i2_dep_i1_now;
            lduse3_i2_dep_both_total <= lduse3_i2_dep_both_now;
            auipc_jalr_total <= auipc_jalr_now;
            auipc_ret_total <= auipc_ret_now;
            auipc_call_jalr_total <= auipc_call_jalr_now;
            auipc_indirect_jalr_total <= auipc_indirect_jalr_now;
            pred_taken_total     <= pred_taken_now;
            dir_correct_total    <= dir_correct_now;
            target_correct_total <= target_correct_now;
            mispredict_total     <= mispredict_now;
            branch_miss_taken_total <= branch_miss_taken_now;
            branch_miss_nt_total <= branch_miss_nt_now;
            branch_hit_forward_total <= branch_hit_forward_now;
            branch_hit_backward_total <= branch_hit_backward_now;
            branch_miss_forward_total <= branch_miss_forward_now;
            branch_miss_backward_total <= branch_miss_backward_now;

            if (ex_bht_store_fire) begin
                bht_meta_valid[ex_bht_idx]   = 1'b1;
                bht_meta_pc[ex_bht_idx]      = u_cpu.ex_instr_addr;
                bht_meta_imm_abs[ex_bht_idx] = ex_branch_imm_abs;
                bht_entry_store[ex_bht_idx]  = bht_entry_store[ex_bht_idx] + 1;
                if (ex_bht_store_conflict)
                    bht_entry_conflict[ex_bht_idx] = bht_entry_conflict[ex_bht_idx] + 1;
                if (ex_bht_store_imm_overlap)
                    bht_entry_imm_ovlp[ex_bht_idx] = bht_entry_imm_ovlp[ex_bht_idx] + 1;
            end

            if (mem_bht_store_fire) begin
                bht_meta_valid[mem_bht_idx]   = 1'b1;
                bht_meta_pc[mem_bht_idx]      = mem_ctrl_pc_full;
                bht_meta_imm_abs[mem_bht_idx] = mem_branch_imm_abs;
                bht_entry_store[mem_bht_idx]  = bht_entry_store[mem_bht_idx] + 1;
                if (mem_bht_store_conflict)
                    bht_entry_conflict[mem_bht_idx] = bht_entry_conflict[mem_bht_idx] + 1;
                if (mem_bht_store_imm_overlap)
                    bht_entry_imm_ovlp[mem_bht_idx] = bht_entry_imm_ovlp[mem_bht_idx] + 1;
            end

            if (issue_instr_fire) begin
                mul_follow_inc   = 0;
                mul_dep_slot_inc = 0;
                mul_dep_d1_inc   = 0;
                mul_dep_d2_inc   = 0;
                mul_dep_d3_inc   = 0;
                mul_exec_inc     = 0;
                if (stat_cycle_win) begin
                    if (mul_dep1_valid)
                        mul_follow_inc = mul_follow_inc + 1;
                    if (mul_dep2_valid)
                        mul_follow_inc = mul_follow_inc + 1;
                    if (mul_dep3_valid)
                        mul_follow_inc = mul_follow_inc + 1;
                    if (mul_dep_hit_d1) begin
                        mul_dep_slot_inc = mul_dep_slot_inc + 1;
                        mul_dep_d1_inc   = 1;
                    end
                    if (mul_dep_hit_d2) begin
                        mul_dep_slot_inc = mul_dep_slot_inc + 1;
                        mul_dep_d2_inc   = 1;
                    end
                    if (mul_dep_hit_d3) begin
                        mul_dep_slot_inc = mul_dep_slot_inc + 1;
                        mul_dep_d3_inc   = 1;
                    end
                    if (issue_is_mul && u_cpu.id_regs_we && (u_cpu.id_regs_w_addr != 5'd0))
                        mul_exec_inc = 1;

                    mul_follow_slot_total <= mul_follow_slot_total + mul_follow_inc;
                    mul_dep_slot_total    <= mul_dep_slot_total + mul_dep_slot_inc;
                    mul_dep_d1_total      <= mul_dep_d1_total + mul_dep_d1_inc;
                    mul_dep_d2_total      <= mul_dep_d2_total + mul_dep_d2_inc;
                    mul_dep_d3_total      <= mul_dep_d3_total + mul_dep_d3_inc;
                    mul_exec_total        <= mul_exec_total + mul_exec_inc;
                end
                prev_issue_valid <= 1'b1;
                prev_issue_we    <= u_cpu.id_regs_we;
                prev_issue_rd    <= u_cpu.id_regs_w_addr;
                prev_issue_instr <= u_cpu.id_instr;
                lduse3_seq0_valid <= lduse3_seq1_valid;
                lduse3_seq0_load  <= lduse3_seq1_load;
                lduse3_seq0_rd    <= lduse3_seq1_rd;
                lduse3_seq1_valid <= 1'b1;
                lduse3_seq1_load  <= issue_is_load;
                lduse3_seq1_we    <= u_cpu.id_regs_we;
                lduse3_seq1_rd    <= u_cpu.id_regs_w_addr;
                lduse3_seq1_rs1_used <= issue_rs1_used;
                lduse3_seq1_rs2_used <= issue_rs2_used;
                lduse3_seq1_rs1_addr <= u_cpu.id_rs1_addr;
                lduse3_seq1_rs2_addr <= u_cpu.id_rs2_addr;
                mul_dep3_valid   <= mul_dep2_valid;
                mul_dep3_rd      <= mul_dep2_rd;
                mul_dep2_valid   <= mul_dep1_valid;
                mul_dep2_rd      <= mul_dep1_rd;
                mul_dep1_valid   <= issue_is_mul && u_cpu.id_regs_we && (u_cpu.id_regs_w_addr != 5'd0);
                mul_dep1_rd      <= u_cpu.id_regs_w_addr;
            end

            if (PERIODIC_STATS_ENABLE && BP_STATS_ENABLE && (stat_cycle_total != 0)
                    && ((stat_cycle_total % 10000) == 0)) begin
                cycle_win          = stat_cycle_total - cycle_snap;
                instr_win          = instr_now          - instr_snap;
                flush_win          = flush_now          - flush_snap;
                load_stall_win     = load_stall_now     - load_stall_snap;
                false_load_stall_win = false_load_stall_now - false_load_stall_snap;
                mul_hold_win       = mul_hold_now       - mul_hold_snap;
                other_bubble_win   = other_bubble_now   - other_bubble_snap;
                wb_commit_win      = wb_commit_now      - wb_commit_snap;
                branch_win         = branch_now         - branch_snap;
                branch_taken_win   = branch_taken_now   - branch_taken_snap;
                branch_both_taken_win = branch_both_taken_now - branch_both_taken_snap;
                jal_win            = jal_now            - jal_snap;
                jal_pred_win       = jal_pred_now       - jal_pred_snap;
                jal_correct_win    = jal_correct_now    - jal_correct_snap;
                jalr_win           = jalr_now           - jalr_snap;
                jalr_pred_win      = jalr_pred_now      - jalr_pred_snap;
                jalr_correct_win   = jalr_correct_now   - jalr_correct_snap;
                ret_win            = ret_now            - ret_snap;
                ret_pred_win       = ret_pred_now       - ret_pred_snap;
                ret_correct_win    = ret_correct_now    - ret_correct_snap;
                call_jalr_win      = call_jalr_now      - call_jalr_snap;
                call_jalr_pred_win = call_jalr_pred_now - call_jalr_pred_snap;
                call_jalr_correct_win = call_jalr_correct_now - call_jalr_correct_snap;
                indirect_jalr_win  = indirect_jalr_now  - indirect_jalr_snap;
                indirect_jalr_pred_win = indirect_jalr_pred_now - indirect_jalr_pred_snap;
                indirect_jalr_correct_win = indirect_jalr_correct_now - indirect_jalr_correct_snap;
                jalr_prev_wr_rs1_win = jalr_prev_wr_rs1_now - jalr_prev_wr_rs1_snap;
                ret_prev_wr_rs1_win = ret_prev_wr_rs1_now - ret_prev_wr_rs1_snap;
                call_jalr_prev_wr_rs1_win = call_jalr_prev_wr_rs1_now - call_jalr_prev_wr_rs1_snap;
                indirect_jalr_prev_wr_rs1_win = indirect_jalr_prev_wr_rs1_now - indirect_jalr_prev_wr_rs1_snap;
                auipc_jalr_win = auipc_jalr_now - auipc_jalr_snap;
                auipc_ret_win = auipc_ret_now - auipc_ret_snap;
                auipc_call_jalr_win = auipc_call_jalr_now - auipc_call_jalr_snap;
                auipc_indirect_jalr_win = auipc_indirect_jalr_now - auipc_indirect_jalr_snap;
                pred_taken_win     = pred_taken_now     - pred_taken_snap;
                dir_correct_win    = dir_correct_now    - dir_correct_snap;
                target_correct_win = target_correct_now - target_correct_snap;
                mispredict_win     = mispredict_now     - mispredict_snap;
                branch_miss_taken_win = branch_miss_taken_now - branch_miss_taken_snap;
                branch_miss_nt_win = branch_miss_nt_now - branch_miss_nt_snap;
                branch_hit_forward_win = branch_hit_forward_now - branch_hit_forward_snap;
                branch_hit_backward_win = branch_hit_backward_now - branch_hit_backward_snap;
                branch_miss_forward_win = branch_miss_forward_now - branch_miss_forward_snap;
                branch_miss_backward_win = branch_miss_backward_now - branch_miss_backward_snap;
                if_branch_hit_win  = if_branch_hit_now  - if_branch_hit_snap;
                if_branch_nohit_win = if_branch_nohit_now - if_branch_nohit_snap;
                if_branch_nohit_back_win = if_branch_nohit_back_now - if_branch_nohit_back_snap;
                if_branch_nohit_back_ok_win = if_branch_nohit_back_ok_now - if_branch_nohit_back_ok_snap;
                if_branch_nohit_back_redirect_win = if_branch_nohit_back_redirect_now - if_branch_nohit_back_redirect_snap;
                slot1_redirect_win = slot1_redirect_now - slot1_redirect_snap;
                bht_tag_alias_win  = bht_tag_alias_now  - bht_tag_alias_snap;
                bht_store_win      = bht_store_now      - bht_store_snap;
                bht_store_conflict_win = bht_store_conflict_now - bht_store_conflict_snap;
                bht_store_imm_overlap_win = bht_store_imm_overlap_now - bht_store_imm_overlap_snap;

                print_compact_report_stats(stat_cycle_total,
                                           instr_now,
                                           branch_now,
                                           branch_both_taken_now,
                                           jal_now, jal_pred_now, jal_correct_now,
                                           jalr_now, jalr_pred_now, jalr_correct_now,
                                           dir_correct_now, target_correct_now, mispredict_now,
                                           flush_now, load_stall_now, mul_hold_now, other_bubble_now);

                cycle_snap          <= stat_cycle_total;
                instr_snap          <= instr_now;
                flush_snap          <= flush_now;
                load_stall_snap     <= load_stall_now;
                false_load_stall_snap <= false_load_stall_now;
                mul_hold_snap       <= mul_hold_now;
                other_bubble_snap   <= other_bubble_now;
                wb_commit_snap      <= wb_commit_now;
                branch_snap         <= branch_now;
                branch_taken_snap   <= branch_taken_now;
                branch_both_taken_snap <= branch_both_taken_now;
                jal_snap            <= jal_now;
                jal_pred_snap       <= jal_pred_now;
                jal_correct_snap    <= jal_correct_now;
                jalr_snap           <= jalr_now;
                jalr_pred_snap      <= jalr_pred_now;
                jalr_correct_snap   <= jalr_correct_now;
                ret_snap            <= ret_now;
                ret_pred_snap       <= ret_pred_now;
                ret_correct_snap    <= ret_correct_now;
                call_jalr_snap      <= call_jalr_now;
                call_jalr_pred_snap <= call_jalr_pred_now;
                call_jalr_correct_snap <= call_jalr_correct_now;
                indirect_jalr_snap  <= indirect_jalr_now;
                indirect_jalr_pred_snap <= indirect_jalr_pred_now;
                indirect_jalr_correct_snap <= indirect_jalr_correct_now;
                jalr_prev_wr_rs1_snap <= jalr_prev_wr_rs1_now;
                ret_prev_wr_rs1_snap <= ret_prev_wr_rs1_now;
                call_jalr_prev_wr_rs1_snap <= call_jalr_prev_wr_rs1_now;
                indirect_jalr_prev_wr_rs1_snap <= indirect_jalr_prev_wr_rs1_now;
                auipc_jalr_snap <= auipc_jalr_now;
                auipc_ret_snap <= auipc_ret_now;
                auipc_call_jalr_snap <= auipc_call_jalr_now;
                auipc_indirect_jalr_snap <= auipc_indirect_jalr_now;
                pred_taken_snap     <= pred_taken_now;
                dir_correct_snap    <= dir_correct_now;
                target_correct_snap <= target_correct_now;
                mispredict_snap     <= mispredict_now;
                branch_miss_taken_snap <= branch_miss_taken_now;
                branch_miss_nt_snap <= branch_miss_nt_now;
                branch_hit_forward_snap <= branch_hit_forward_now;
                branch_hit_backward_snap <= branch_hit_backward_now;
                branch_miss_forward_snap <= branch_miss_forward_now;
                branch_miss_backward_snap <= branch_miss_backward_now;
                if_branch_hit_snap  <= if_branch_hit_now;
                if_branch_nohit_snap <= if_branch_nohit_now;
                if_branch_nohit_back_snap <= if_branch_nohit_back_now;
                if_branch_nohit_back_ok_snap <= if_branch_nohit_back_ok_now;
                if_branch_nohit_back_redirect_snap <= if_branch_nohit_back_redirect_now;
                slot1_redirect_snap <= slot1_redirect_now;
                bht_tag_alias_snap  <= bht_tag_alias_now;
                bht_store_snap      <= bht_store_now;
                bht_store_conflict_snap <= bht_store_conflict_now;
                bht_store_imm_overlap_snap <= bht_store_imm_overlap_now;
            end
        end
    end

    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && !u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == `MMIO_REGION_NIBBLE
                && u_cpu.bus_m_addr[5:0] != `MMIO_UART_TX_OFFSET
                && u_cpu.bus_m_addr[5:0] != `MMIO_UART_STATUS_OFFSET) begin
            $display("[%0t ns] MMIO READ  addr=%08x", $time, u_cpu.bus_m_addr);
            #10;
            $display("data=%08x ", u_cpu.bus_m_dat_o);
        end
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == `MMIO_REGION_NIBBLE
                && u_cpu.bus_m_addr[5:0] != `MMIO_UART_TX_OFFSET
                && u_cpu.bus_m_addr[5:0] != `MMIO_UART_STATUS_OFFSET) begin
            $display("[%0t ns] MMIO WRITE  addr=%08x", $time, u_cpu.bus_m_addr);
            #10;
            $display("data=%08x ", u_cpu.bus_m_dat_o);
        end
    end

    always @(led) begin
        $display("[%0t ns] LED = %04x", $time, led);
    end

    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr == 32'hF0000008) begin
            $display("[%0t ns] TOHOST WRITE = %08x", $time, u_cpu.bus_m_dat_i);
            if (u_cpu.bus_m_dat_i != 0) begin
                $display("=== Simulation END, LED=%04x ===", led);
                #100;
                $finish;
            end
        end
    end

    always @(posedge clk) begin
        if (u_cpu.u_mmio.uart_valid) begin
            $write("%c", u_cpu.u_mmio.uart_data);

            if (!dhry_capture_active) begin
                if (u_cpu.u_mmio.uart_data == dhry_key_char(dhry_key_pos)) begin
                    if (dhry_key_pos == 21) begin
                        dhry_capture_active = 1'b1;
                        dhry_seen_digit = 1'b0;
                        dhry_dps_accum = 0;
                        dhry_key_pos = 0;
                    end else begin
                        dhry_key_pos = dhry_key_pos + 1;
                    end
                end else if (u_cpu.u_mmio.uart_data == dhry_key_char(0))
                    dhry_key_pos = 1;
                else
                    dhry_key_pos = 0;
            end else begin
                if ((u_cpu.u_mmio.uart_data >= "0") && (u_cpu.u_mmio.uart_data <= "9")) begin
                    dhry_dps_accum = dhry_dps_accum * 10 + (u_cpu.u_mmio.uart_data - "0");
                    dhry_seen_digit = 1'b1;
                end else if ((u_cpu.u_mmio.uart_data == " ") || (u_cpu.u_mmio.uart_data == 8'h09)) begin
                    if (dhry_seen_digit) begin
                        dhry_dps_value = dhry_dps_accum;
                        dhry_dps_valid = 1'b1;
                        dhry_capture_active = 1'b0;
                        dhry_seen_digit = 1'b0;
                        dhry_dps_accum = 0;
                    end
                end else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d)) begin
                    if (dhry_seen_digit) begin
                        dhry_dps_value = dhry_dps_accum;
                        dhry_dps_valid = 1'b1;
                    end
                    dhry_capture_active = 1'b0;
                    dhry_seen_digit = 1'b0;
                    dhry_dps_accum = 0;
                end else begin
                    dhry_capture_active = 1'b0;
                    dhry_seen_digit = 1'b0;
                    dhry_dps_accum = 0;
                    if (u_cpu.u_mmio.uart_data == dhry_key_char(0))
                        dhry_key_pos = 1;
                    else
                        dhry_key_pos = 0;
                end
            end

            if (uart_bench_parse_state == UART_BENCH_PARSE_WAIT_C) begin
                if (u_cpu.u_mmio.uart_data == ipc_key_char(uart_ipc_key_pos)) begin
                    if (uart_ipc_key_pos == 3) begin
                        uart_ipc_key_pos = 0;
                        uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C_EQ;
                        uart_bench_c_seen_digit = 1'b0;
                        uart_bench_i_seen_digit = 1'b0;
                        uart_bench_c_accum = 64'd0;
                        uart_bench_i_accum = 64'd0;
                        uart_bench_cycle_valid = 1'b0;
                        uart_bench_instret_valid = 1'b0;
                    end else begin
                        uart_ipc_key_pos = uart_ipc_key_pos + 1;
                    end
                end else if (u_cpu.u_mmio.uart_data == ipc_key_char(0)) begin
                    uart_ipc_key_pos = 1;
                end else begin
                    uart_ipc_key_pos = 0;
                end
            end else if (uart_bench_parse_state == UART_BENCH_PARSE_WAIT_C_EQ) begin
                if (u_cpu.u_mmio.uart_data == "C")
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C_EQ;
                else if (u_cpu.u_mmio.uart_data == "=")
                    uart_bench_parse_state = UART_BENCH_PARSE_CAP_C;
                else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d))
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
            end else if (uart_bench_parse_state == UART_BENCH_PARSE_CAP_C) begin
                if ((u_cpu.u_mmio.uart_data >= "0") && (u_cpu.u_mmio.uart_data <= "9")) begin
                    uart_bench_c_accum = uart_bench_c_accum * 10 + (u_cpu.u_mmio.uart_data - "0");
                    uart_bench_c_seen_digit = 1'b1;
                end else if (uart_bench_c_seen_digit) begin
                    uart_bench_cycle_value = uart_bench_c_accum;
                    uart_bench_cycle_valid = 1'b1;
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_I;
                end else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d)) begin
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
                end
            end else if (uart_bench_parse_state == UART_BENCH_PARSE_WAIT_I) begin
                if (u_cpu.u_mmio.uart_data == "I")
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_I_EQ;
                else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d))
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
            end else if (uart_bench_parse_state == UART_BENCH_PARSE_WAIT_I_EQ) begin
                if (u_cpu.u_mmio.uart_data == "=")
                    uart_bench_parse_state = UART_BENCH_PARSE_CAP_I;
                else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d))
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
            end else if (uart_bench_parse_state == UART_BENCH_PARSE_CAP_I) begin
                if ((u_cpu.u_mmio.uart_data >= "0") && (u_cpu.u_mmio.uart_data <= "9")) begin
                    uart_bench_i_accum = uart_bench_i_accum * 10 + (u_cpu.u_mmio.uart_data - "0");
                    uart_bench_i_seen_digit = 1'b1;
                end else if (uart_bench_i_seen_digit) begin
                    uart_bench_instret_value = uart_bench_i_accum;
                    uart_bench_instret_valid = 1'b1;
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
                    uart_bench_c_seen_digit = 1'b0;
                    uart_bench_i_seen_digit = 1'b0;
                    uart_bench_c_accum = 64'd0;
                    uart_bench_i_accum = 64'd0;
                end else if ((u_cpu.u_mmio.uart_data == 8'h0a) || (u_cpu.u_mmio.uart_data == 8'h0d)) begin
                    uart_bench_parse_state = UART_BENCH_PARSE_WAIT_C;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (u_cpu.u_mmio.tohost) begin
            cycle_win          = stat_cycle_total - cycle_snap;
            instr_win          = instr_total          - instr_snap;
            flush_win          = flush_total          - flush_snap;
            load_stall_win     = load_stall_total     - load_stall_snap;
            false_load_stall_win = false_load_stall_total - false_load_stall_snap;
            mul_hold_win       = mul_hold_total       - mul_hold_snap;
            other_bubble_win   = other_bubble_total   - other_bubble_snap;
            wb_commit_win      = wb_commit_total      - wb_commit_snap;
            branch_win         = branch_total         - branch_snap;
            branch_taken_win   = branch_taken_total   - branch_taken_snap;
            branch_both_taken_win = branch_both_taken_total - branch_both_taken_snap;
            jal_win            = jal_total            - jal_snap;
            jal_pred_win       = jal_pred_total       - jal_pred_snap;
            jal_correct_win    = jal_correct_total    - jal_correct_snap;
            jalr_win           = jalr_total           - jalr_snap;
            jalr_pred_win      = jalr_pred_total      - jalr_pred_snap;
            jalr_correct_win   = jalr_correct_total   - jalr_correct_snap;
            ret_win            = ret_total           - ret_snap;
            ret_pred_win       = ret_pred_total      - ret_pred_snap;
            ret_correct_win    = ret_correct_total   - ret_correct_snap;
            call_jalr_win      = call_jalr_total     - call_jalr_snap;
            call_jalr_pred_win = call_jalr_pred_total - call_jalr_pred_snap;
            call_jalr_correct_win = call_jalr_correct_total - call_jalr_correct_snap;
            indirect_jalr_win  = indirect_jalr_total - indirect_jalr_snap;
            indirect_jalr_pred_win = indirect_jalr_pred_total - indirect_jalr_pred_snap;
            indirect_jalr_correct_win = indirect_jalr_correct_total - indirect_jalr_correct_snap;
            jalr_prev_wr_rs1_win = jalr_prev_wr_rs1_total - jalr_prev_wr_rs1_snap;
            ret_prev_wr_rs1_win = ret_prev_wr_rs1_total - ret_prev_wr_rs1_snap;
            call_jalr_prev_wr_rs1_win = call_jalr_prev_wr_rs1_total - call_jalr_prev_wr_rs1_snap;
            indirect_jalr_prev_wr_rs1_win = indirect_jalr_prev_wr_rs1_total - indirect_jalr_prev_wr_rs1_snap;
            auipc_jalr_win = auipc_jalr_total - auipc_jalr_snap;
            auipc_ret_win = auipc_ret_total - auipc_ret_snap;
            auipc_call_jalr_win = auipc_call_jalr_total - auipc_call_jalr_snap;
            auipc_indirect_jalr_win = auipc_indirect_jalr_total - auipc_indirect_jalr_snap;
            pred_taken_win     = pred_taken_total     - pred_taken_snap;
            dir_correct_win    = dir_correct_total    - dir_correct_snap;
            target_correct_win = target_correct_total - target_correct_snap;
            mispredict_win     = mispredict_total     - mispredict_snap;
            branch_miss_taken_win = branch_miss_taken_total - branch_miss_taken_snap;
            branch_miss_nt_win = branch_miss_nt_total - branch_miss_nt_snap;
            branch_hit_forward_win = branch_hit_forward_total - branch_hit_forward_snap;
            branch_hit_backward_win = branch_hit_backward_total - branch_hit_backward_snap;
            branch_miss_forward_win = branch_miss_forward_total - branch_miss_forward_snap;
            branch_miss_backward_win = branch_miss_backward_total - branch_miss_backward_snap;
            if_branch_hit_win  = if_branch_hit_total  - if_branch_hit_snap;
            if_branch_nohit_win = if_branch_nohit_total - if_branch_nohit_snap;
            if_branch_nohit_back_win = if_branch_nohit_back_total - if_branch_nohit_back_snap;
            if_branch_nohit_back_ok_win = if_branch_nohit_back_ok_total - if_branch_nohit_back_ok_snap;
            if_branch_nohit_back_redirect_win = if_branch_nohit_back_redirect_total - if_branch_nohit_back_redirect_snap;
            slot1_redirect_win = slot1_redirect_total - slot1_redirect_snap;
            bht_tag_alias_win  = bht_tag_alias_total  - bht_tag_alias_snap;
            bht_store_win      = bht_store_total      - bht_store_snap;
            bht_store_conflict_win = bht_store_conflict_total - bht_store_conflict_snap;
            bht_store_imm_overlap_win = bht_store_imm_overlap_total - bht_store_imm_overlap_snap;

            if (BP_STATS_ENABLE) begin
                print_bp_stats(stat_cycle_total,
                               instr_total,
                               flush_total,
                               load_stall_total,
                               false_load_stall_total,
                               mul_hold_total,
                               other_bubble_total,
                               branch_total,
                               branch_taken_total,
                               branch_both_taken_total,
                               jal_total,
                               jal_pred_total,
                               jal_correct_total,
                               jalr_total,
                               jalr_pred_total,
                               jalr_correct_total,
                               ret_total,
                               ret_pred_total,
                               ret_correct_total,
                               call_jalr_total,
                               call_jalr_pred_total,
                               call_jalr_correct_total,
                               indirect_jalr_total,
                               indirect_jalr_pred_total,
                               indirect_jalr_correct_total,
                               pred_taken_total,
                               dir_correct_total,
                               target_correct_total,
                               mispredict_total,
                               branch_miss_taken_total,
                               branch_miss_nt_total,
                               branch_hit_forward_total,
                               branch_hit_backward_total,
                               branch_miss_forward_total,
                               branch_miss_backward_total,
                               if_branch_hit_total,
                               if_branch_nohit_total,
                               if_branch_nohit_back_total,
                               if_branch_nohit_back_ok_total,
                               if_branch_nohit_back_redirect_total,
                               slot1_redirect_total,
                               wb_commit_total,
                               bht_tag_alias_total,
                               bht_store_total,
                               bht_store_conflict_total,
                               bht_store_imm_overlap_total,
                               mul_exec_total,
                               mul_follow_slot_total,
                               mul_dep_slot_total,
                               mul_dep_d1_total,
                               mul_dep_d2_total,
                               mul_dep_d3_total);
                print_slot1_branch_stats(stat_cycle_total,
                                         branch_total,
                                         slot1_branch_seen_total,
                                         slot1_branch_issue_total,
                                         slot1_branch_back_total,
                                         slot1_branch_issue_back_total);
                print_slot1_ctrl_stats(stat_cycle_total);
            end
            print_bench_ipc_crosscheck();
            $display("LED = %04X", u_cpu.u_mmio.led);
            //if (u_cpu.u_mmio.led == 16'h0000)
            //    $display(">>> PASSED <<<");
            //else
            //    $display(">>> FAILED at sub-test %0d <<<", u_cpu.u_mmio.led);
            $finish;
        end
    end

endmodule
