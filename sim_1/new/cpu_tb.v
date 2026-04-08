`timescale 1ns / 1ps

module cpu_tb;

    localparam BP_STATS_ENABLE = 1'b1;
    localparam PERIODIC_STATS_ENABLE = 1'b0;
    localparam [31:0] MMIO_TIMER_LO_ADDR = 32'hF0000000;
    localparam [31:0] MMIO_TIMER_HI_ADDR = 32'hF0000004;

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
    integer pred_taken_total;
    integer dir_correct_total;
    integer target_correct_total;
    integer mispredict_total;
    integer btb_hit0_total;
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
    integer pred_taken_snap;
    integer dir_correct_snap;
    integer target_correct_snap;
    integer mispredict_snap;
    integer btb_hit0_snap;
    integer slot1_redirect_snap;

    integer instr_now;
    integer flush_now;
    integer load_stall_now;
    integer mul_hold_now;
    integer other_bubble_now;
    integer wb_commit_now;
    integer branch_now;
    integer branch_taken_now;
    integer pred_taken_now;
    integer dir_correct_now;
    integer target_correct_now;
    integer mispredict_now;
    integer btb_hit0_now;
    integer slot1_redirect_now;

    integer cycle_win;
    integer stat_cycle_win;

    integer instr_win;
    integer flush_win;
    integer load_stall_win;
    integer mul_hold_win;
    integer other_bubble_win;
    integer wb_commit_win;
    integer branch_win;
    integer branch_taken_win;
    integer pred_taken_win;
    integer dir_correct_win;
    integer target_correct_win;
    integer mispredict_win;
    integer btb_hit0_win;
    integer slot1_redirect_win;

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
        input integer total_pred_taken;
        input integer total_dir_correct;
        input integer total_target_correct;
        input integer total_mispredict;
        input integer total_btb_hit;
        input integer total_slot1_redirect;
        input integer total_wb_commit;
        input integer win_instr;
        input integer win_flush;
        input integer win_load_stall;
        input integer win_mul_hold;
        input integer win_other_bubble;
        input integer win_branch;
        input integer win_branch_taken;
        input integer win_pred_taken;
        input integer win_dir_correct;
        input integer win_target_correct;
        input integer win_mispredict;
        input integer win_btb_hit;
        input integer win_slot1_redirect;
        input integer win_wb_commit;
        integer total_dir_acc_x100;
        integer total_taken_prec_x100;
        integer total_taken_recall_x100;
        integer total_ipc_x1000;
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
        integer win_ipc_x1000;
        begin
            total_dir_acc_x100      = pct_x100(total_dir_correct, total_branch);
            total_taken_prec_x100   = pct_x100(total_target_correct, total_pred_taken);
            total_taken_recall_x100 = pct_x100(total_target_correct, total_branch_taken);
            total_ipc_x1000         = (show_cycle != 0) ? ((total_instr * 1000 + (show_cycle / 2)) / show_cycle) : 0;
            total_loss              = show_cycle - total_instr;
            total_loss_pct_x100     = pct_x100(total_loss, show_cycle);
            total_flush_share_x100      = pct_x100(total_flush, total_loss);
            total_load_stall_share_x100 = pct_x100(total_load_stall, total_loss);
            total_mul_hold_share_x100   = pct_x100(total_mul_hold, total_loss);
            total_other_bubble_share_x100 = pct_x100(total_other_bubble, total_loss);
            win_dir_acc_x100        = pct_x100(win_dir_correct, win_branch);
            win_taken_prec_x100     = pct_x100(win_target_correct, win_pred_taken);
            win_taken_recall_x100   = pct_x100(win_target_correct, win_branch_taken);
            win_ipc_x1000           = (win_cycle != 0) ? ((win_instr * 1000 + (win_cycle / 2)) / win_cycle) : 0;
            win_loss                = win_cycle - win_instr;
            win_loss_pct_x100       = pct_x100(win_loss, win_cycle);
            win_flush_share_x100      = pct_x100(win_flush, win_loss);
            win_load_stall_share_x100 = pct_x100(win_load_stall, win_loss);
            win_mul_hold_share_x100   = pct_x100(win_mul_hold, win_loss);
            win_other_bubble_share_x100 = pct_x100(win_other_bubble, win_loss);

            $display("");
            $display("[STAT][%0d cyc] IPC total=%0d.%03d  win=%0d.%03d  |  BP dir=%0d.%02d%%  prec=%0d.%02d%%  recall=%0d.%02d%%",
                     show_cycle,
                     total_ipc_x1000 / 1000, total_ipc_x1000 % 1000,
                     win_ipc_x1000 / 1000, win_ipc_x1000 % 1000,
                     total_dir_acc_x100 / 100, total_dir_acc_x100 % 100,
                     total_taken_prec_x100 / 100, total_taken_prec_x100 % 100,
                     total_taken_recall_x100 / 100, total_taken_recall_x100 % 100);
            $display("[STAT][%0d cyc] CNT  total: instr=%0d wb=%0d br=%0d taken=%0d predT=%0d mis=%0d btb=%0d s1=%0d  |  win: instr=%0d wb=%0d br=%0d mis=%0d",
                     show_cycle,
                     total_instr, total_wb_commit,
                     total_branch, total_branch_taken, total_pred_taken, total_mispredict,
                     total_btb_hit, total_slot1_redirect,
                     win_instr, win_wb_commit, win_branch, win_mispredict);
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
        pred_taken_total = 0;
        dir_correct_total = 0;
        target_correct_total = 0;
        mispredict_total = 0;
        btb_hit0_total = 0;
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
        pred_taken_snap = 0;
        dir_correct_snap = 0;
        target_correct_snap = 0;
        mispredict_snap = 0;
        btb_hit0_snap = 0;
        slot1_redirect_snap = 0;

        #100;
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 0;
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
            btb_hit0_now       = btb_hit0_total       + ((stat_cycle_win && u_cpu.preif_btb_hit) ? 1 : 0);
            slot1_redirect_now = slot1_redirect_total + ((stat_cycle_win && u_cpu.slot1_pred_redirect) ? 1 : 0);

            branch_now         = branch_total;
            branch_taken_now   = branch_taken_total;
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

                if (u_cpu.ex_pred_taken && u_cpu.ex_actual_jump_flag
                        && (u_cpu.ex_pred_target == u_cpu.ex_actual_jump_addr))
                    target_correct_now = target_correct_now + 1;

                if (u_cpu.ex_mispredict)
                    mispredict_now = mispredict_now + 1;
            end

            stat_cycle_total     <= stat_cycle_total + stat_cycle_win;
            instr_total          <= instr_now;
            flush_total          <= flush_now;
            load_stall_total     <= load_stall_now;
            mul_hold_total       <= mul_hold_now;
            other_bubble_total   <= other_bubble_now;
            wb_commit_total      <= wb_commit_now;
            btb_hit0_total       <= btb_hit0_now;
            slot1_redirect_total <= slot1_redirect_now;
            branch_total         <= branch_now;
            branch_taken_total   <= branch_taken_now;
            pred_taken_total     <= pred_taken_now;
            dir_correct_total    <= dir_correct_now;
            target_correct_total <= target_correct_now;
            mispredict_total     <= mispredict_now;

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
                pred_taken_win     = pred_taken_now     - pred_taken_snap;
                dir_correct_win    = dir_correct_now    - dir_correct_snap;
                target_correct_win = target_correct_now - target_correct_snap;
                mispredict_win     = mispredict_now     - mispredict_snap;
                btb_hit0_win       = btb_hit0_now       - btb_hit0_snap;
                slot1_redirect_win = slot1_redirect_now - slot1_redirect_snap;

                print_bp_stats(stat_cycle_total,
                               cycle_win,
                               instr_now,
                               flush_now, load_stall_now, mul_hold_now, other_bubble_now,
                               branch_now, branch_taken_now, pred_taken_now,
                               dir_correct_now, target_correct_now, mispredict_now,
                               btb_hit0_now, slot1_redirect_now, wb_commit_now,
                               instr_win,
                               flush_win, load_stall_win, mul_hold_win, other_bubble_win,
                               branch_win, branch_taken_win, pred_taken_win,
                               dir_correct_win, target_correct_win, mispredict_win,
                               btb_hit0_win, slot1_redirect_win, wb_commit_win);

                cycle_snap          <= stat_cycle_total;
                instr_snap          <= instr_now;
                flush_snap          <= flush_now;
                load_stall_snap     <= load_stall_now;
                mul_hold_snap       <= mul_hold_now;
                other_bubble_snap   <= other_bubble_now;
                wb_commit_snap      <= wb_commit_now;
                branch_snap         <= branch_now;
                branch_taken_snap   <= branch_taken_now;
                pred_taken_snap     <= pred_taken_now;
                dir_correct_snap    <= dir_correct_now;
                target_correct_snap <= target_correct_now;
                mispredict_snap     <= mispredict_now;
                btb_hit0_snap       <= btb_hit0_now;
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
            pred_taken_win     = pred_taken_total     - pred_taken_snap;
            dir_correct_win    = dir_correct_total    - dir_correct_snap;
            target_correct_win = target_correct_total - target_correct_snap;
            mispredict_win     = mispredict_total     - mispredict_snap;
            btb_hit0_win       = btb_hit0_total       - btb_hit0_snap;
            slot1_redirect_win = slot1_redirect_total - slot1_redirect_snap;

            if (BP_STATS_ENABLE) begin
                $display("");
                print_bp_stats(stat_cycle_total,
                               cycle_win,
                               instr_total,
                               flush_total, load_stall_total, mul_hold_total, other_bubble_total,
                               branch_total, branch_taken_total, pred_taken_total,
                               dir_correct_total, target_correct_total, mispredict_total,
                               btb_hit0_total, slot1_redirect_total, wb_commit_total,
                               instr_win,
                               flush_win, load_stall_win, mul_hold_win, other_bubble_win,
                               branch_win, branch_taken_win, pred_taken_win,
                               dir_correct_win, target_correct_win, mispredict_win,
                               btb_hit0_win, slot1_redirect_win, wb_commit_win);
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
