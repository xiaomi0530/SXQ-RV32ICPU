`timescale 1ns / 1ps

module cpu_tb;

    localparam BP_STATS_ENABLE = 1'b1;
    localparam PERIODIC_STATS_ENABLE = 1'b0;
    localparam [31:0] MMIO_TIMER_LO_ADDR = 32'hF0000000;
    localparam [31:0] MMIO_TIMER_HI_ADDR = 32'hF0000004;
    localparam integer JALR_PC_STAT_SLOTS = 16;

    reg  clk;
    reg  rst_n;
    wire [15:0] led;

    integer cycle_count;
    integer stat_cycle_total;
    integer timer_req_count;
    reg     stat_active;

    integer instr_total;
    integer flush_total;
    integer load_stall_total;
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
    integer branch_hit_total;
    integer slot1_redirect_total;

    integer cycle_snap;

    integer instr_snap;
    integer flush_snap;
    integer load_stall_snap;
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
    integer branch_hit_snap;
    integer slot1_redirect_snap;

    integer instr_now;
    integer flush_now;
    integer load_stall_now;
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
    integer branch_hit_now;
    integer slot1_redirect_now;

    integer cycle_win;
    integer stat_cycle_win;
    integer init_i;
    integer jalr_pc_i;
    integer jalr_pc_slot;
    integer jalr_pc_free;

    integer instr_win;
    integer flush_win;
    integer load_stall_win;
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
    integer branch_hit_win;
    integer slot1_redirect_win;

    reg         prev_issue_valid;
    reg         prev_issue_we;
    reg  [4:0]  prev_issue_rd;
    reg  [31:0] prev_issue_instr;
    reg         jalr_pc_valid [0:JALR_PC_STAT_SLOTS-1];
    reg  [31:0] jalr_pc_addr  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_exec  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_pred  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_ok    [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_ret   [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_call  [0:JALR_PC_STAT_SLOTS-1];
    integer     jalr_pc_other [0:JALR_PC_STAT_SLOTS-1];

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

    function integer pct_x100;
        input integer numer;
        input integer denom;
        begin
            if (denom != 0)
                pct_x100 = (numer * 10000 + (denom / 2)) / denom;
            else
                pct_x100 = 0;
        end
    endfunction

    wire issue_instr_fire = !u_cpu.pipeline_flush
                         && !u_cpu.pipeline_stall
                         && !u_cpu.pipeline_hold
                         && (u_cpu.id_instr != 32'b0);
    wire timer_req_fire = u_cpu.ex_dmem_re
                       && ((u_cpu.ex_dmem_wr_addr == MMIO_TIMER_LO_ADDR)
                        || (u_cpu.ex_dmem_wr_addr == MMIO_TIMER_HI_ADDR));

    task print_bp_stats;
        input integer show_cycle;
        input integer win_cycle;
        input integer total_instr;
        input integer total_flush;
        input integer total_load_stall;
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
        input integer total_branch_hit;
        input integer total_slot1_redirect;
        input integer total_wb_commit;
        input integer win_instr;
        input integer win_flush;
        input integer win_load_stall;
        input integer win_mul_hold;
        input integer win_other_bubble;
        input integer win_branch;
        input integer win_branch_taken;
        input integer win_branch_both_taken;
        input integer win_jal;
        input integer win_jal_pred;
        input integer win_jal_correct;
        input integer win_jalr;
        input integer win_jalr_pred;
        input integer win_jalr_correct;
        input integer win_ret;
        input integer win_ret_pred;
        input integer win_ret_correct;
        input integer win_call_jalr;
        input integer win_call_jalr_pred;
        input integer win_call_jalr_correct;
        input integer win_indirect_jalr;
        input integer win_indirect_jalr_pred;
        input integer win_indirect_jalr_correct;
        input integer win_pred_taken;
        input integer win_dir_correct;
        input integer win_target_correct;
        input integer win_mispredict;
        input integer win_branch_hit;
        input integer win_slot1_redirect;
        input integer win_wb_commit;
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
        integer total_loss;
        integer win_loss;
        integer total_loss_pct_x100;
        integer win_loss_pct_x100;
        integer total_flush_share_x100;
        integer total_load_stall_share_x100;
        integer total_mul_hold_share_x100;
        integer total_other_bubble_share_x100;
        integer win_flush_share_x100;
        integer win_load_stall_share_x100;
        integer win_mul_hold_share_x100;
        integer win_other_bubble_share_x100;
        integer win_dir_acc_x100;
        integer win_taken_prec_x100;
        integer win_taken_recall_x100;
        integer win_target_acc_x100;
        integer win_pred_cov_x100;
        integer win_miss_rate_x100;
        integer win_ctrl_share_x100;
        integer win_ipc_x1000;
        integer win_jal_acc_x100;
        integer win_jal_pred_rate_x100;
        integer win_jalr_acc_x100;
        integer win_jalr_pred_rate_x100;
        integer win_ret_acc_x100;
        integer win_ret_pred_rate_x100;
        integer win_call_jalr_acc_x100;
        integer win_call_jalr_pred_rate_x100;
        integer win_indirect_jalr_acc_x100;
        integer win_indirect_jalr_pred_rate_x100;
        integer win_dir_wrong;
        integer win_target_wrong;
        integer win_branch_nt;
        integer win_ctrl_total;
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
            total_loss              = show_cycle - total_instr;
            total_loss_pct_x100     = pct_x100(total_loss, show_cycle);
            total_flush_share_x100      = pct_x100(total_flush, total_loss);
            total_load_stall_share_x100 = pct_x100(total_load_stall, total_loss);
            total_mul_hold_share_x100   = pct_x100(total_mul_hold, total_loss);
            total_other_bubble_share_x100 = pct_x100(total_other_bubble, total_loss);
            win_dir_acc_x100        = pct_x100(win_dir_correct, win_branch);
            win_taken_prec_x100     = pct_x100(win_target_correct, win_pred_taken);
            win_taken_recall_x100   = pct_x100(win_target_correct, win_branch_taken);
            win_target_acc_x100     = pct_x100(win_target_correct, win_branch_both_taken);
            win_pred_cov_x100       = pct_x100(win_pred_taken, win_branch);
            win_miss_rate_x100      = pct_x100(win_mispredict, win_branch);
            win_ctrl_total          = win_branch + win_jal + win_jalr;
            win_ctrl_share_x100     = pct_x100(win_ctrl_total, win_instr);
            win_ipc_x1000           = (win_cycle != 0) ? ((win_instr * 1000 + (win_cycle / 2)) / win_cycle) : 0;
            win_jal_acc_x100        = pct_x100(win_jal_correct, win_jal);
            win_jal_pred_rate_x100  = pct_x100(win_jal_pred, win_jal);
            win_jalr_acc_x100       = pct_x100(win_jalr_correct, win_jalr);
            win_jalr_pred_rate_x100 = pct_x100(win_jalr_pred, win_jalr);
            win_ret_acc_x100        = pct_x100(win_ret_correct, win_ret);
            win_ret_pred_rate_x100  = pct_x100(win_ret_pred, win_ret);
            win_call_jalr_acc_x100  = pct_x100(win_call_jalr_correct, win_call_jalr);
            win_call_jalr_pred_rate_x100 = pct_x100(win_call_jalr_pred, win_call_jalr);
            win_indirect_jalr_acc_x100 = pct_x100(win_indirect_jalr_correct, win_indirect_jalr);
            win_indirect_jalr_pred_rate_x100 = pct_x100(win_indirect_jalr_pred, win_indirect_jalr);
            win_dir_wrong           = win_branch - win_dir_correct;
            win_target_wrong        = win_branch_both_taken - win_target_correct;
            win_branch_nt           = win_branch - win_branch_taken;
            win_loss                = win_cycle - win_instr;
            win_loss_pct_x100       = pct_x100(win_loss, win_cycle);
            win_flush_share_x100      = pct_x100(win_flush, win_loss);
            win_load_stall_share_x100 = pct_x100(win_load_stall, win_loss);
            win_mul_hold_share_x100   = pct_x100(win_mul_hold, win_loss);
            win_other_bubble_share_x100 = pct_x100(win_other_bubble, win_loss);

            $display("");
            $display("[STAT][%0d cyc] KEY total: IPC=%0d.%03d  CTRL=%0d.%02d%%  |  BR dir_acc=%0d.%02d%%  taken_ok_prec=%0d.%02d%%  taken_ok_rec=%0d.%02d%%  miss=%0d.%02d%%",
                     show_cycle,
                     total_ipc_x1000 / 1000, total_ipc_x1000 % 1000,
                     total_ctrl_share_x100 / 100, total_ctrl_share_x100 % 100,
                     total_dir_acc_x100 / 100, total_dir_acc_x100 % 100,
                     total_taken_prec_x100 / 100, total_taken_prec_x100 % 100,
                     total_taken_recall_x100 / 100, total_taken_recall_x100 % 100,
                     total_miss_rate_x100 / 100, total_miss_rate_x100 % 100);
            $display("[STAT][%0d cyc] KEY win  : IPC=%0d.%03d  CTRL=%0d.%02d%%  |  BR dir_acc=%0d.%02d%%  taken_ok_prec=%0d.%02d%%  taken_ok_rec=%0d.%02d%%  miss=%0d.%02d%%",
                     show_cycle,
                     win_ipc_x1000 / 1000, win_ipc_x1000 % 1000,
                     win_ctrl_share_x100 / 100, win_ctrl_share_x100 % 100,
                     win_dir_acc_x100 / 100, win_dir_acc_x100 % 100,
                     win_taken_prec_x100 / 100, win_taken_prec_x100 % 100,
                     win_taken_recall_x100 / 100, win_taken_recall_x100 % 100,
                     win_miss_rate_x100 / 100, win_miss_rate_x100 % 100);
            $display("[STAT][%0d cyc] BR  total: all=%0d taken=%0d nt=%0d predT=%0d cover=%0d.%02d%% bothT=%0d dir_ok=%0d dir_bad=%0d tgt_ok=%0d tgt_bad=%0d tgt_acc=%0d.%02d%% mis=%0d",
                     show_cycle,
                     total_branch, total_branch_taken, total_branch_nt, total_pred_taken,
                     total_pred_cov_x100 / 100, total_pred_cov_x100 % 100,
                     total_branch_both_taken, total_dir_correct, total_dir_wrong,
                     total_target_correct, total_target_wrong,
                     total_target_acc_x100 / 100, total_target_acc_x100 % 100,
                     total_mispredict);
            $display("[STAT][%0d cyc] BR  win  : all=%0d taken=%0d nt=%0d predT=%0d cover=%0d.%02d%% bothT=%0d dir_ok=%0d dir_bad=%0d tgt_ok=%0d tgt_bad=%0d tgt_acc=%0d.%02d%% mis=%0d",
                     show_cycle,
                     win_branch, win_branch_taken, win_branch_nt, win_pred_taken,
                     win_pred_cov_x100 / 100, win_pred_cov_x100 % 100,
                     win_branch_both_taken, win_dir_correct, win_dir_wrong,
                     win_target_correct, win_target_wrong,
                     win_target_acc_x100 / 100, win_target_acc_x100 % 100,
                     win_mispredict);
            $display("[STAT][%0d cyc] JMP total: jal=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)  |  jalr=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_jal, total_jal_pred, total_jal_pred_rate_x100 / 100, total_jal_pred_rate_x100 % 100,
                     total_jal_correct, total_jal_acc_x100 / 100, total_jal_acc_x100 % 100,
                     total_jalr, total_jalr_pred, total_jalr_pred_rate_x100 / 100, total_jalr_pred_rate_x100 % 100,
                     total_jalr_correct, total_jalr_acc_x100 / 100, total_jalr_acc_x100 % 100);
            $display("[STAT][%0d cyc] JALR split: ret=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)  |  call=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)  |  other=%0d pred=%0d(%0d.%02d%%) ok=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_ret, total_ret_pred, total_ret_pred_rate_x100 / 100, total_ret_pred_rate_x100 % 100,
                     total_ret_correct, total_ret_acc_x100 / 100, total_ret_acc_x100 % 100,
                     total_call_jalr, total_call_jalr_pred, total_call_jalr_pred_rate_x100 / 100, total_call_jalr_pred_rate_x100 % 100,
                     total_call_jalr_correct, total_call_jalr_acc_x100 / 100, total_call_jalr_acc_x100 % 100,
                     total_indirect_jalr, total_indirect_jalr_pred, total_indirect_jalr_pred_rate_x100 / 100, total_indirect_jalr_pred_rate_x100 % 100,
                     total_indirect_jalr_correct, total_indirect_jalr_acc_x100 / 100, total_indirect_jalr_acc_x100 % 100);
            $display("[STAT][%0d cyc] FE  total: if_branch_hit=%0d(%0d.%02d%% cyc)  slot1_redir=%0d(%0d.%02d%% cyc)  wb=%0d",
                     show_cycle,
                     total_branch_hit, pct_x100(total_branch_hit, show_cycle) / 100, pct_x100(total_branch_hit, show_cycle) % 100,
                     total_slot1_redirect, pct_x100(total_slot1_redirect, show_cycle) / 100, pct_x100(total_slot1_redirect, show_cycle) % 100,
                     total_wb_commit);
            $display("[STAT][%0d cyc] FE  win  : if_branch_hit=%0d(%0d.%02d%% cyc)  slot1_redir=%0d(%0d.%02d%% cyc)  wb=%0d",
                     show_cycle,
                     win_branch_hit, pct_x100(win_branch_hit, win_cycle) / 100, pct_x100(win_branch_hit, win_cycle) % 100,
                     win_slot1_redirect, pct_x100(win_slot1_redirect, win_cycle) / 100, pct_x100(win_slot1_redirect, win_cycle) % 100,
                     win_wb_commit);
            $display("[STAT][%0d cyc] NOTE: taken_ok = predicted taken + actually taken + target correct", show_cycle);
            $display("[STAT][%0d cyc] LOSS total=%0d (%0d.%02d%% cyc): flush=%0d(%0d.%02d%%) ld=%0d(%0d.%02d%%) mul=%0d(%0d.%02d%%) bub=%0d(%0d.%02d%%)",
                     show_cycle,
                     total_loss, total_loss_pct_x100 / 100, total_loss_pct_x100 % 100,
                     total_flush, total_flush_share_x100 / 100, total_flush_share_x100 % 100,
                     total_load_stall, total_load_stall_share_x100 / 100, total_load_stall_share_x100 % 100,
                     total_mul_hold, total_mul_hold_share_x100 / 100, total_mul_hold_share_x100 % 100,
                     total_other_bubble, total_other_bubble_share_x100 / 100, total_other_bubble_share_x100 % 100);
            $display("[STAT][%0d cyc] LOSS win  =%0d (%0d.%02d%% cyc): flush=%0d(%0d.%02d%%) ld=%0d(%0d.%02d%%) mul=%0d(%0d.%02d%%) bub=%0d(%0d.%02d%%)",
                     show_cycle,
                     win_loss, win_loss_pct_x100 / 100, win_loss_pct_x100 % 100,
                     win_flush, win_flush_share_x100 / 100, win_flush_share_x100 % 100,
                     win_load_stall, win_load_stall_share_x100 / 100, win_load_stall_share_x100 % 100,
                     win_mul_hold, win_mul_hold_share_x100 / 100, win_mul_hold_share_x100 % 100,
                     win_other_bubble, win_other_bubble_share_x100 / 100, win_other_bubble_share_x100 % 100);
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

        instr_total = 0;
        flush_total = 0;
        load_stall_total = 0;
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
        branch_hit_total = 0;
        slot1_redirect_total = 0;

        cycle_snap = 0;
        instr_snap = 0;
        flush_snap = 0;
        load_stall_snap = 0;
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
        branch_hit_snap = 0;
        slot1_redirect_snap = 0;
        prev_issue_valid = 1'b0;
        prev_issue_we = 1'b0;
        prev_issue_rd = 5'd0;
        prev_issue_instr = 32'b0;

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

        #100;
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 0;
            prev_issue_valid <= 1'b0;
            prev_issue_we    <= 1'b0;
            prev_issue_rd    <= 5'd0;
            prev_issue_instr <= 32'b0;
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
        end else begin
            cycle_count <= cycle_count + 1;

            if (timer_req_fire) begin
                if (timer_req_count == 2)
                    stat_active <= 1'b1;
                else if (timer_req_count == 3)
                    stat_active <= 1'b0;
                timer_req_count <= timer_req_count + 1;
            end

            stat_cycle_win = stat_active ? 1 : 0;

            instr_now          = instr_total          + ((stat_cycle_win && issue_instr_fire) ? 1 : 0);
            flush_now          = flush_total          + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_flush) ? 1 : 0);
            load_stall_now     = load_stall_total     + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_stall && !u_cpu.pipeline_flush) ? 1 : 0);
            mul_hold_now       = mul_hold_total       + ((stat_cycle_win && !issue_instr_fire && u_cpu.pipeline_hold && !u_cpu.pipeline_flush && !u_cpu.pipeline_stall) ? 1 : 0);
            other_bubble_now   = other_bubble_total   + ((stat_cycle_win && !issue_instr_fire && !u_cpu.pipeline_flush && !u_cpu.pipeline_stall && !u_cpu.pipeline_hold) ? 1 : 0);
            wb_commit_now      = wb_commit_total      + ((stat_cycle_win && u_cpu.wb_regs_we) ? 1 : 0);
            branch_hit_now       = branch_hit_total       + ((stat_cycle_win && u_cpu.if_branch_hit) ? 1 : 0);
            slot1_redirect_now = slot1_redirect_total + ((stat_cycle_win && u_cpu.slot1_pred_redirect) ? 1 : 0);

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
            auipc_jalr_now = auipc_jalr_total;
            auipc_ret_now = auipc_ret_total;
            auipc_call_jalr_now = auipc_call_jalr_total;
            auipc_indirect_jalr_now = auipc_indirect_jalr_total;
            pred_taken_now     = pred_taken_total;
            dir_correct_now    = dir_correct_total;
            target_correct_now = target_correct_total;
            mispredict_now     = mispredict_total;

            if (stat_cycle_win && u_cpu.ex_branch_flag) begin
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
            end else if (stat_cycle_win && u_cpu.ex_jump_flag) begin
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

            if (jalr_prev_wr_rs1_fire) begin
                jalr_prev_wr_rs1_now = jalr_prev_wr_rs1_now + 1;
                if (u_cpu.id_ret_flag)
                    ret_prev_wr_rs1_now = ret_prev_wr_rs1_now + 1;
                else if (u_cpu.id_call_flag)
                    call_jalr_prev_wr_rs1_now = call_jalr_prev_wr_rs1_now + 1;
                else
                    indirect_jalr_prev_wr_rs1_now = indirect_jalr_prev_wr_rs1_now + 1;
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

            if (stat_cycle_win && u_cpu.ex_jump_flag && u_cpu.ex_jalr_flag) begin
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
                        jalr_pc_valid[jalr_pc_slot] <= 1'b1;
                        jalr_pc_addr[jalr_pc_slot]  <= u_cpu.ex_instr_addr;
                        jalr_pc_exec[jalr_pc_slot]  <= 0;
                        jalr_pc_pred[jalr_pc_slot]  <= 0;
                        jalr_pc_ok[jalr_pc_slot]    <= 0;
                        jalr_pc_ret[jalr_pc_slot]   <= 0;
                        jalr_pc_call[jalr_pc_slot]  <= 0;
                        jalr_pc_other[jalr_pc_slot] <= 0;
                    end

                    jalr_pc_exec[jalr_pc_slot] <= jalr_pc_exec[jalr_pc_slot] + 1;
                    if (u_cpu.ex_pred_taken)
                        jalr_pc_pred[jalr_pc_slot] <= jalr_pc_pred[jalr_pc_slot] + 1;
                    if (!u_cpu.ex_mispredict)
                        jalr_pc_ok[jalr_pc_slot] <= jalr_pc_ok[jalr_pc_slot] + 1;
                    if (u_cpu.ex_ret_flag)
                        jalr_pc_ret[jalr_pc_slot] <= jalr_pc_ret[jalr_pc_slot] + 1;
                    else if (u_cpu.ex_call_flag)
                        jalr_pc_call[jalr_pc_slot] <= jalr_pc_call[jalr_pc_slot] + 1;
                    else
                        jalr_pc_other[jalr_pc_slot] <= jalr_pc_other[jalr_pc_slot] + 1;
                end
            end

            stat_cycle_total     <= stat_cycle_total + stat_cycle_win;
            instr_total          <= instr_now;
            flush_total          <= flush_now;
            load_stall_total     <= load_stall_now;
            mul_hold_total       <= mul_hold_now;
            other_bubble_total   <= other_bubble_now;
            wb_commit_total      <= wb_commit_now;
            branch_hit_total       <= branch_hit_now;
            slot1_redirect_total <= slot1_redirect_now;
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
            auipc_jalr_total <= auipc_jalr_now;
            auipc_ret_total <= auipc_ret_now;
            auipc_call_jalr_total <= auipc_call_jalr_now;
            auipc_indirect_jalr_total <= auipc_indirect_jalr_now;
            pred_taken_total     <= pred_taken_now;
            dir_correct_total    <= dir_correct_now;
            target_correct_total <= target_correct_now;
            mispredict_total     <= mispredict_now;

            if (issue_instr_fire) begin
                prev_issue_valid <= 1'b1;
                prev_issue_we    <= u_cpu.id_regs_we;
                prev_issue_rd    <= u_cpu.id_regs_w_addr;
                prev_issue_instr <= u_cpu.id_instr;
            end

            if (PERIODIC_STATS_ENABLE && BP_STATS_ENABLE && (stat_cycle_total != 0)
                    && ((stat_cycle_total % 10000) == 0)) begin
                cycle_win          = stat_cycle_total - cycle_snap;
                instr_win          = instr_now          - instr_snap;
                flush_win          = flush_now          - flush_snap;
                load_stall_win     = load_stall_now     - load_stall_snap;
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
                branch_hit_win       = branch_hit_now       - branch_hit_snap;
                slot1_redirect_win = slot1_redirect_now - slot1_redirect_snap;

                print_bp_stats(stat_cycle_total,
                               cycle_win,
                               instr_now,
                               flush_now, load_stall_now, mul_hold_now, other_bubble_now,
                               branch_now, branch_taken_now, branch_both_taken_now,
                               jal_now, jal_pred_now, jal_correct_now,
                               jalr_now, jalr_pred_now, jalr_correct_now,
                               ret_now, ret_pred_now, ret_correct_now,
                               call_jalr_now, call_jalr_pred_now, call_jalr_correct_now,
                               indirect_jalr_now, indirect_jalr_pred_now, indirect_jalr_correct_now,
                               pred_taken_now,
                               dir_correct_now, target_correct_now, mispredict_now,
                               branch_hit_now, slot1_redirect_now, wb_commit_now,
                               instr_win,
                               flush_win, load_stall_win, mul_hold_win, other_bubble_win,
                               branch_win, branch_taken_win, branch_both_taken_win,
                               jal_win, jal_pred_win, jal_correct_win,
                               jalr_win, jalr_pred_win, jalr_correct_win,
                               ret_win, ret_pred_win, ret_correct_win,
                               call_jalr_win, call_jalr_pred_win, call_jalr_correct_win,
                               indirect_jalr_win, indirect_jalr_pred_win, indirect_jalr_correct_win,
                               pred_taken_win,
                               dir_correct_win, target_correct_win, mispredict_win,
                               branch_hit_win, slot1_redirect_win, wb_commit_win);
                $display("[STAT][%0d cyc] JALR dep win : prev_wr_rs1=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         jalr_prev_wr_rs1_win,
                         pct_x100(jalr_prev_wr_rs1_win, jalr_win) / 100,
                         pct_x100(jalr_prev_wr_rs1_win, jalr_win) % 100,
                         ret_prev_wr_rs1_win,
                         call_jalr_prev_wr_rs1_win,
                         indirect_jalr_prev_wr_rs1_win);
                $display("[STAT][%0d cyc] AUIPC+JALR win: pair=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         auipc_jalr_win,
                         pct_x100(auipc_jalr_win, jalr_win) / 100,
                         pct_x100(auipc_jalr_win, jalr_win) % 100,
                         auipc_ret_win,
                         auipc_call_jalr_win,
                         auipc_indirect_jalr_win);

                cycle_snap          <= stat_cycle_total;
                instr_snap          <= instr_now;
                flush_snap          <= flush_now;
                load_stall_snap     <= load_stall_now;
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
                branch_hit_snap       <= branch_hit_now;
                slot1_redirect_snap <= slot1_redirect_now;
            end
        end
    end

    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && !u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF
                && u_cpu.bus_m_addr[5:0] != 6'h10
                && u_cpu.bus_m_addr[5:0] != 6'h14) begin
            $display("[%0t ns] MMIO READ  addr=%08x", $time, u_cpu.bus_m_addr);
            #10;
            $display("data=%08x ", u_cpu.bus_m_dat_o);
        end
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF
                && u_cpu.bus_m_addr[5:0] != 6'h10
                && u_cpu.bus_m_addr[5:0] != 6'h14) begin
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
        if (u_cpu.u_mmio.uart_valid)
            $write("%c", u_cpu.u_mmio.uart_data);
    end

    integer trace_fd;
    initial begin
        trace_fd = $fopen("build/nobranch2.trace", "w");
    end
    always @(posedge clk) begin
        if (rst_n && cycle_count > 20 && cycle_count < 200000) begin
            if (u_cpu.ex_branch_flag || u_cpu.ex_jump_flag || u_cpu.mem_dmem_we || u_cpu.wb_regs_we) begin
                $fwrite(trace_fd, "%0d EX pc=%08x br=%0b j=%0b pred=%0b pt=%08x act=%0b at=%08x mis=%0b MEMwe=%0b ma=%08x md=%08x WBwe=%0b wa=%0d wd=%08x\n", cycle_count, u_cpu.ex_instr_addr, u_cpu.ex_branch_flag, u_cpu.ex_jump_flag, u_cpu.ex_pred_taken, u_cpu.ex_pred_target, u_cpu.ex_actual_jump_flag, u_cpu.ex_actual_jump_addr, u_cpu.ex_mispredict, u_cpu.mem_dmem_we, u_cpu.mem_dmem_wr_addr, u_cpu.mem_dmem_w_data, u_cpu.wb_regs_we, u_cpu.wb_regs_w_addr, u_cpu.wb_actual_regs_w_data);
            end
        end
        if (cycle_count == 200000) begin
            $fclose(trace_fd);
            $finish;
        end
    end

    always @(posedge clk) begin
        if (u_cpu.u_mmio.tohost) begin
            cycle_win          = stat_cycle_total - cycle_snap;
            instr_win          = instr_total          - instr_snap;
            flush_win          = flush_total          - flush_snap;
            load_stall_win     = load_stall_total     - load_stall_snap;
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
            branch_hit_win       = branch_hit_total       - branch_hit_snap;
            slot1_redirect_win = slot1_redirect_total - slot1_redirect_snap;

            if (BP_STATS_ENABLE) begin
                $display("");
                print_bp_stats(stat_cycle_total,
                               cycle_win,
                               instr_total,
                               flush_total, load_stall_total, mul_hold_total, other_bubble_total,
                               branch_total, branch_taken_total, branch_both_taken_total,
                               jal_total, jal_pred_total, jal_correct_total,
                               jalr_total, jalr_pred_total, jalr_correct_total,
                               ret_total, ret_pred_total, ret_correct_total,
                               call_jalr_total, call_jalr_pred_total, call_jalr_correct_total,
                               indirect_jalr_total, indirect_jalr_pred_total, indirect_jalr_correct_total,
                               pred_taken_total,
                               dir_correct_total, target_correct_total, mispredict_total,
                               branch_hit_total, slot1_redirect_total, wb_commit_total,
                               instr_win,
                               flush_win, load_stall_win, mul_hold_win, other_bubble_win,
                               branch_win, branch_taken_win, branch_both_taken_win,
                               jal_win, jal_pred_win, jal_correct_win,
                               jalr_win, jalr_pred_win, jalr_correct_win,
                               ret_win, ret_pred_win, ret_correct_win,
                               call_jalr_win, call_jalr_pred_win, call_jalr_correct_win,
                               indirect_jalr_win, indirect_jalr_pred_win, indirect_jalr_correct_win,
                               pred_taken_win,
                               dir_correct_win, target_correct_win, mispredict_win,
                               branch_hit_win, slot1_redirect_win, wb_commit_win);
                print_jalr_pc_stats();
                $display("[STAT][%0d cyc] JALR dep total: prev_wr_rs1=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         jalr_prev_wr_rs1_total,
                         pct_x100(jalr_prev_wr_rs1_total, jalr_total) / 100,
                         pct_x100(jalr_prev_wr_rs1_total, jalr_total) % 100,
                         ret_prev_wr_rs1_total,
                         call_jalr_prev_wr_rs1_total,
                         indirect_jalr_prev_wr_rs1_total);
                $display("[STAT][%0d cyc] JALR dep win  : prev_wr_rs1=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         jalr_prev_wr_rs1_win,
                         pct_x100(jalr_prev_wr_rs1_win, jalr_win) / 100,
                         pct_x100(jalr_prev_wr_rs1_win, jalr_win) % 100,
                         ret_prev_wr_rs1_win,
                         call_jalr_prev_wr_rs1_win,
                         indirect_jalr_prev_wr_rs1_win);
                $display("[STAT][%0d cyc] AUIPC+JALR total: pair=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         auipc_jalr_total,
                         pct_x100(auipc_jalr_total, jalr_total) / 100,
                         pct_x100(auipc_jalr_total, jalr_total) % 100,
                         auipc_ret_total,
                         auipc_call_jalr_total,
                         auipc_indirect_jalr_total);
                $display("[STAT][%0d cyc] AUIPC+JALR win  : pair=%0d(%0d.%02d%%)  |  ret=%0d  call=%0d  other=%0d",
                         stat_cycle_total,
                         auipc_jalr_win,
                         pct_x100(auipc_jalr_win, jalr_win) / 100,
                         pct_x100(auipc_jalr_win, jalr_win) % 100,
                         auipc_ret_win,
                         auipc_call_jalr_win,
                         auipc_indirect_jalr_win);
            end
            $display("LED = %04X", u_cpu.u_mmio.led);
            if (u_cpu.u_mmio.led == 16'h0000)
                $display(">>> PASSED <<<");
            else
                $display(">>> FAILED at sub-test %0d <<<", u_cpu.u_mmio.led);
            $finish;
        end
    end

endmodule



