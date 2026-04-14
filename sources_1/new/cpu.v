`timescale 1ns / 1ps

module cpu(
    input  wire        clk,
    input  wire        rst_n,
    output wire [15:0] led,
    output wire        uart_tx
);

`ifdef SYNTHESIS
    localparam integer UART_BAUD_RATE = 115_200;
`else
    localparam integer UART_BAUD_RATE = 3_000_000;
`endif
    localparam integer BR_PRED_ENTRY_NUM  = 16;
    localparam integer BR_PRED_INDEX_BITS = 4;

    // ------------------------------------------------------------------------
    // Global control
    // ------------------------------------------------------------------------
    wire        pipeline_stall;
    wire        pipeline_flush;
    wire        ex_mul_busy;
    wire        pipeline_hold         = ex_mul_busy;
    wire        pipeline_block        = pipeline_stall | pipeline_hold;

    // ------------------------------------------------------------------------
    // PREIF
    // ------------------------------------------------------------------------
    wire        preif_valid;
    wire [31:0] preif_pc_addr;

    wire        preif_jtb_hit;
    wire [31:0] preif_jtb_target;
    wire        preif_next_jtb_hit;
    wire [31:0] preif_next_jtb_target;

    wire        slot0_jump_redirect;
    wire        slot0_jump_redirect_raw;
    wire        slot0_jal_redirect;
    wire        slot0_jalr_redirect;
    wire        slot0_branch_redirect;
    wire        slot0_ctrl_redirect;
    wire        slot0_ctrl_redirect_raw;
    wire        slot1_pred_redirect;
    wire        slot1_pred_redirect_raw;
    wire        frontend_redirect_flag;
    wire [31:0] frontend_redirect_addr;

    // ------------------------------------------------------------------------
    // IF
    // ------------------------------------------------------------------------
    wire [31:0] if_instr;
    wire [31:0] if_instr_addr;
    wire [31:0] if_pred_instr      = if_instr;
    wire [31:0] if_pred_instr_addr = if_instr_addr;
    wire [31:0] if_pre_instr;
    wire [31:0] if_pre_instr_addr;
    wire        if_pre_valid;
    wire        if_pre_valid_imem;
    reg         if_pre_valid_q;
    reg         frontend_redirect_kill_q;

    reg         if_jtb_hit;
    reg  [31:0] if_jtb_target;
    reg         if_pre_jtb_hit;
    reg  [31:0] if_pre_jtb_target;

    wire        if_is_b;
    wire        if_is_jal;
    wire        if_is_jalr;
    wire        if_is_call;
    wire        if_is_ret;
    wire [10:1] if_b_imm_lo;
    wire [31:0] if_jalr_pred_target;
    wire        if_jalr_pred_hit;
    wire [31:0] if_b_imm;
    wire [31:0] if_b_target;
    wire [31:0] if_b_target_canon;
    wire [31:0] if_jal_target;
    wire [31:0] if_jal_target_canon;
    wire [31:0] if_jtb_target_canon;
    wire [BR_PRED_INDEX_BITS-1:0] if_branch_hash;
    wire        if_branch_pred_taken;
    wire        if_branch_hit;
    wire        preif_btb_hit;
    wire        if_pred_taken_eff;
    wire [31:0] if_pred_target_eff;

    wire        if_pre_is_jal;
    wire        if_pre_is_jalr;
    wire        if_pre_is_call;
    wire        if_pre_is_ret;
    wire [31:0] if_pre_jal_target;
    wire [31:0] if_pre_jal_target_canon;
    wire        if_pre_jalr_pred_hit;
    wire [31:0] if_pre_jalr_pred_target;
    wire [31:0] if_pre_jtb_target_canon;
    wire        if_pre_pred_taken_eff;
    wire [31:0] if_pre_pred_target_eff;
    wire        id_use_if_now;
    wire        id_use_if_recovery_now;

    wire        imem_bus_re;
    wire        if_pre_capture_en;

    // ------------------------------------------------------------------------
    // ID
    // ------------------------------------------------------------------------
    wire [31:0] id_instr_reg;
    wire [31:0] id_instr_addr_reg;
    wire        id_pred_taken_reg;
    wire [31:0] id_pred_target_reg;

    wire [31:0] id_instr;
    wire [31:0] id_instr_addr;
    wire        id_pred_taken;
    wire [31:0] id_pred_target;

    wire        id_regs_re;
    wire        id_regs_we;
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire [4:0]  id_regs_w_addr;
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_rs1_data_fwd;
    wire [31:0] id_rs2_data_fwd;

    wire [3:0]  id_alu_op;
    wire [31:0] id_alu_num1;
    wire [31:0] id_alu_num2;

    wire [2:0]  id_mem_op;
    wire        id_dmem_we;
    wire        id_dmem_re;
    wire [31:0] id_dmem_w_data;

    wire        id_branch_flag;
    wire        id_jump_flag;
    wire        id_jalr_flag;
    wire        id_call_flag;
    wire        id_ret_flag;
    wire [10:1] id_b_imm_lo;
    wire [BR_PRED_INDEX_BITS-1:0] id_branch_hash;
    wire [31:0] id_branch_jump_addr;

    wire [31:0] if_instr_fwd         = if_instr;

    // ------------------------------------------------------------------------
    // EX
    // ------------------------------------------------------------------------
    wire [31:0] ex_instr_addr;
    wire [BR_PRED_INDEX_BITS-1:0] ex_branch_hash;
    wire        ex_pred_taken;
    wire [31:0] ex_pred_target;

    wire [31:0] ex_alu_num1;
    wire [31:0] ex_alu_num2;
    wire [3:0]  ex_alu_op;

    wire        ex_regs_we;
    wire [4:0]  ex_regs_w_addr;
    wire [31:0] ex_regs_w_data;

    wire        ex_dmem_we;
    wire        ex_dmem_re;
    wire [31:0] ex_dmem_w_data;
    wire [31:0] ex_dmem_wr_addr;
    wire [2:0]  ex_mem_op;

    wire        ex_branch_flag;
    wire        ex_jump_flag;
    wire        ex_jalr_flag;
    wire        ex_call_flag;
    wire        ex_ret_flag;
    wire [31:0] ex_branch_jump_addr;

    wire        ex_actual_jump_flag;
    wire [31:0] ex_actual_jump_addr;
    wire        ex_mispredict;
    wire [31:0] ex_redirect_addr;

    // ------------------------------------------------------------------------
    // MEM
    // ------------------------------------------------------------------------
    wire        mem_regs_we;
    wire [4:0]  mem_regs_w_addr;
    wire [31:0] mem_regs_w_data;
    wire [31:0] mem_actual_regs_w_data;

    wire        mem_dmem_we;
    wire        mem_dmem_re;
    wire [31:0] mem_dmem_wr_addr;
    wire [31:0] mem_dmem_w_data;
    wire [31:0] mem_dmem_r_data;
    wire [2:0]  mem_mem_op;

    wire        bus_m_stb;
    wire        bus_m_ack;
    wire        bus_m_we;
    wire [31:0] bus_m_addr;
    wire [31:0] bus_m_dat_i;
    wire [31:0] bus_m_dat_o;

    wire        bus_s0_stb;
    wire        bus_s0_ack;
    wire        bus_s0_we;
    wire [31:0] bus_s0_addr;
    wire [31:0] bus_s0_dat_i;
    wire [31:0] bus_s0_dat_o;

    wire        bus_s1_stb;
    wire        bus_s1_ack;
    wire        bus_s1_we;
    wire [31:0] bus_s1_addr;
    wire [31:0] bus_s1_dat_i;
    wire [31:0] bus_s1_dat_o;

    wire        bus_s2_stb;
    wire        bus_s2_ack;
    wire        bus_s2_we;
    wire [31:0] bus_s2_addr;
    wire [31:0] bus_s2_dat_i;
    wire [31:0] bus_s2_dat_o;

    wire        uart_valid;
    wire [7:0]  uart_data;
    wire        tohost;
    wire        uart_line;
    wire        uart_busy;
    wire        uart_ready;
    wire        uart_overflow;

    // ------------------------------------------------------------------------
    // RAS
    // ------------------------------------------------------------------------
    localparam integer RAS_DEPTH = 8;
    localparam integer RAS_PTR_W = 3;
    reg  [31:0] ras_stack [0:RAS_DEPTH-1];
    reg  [RAS_PTR_W-1:0] ras_sp;
    reg  [RAS_PTR_W:0]   ras_count;
    wire                 ras_valid;
    wire [RAS_PTR_W-1:0] ras_top_idx;
    wire [31:0]          ras_top_target;
    wire                 ras_slot1_valid_shadow;
    wire [RAS_PTR_W-1:0] ras_slot1_top_idx_shadow;
    wire [31:0]          ras_slot1_top_target_shadow;
    wire                 frontend_issue_ok;
    wire                 slot0_jump_pred_base;
    wire                 slot0_ctrl_pred_base;
    wire                 slot1_pred_base;

    // ------------------------------------------------------------------------
    // WB
    // ------------------------------------------------------------------------
    wire        wb_regs_we;
    wire        wb_dmem_re;
    wire [4:0]  wb_regs_w_addr;
    wire [31:0] wb_actual_regs_w_data;

    // ------------------------------------------------------------------------
    // Timing helper / fanout split signals
    // ------------------------------------------------------------------------
    assign ras_valid            = (ras_count != 0);
    assign ras_top_idx          = ras_sp - 1'b1;
    assign ras_top_target       = ras_stack[ras_top_idx];
    assign ras_slot1_valid_shadow = slot0_jump_redirect && if_is_ret
                                  ? (ras_count > 1)
                                  : (slot0_jump_redirect && if_is_call)
                                  ? 1'b1
                                  : ras_valid;
    assign ras_slot1_top_idx_shadow = slot0_jump_redirect && if_is_ret
                                    ? (ras_sp - 2'd2)
                                    : ras_top_idx;
    assign ras_slot1_top_target_shadow = (slot0_jump_redirect && if_is_call)
                                       ? (if_pred_instr_addr + 32'd4)
                                       : ras_stack[ras_slot1_top_idx_shadow];

    assign if_is_b               = (if_pred_instr[6:2] == 5'b11000);
    assign if_is_jal             = (if_pred_instr[6:2] == 5'b11011);
    assign if_is_jalr            = (if_pred_instr[6:2] == 5'b11001);
    assign if_is_call            = (if_is_jal || if_is_jalr)
                                 && ((if_pred_instr[11:7] == 5'd1) || (if_pred_instr[11:7] == 5'd5));
    assign if_is_ret             = if_is_jalr
                                 && (if_pred_instr[11:7] == 5'd0)
                                 && ((if_pred_instr[19:15] == 5'd1) || (if_pred_instr[19:15] == 5'd5))
                                 && (if_pred_instr[31:20] == 12'b0);
    assign if_b_imm_lo           = {if_pred_instr[7], if_pred_instr[30:25], if_pred_instr[11:8]};
    assign if_b_imm              = {{20{if_pred_instr[31]}}, if_b_imm_lo, 1'b0};
    assign if_b_target           = if_pred_instr_addr + if_b_imm;
    assign if_b_target_canon     = {17'b0, if_b_target[14:0]};
    assign if_branch_hash        = if_b_imm_lo[BR_PRED_INDEX_BITS+1:2];
    assign if_jal_target         = if_pred_instr_addr + {{12{if_pred_instr[31]}}, if_pred_instr[19:12], if_pred_instr[20], if_pred_instr[30:21], 1'b0};
    assign if_jal_target_canon   = {17'b0, if_jal_target[14:0]};
    assign if_jtb_target_canon   = {17'b0, if_jtb_target[14:0]};
    assign if_jalr_pred_hit      = if_is_ret ? ras_valid : if_jtb_hit;
    assign if_jalr_pred_target   = if_is_ret ? ras_top_target : if_jtb_target_canon;
    assign if_pred_taken_eff     = if_is_jal ? slot0_jump_redirect
                                  : (if_is_jalr ? slot0_jump_redirect
                                  : (if_is_b ? slot0_branch_redirect : 1'b0));
    assign if_pred_target_eff    = if_is_jal ? if_jal_target_canon
                                  : (if_is_jalr ? if_jalr_pred_target
                                  : (if_is_b ? if_b_target_canon : 32'b0));

    assign if_pre_is_jal         = (if_pre_instr[6:2] == 5'b11011);
    assign if_pre_is_jalr        = (if_pre_instr[6:2] == 5'b11001);
    assign if_pre_is_call        = if_pre_is_jalr
                                 && ((if_pre_instr[11:7] == 5'd1) || (if_pre_instr[11:7] == 5'd5));
    assign if_pre_is_ret         = if_pre_is_jalr
                                 && (if_pre_instr[11:7] == 5'd0)
                                 && ((if_pre_instr[19:15] == 5'd1) || (if_pre_instr[19:15] == 5'd5))
                                 && (if_pre_instr[31:20] == 12'b0);
    assign if_pre_jal_target     = if_pre_instr_addr + {{12{if_pre_instr[31]}}, if_pre_instr[19:12], if_pre_instr[20], if_pre_instr[30:21], 1'b0};
    assign if_pre_jal_target_canon = {17'b0, if_pre_jal_target[14:0]};
    assign if_pre_jtb_target_canon = {17'b0, if_pre_jtb_target[14:0]};
    assign if_pre_jalr_pred_hit  = if_pre_is_ret ? ras_slot1_valid_shadow
                                  : (if_pre_is_call ? if_pre_jtb_hit : 1'b0);
    assign if_pre_jalr_pred_target = if_pre_is_ret ? ras_slot1_top_target_shadow
                                     : if_pre_jtb_target_canon;
    assign if_pre_pred_taken_eff = if_pre_is_jal ? 1'b1
                                  : (if_pre_is_jalr ? if_pre_jalr_pred_hit : 1'b0);
    assign if_pre_pred_target_eff= if_pre_is_jal ? if_pre_jal_target_canon
                                  : (if_pre_is_jalr ? if_pre_jalr_pred_target : 32'b0);

    assign frontend_issue_ok     = !pipeline_block_if && !frontend_redirect_kill_q;
    assign slot0_jump_pred_base  = if_is_jal || (if_is_jalr && if_jalr_pred_hit);
    assign slot0_ctrl_pred_base  = slot0_jump_pred_base || (if_is_b && if_branch_pred_taken);
    assign slot1_pred_base       = if_pre_valid && if_pre_pred_taken_eff;
    assign slot0_jal_redirect    = frontend_issue_ok && if_is_jal;
    assign slot0_jalr_redirect   = frontend_issue_ok && if_is_jalr && if_jalr_pred_hit;
    assign slot0_branch_redirect = frontend_issue_ok && if_is_b && if_branch_pred_taken;
    assign slot0_jump_redirect_raw = slot0_jump_pred_base;
    assign slot0_ctrl_redirect_raw = slot0_ctrl_pred_base;
    assign slot1_pred_redirect_raw = slot1_pred_base;
    assign slot0_jump_redirect   = frontend_issue_ok && slot0_jump_pred_base;
    assign slot0_ctrl_redirect   = frontend_issue_ok && slot0_ctrl_pred_base;
    assign slot1_pred_redirect   = frontend_issue_ok && slot1_pred_base;
    assign frontend_redirect_flag = ex_mispredict | slot0_ctrl_redirect | slot1_pred_redirect;
    assign frontend_redirect_addr = ex_mispredict    ? ex_redirect_addr
                                  : slot0_ctrl_redirect ? if_pred_target_eff
                                  : if_pre_pred_target_eff;
    assign if_pre_valid          = if_pre_valid_q;
    assign id_use_if_recovery_now = preif_valid && !frontend_redirect_kill_q;
    assign id_use_if_now         = if_pre_valid || id_use_if_recovery_now;
    assign id_b_imm_lo           = {id_instr[7], id_instr[30:25], id_instr[11:8]};
    assign id_branch_hash        = id_b_imm_lo[BR_PRED_INDEX_BITS+1:2];
    assign imem_bus_re           = bus_s0_stb && !bus_s0_we;
    assign if_pre_capture_en     = preif_valid && !imem_bus_re;
    assign mem_actual_regs_w_data = mem_dmem_re ? mem_dmem_r_data : mem_regs_w_data;
    assign preif_btb_hit         = if_branch_hit;

    wire        pipeline_hold_if          = pipeline_hold;
    wire        pipeline_hold_id          = pipeline_hold;
    wire        pipeline_hold_exm         = pipeline_hold;
    wire        pipeline_block_pc         = pipeline_block;
    wire        pipeline_block_imem       = pipeline_block;
    wire        pipeline_block_if         = pipeline_block;
    wire        pipeline_flush_if         = pipeline_flush;
    wire        slot1_pred_redirect_if    = slot1_pred_redirect;
    wire        frontend_redirect_flag_pc = frontend_redirect_flag;
    wire [31:0] frontend_redirect_addr_pc = frontend_redirect_addr;
    wire        pipeline_flush_imem       = pipeline_flush;
    wire        pipeline_flush_if_id      = pipeline_flush;
    wire        pipeline_flush_id_ex      = pipeline_flush;
    branch_predictor #(
        .ENTRY_NUM  (BR_PRED_ENTRY_NUM ),
        .INDEX_BITS (BR_PRED_INDEX_BITS)
    ) u_branch_predictor (
        .clk         (clk               ),
        .rst_n       (rst_n             ),
        .lookup_is_branch0(if_is_b          ),
        .lookup_pc0  (if_pred_instr_addr    ),
        .lookup_hash0(if_branch_hash        ),
        .pred_taken0 (if_branch_pred_taken  ),
        .branch_hit0 (if_branch_hit         ),
        .update_en   (ex_branch_flag        ),
        .update_pc   (ex_instr_addr         ),
        .update_hash (ex_branch_hash        ),
        .update_taken(ex_actual_jump_flag   )
    );

    jump_target_buffer #(
        .ENTRY_NUM  (8),
        .INDEX_BITS (3)
    ) u_jump_target_buffer (
        .clk         (clk               ),
        .rst_n       (rst_n             ),
        .lookup_pc0  (preif_pc_addr     ),
        .hit0        (preif_jtb_hit     ),
        .target0     (preif_jtb_target  ),
        .lookup_pc1  (preif_pc_addr + 32'd4),
        .hit1        (preif_next_jtb_hit   ),
        .target1     (preif_next_jtb_target),
        .update_en   (ex_jalr_flag && !ex_ret_flag),
        .update_pc   (ex_instr_addr     ),
        .update_target({17'b0, ex_actual_jump_addr[14:0]})
    );

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            ras_sp    <= {RAS_PTR_W{1'b0}};
            ras_count <= {(RAS_PTR_W+1){1'b0}};
        end else if (ex_jump_flag) begin
            if (ex_ret_flag) begin
                if (ras_count != 0) begin
                    ras_sp    <= ras_sp - 1'b1;
                    ras_count <= ras_count - 1'b1;
                end
            end else if (ex_call_flag) begin
                ras_stack[ras_sp] <= ex_instr_addr + 32'd4;
                ras_sp            <= ras_sp + 1'b1;
                if (ras_count != RAS_DEPTH)
                    ras_count <= ras_count + 1'b1;
            end
        end
    end

    //PREIF
    pc u_pc(
        .clk            (clk                  ),
        .rst_n          (rst_n                ),
        .redirect_flag  (frontend_redirect_flag_pc),
        .redirect_addr  (frontend_redirect_addr_pc),
        .preif_ready    (!imem_bus_re         ),
        .pipeline_stall (pipeline_block_pc    ),
        .pc_o           (preif_pc_addr        ),
        .preif_valid_o  (preif_valid          )
    );

    imem u_imem(
        .clk                (clk               ),
        .rst_n              (rst_n             ),
        .pipeline_stall     (pipeline_block_imem),
        .pipeline_flush     (pipeline_flush_imem),
        .preif_pc_addr_i    (preif_pc_addr     ),
        .if_instr_o         (if_instr          ),
        .if_instr_addr_o    (if_instr_addr     ),
        .preif_valid_i      (preif_valid       ),
        .if_pre_instr_o     (if_pre_instr      ),
        .if_pre_instr_addr_o(if_pre_instr_addr ),
        .if_pre_valid_o     (if_pre_valid_imem ),
        
        .bus_stb            (bus_s0_stb        ),
        .bus_ack            (bus_s0_ack        ),
        .r_addr             (bus_s0_addr       ),
        .bus_we             (bus_s0_we         ),
        .mem_op             (ex_mem_op         ),
        .r_data             (bus_s0_dat_i      )
    );

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            frontend_redirect_kill_q <= 1'b0;
        end else if (pipeline_flush_if || slot0_ctrl_redirect || slot1_pred_redirect) begin
            frontend_redirect_kill_q <= 1'b1;
        end else if (!pipeline_block_if) begin
            frontend_redirect_kill_q <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            if_pre_valid_q    <= 1'b0;
            if_jtb_hit        <= 1'b0;
            if_jtb_target     <= 32'b0;
            if_pre_jtb_hit    <= 1'b0;
            if_pre_jtb_target <= 32'b0;
        end else if (slot0_ctrl_redirect || slot1_pred_redirect_if) begin
            if_pre_valid_q     <= 1'b0;
            if_jtb_hit         <= 1'b0;
            if_jtb_target      <= 32'b0;
            if_pre_jtb_hit     <= 1'b0;
            if_pre_jtb_target  <= 32'b0;
        end else if (pipeline_flush_if) begin
            if_pre_valid_q     <= 1'b0;
            if_jtb_hit         <= 1'b0;
            if_jtb_target      <= 32'b0;
            if_pre_jtb_hit     <= 1'b0;
            if_pre_jtb_target  <= 32'b0;
        end else if (!pipeline_block_if) begin
            if_pre_valid_q <= if_pre_capture_en;
            if_jtb_hit     <= preif_jtb_hit;
            if_jtb_target  <= preif_jtb_target;
            if_pre_jtb_hit <= preif_next_jtb_hit;
            if_pre_jtb_target <= preif_next_jtb_target;
        end
    end

    if_id u_if_id(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .pipeline_stall  (pipeline_stall  ),
        .pipeline_hold   (pipeline_hold_if),
        .pipeline_flush  (pipeline_flush_if_id),
        .frontend_kill   (frontend_redirect_kill_q),
        .slot0_drop_buf  (if_pre_valid && slot0_ctrl_redirect),
        .if_instr_i      (if_instr        ),
        .if_instr_addr_i (if_instr_addr   ),
        .if_pred_taken_i (if_pred_taken_eff),
        .if_pred_target_i(if_pred_target_eff),
        .if_pre_instr_i  (if_pre_instr    ),
        .if_pre_instr_addr_i(if_pre_instr_addr),
        .if_pre_pred_taken_i (if_pre_pred_taken_eff),
        .if_pre_pred_target_i(if_pre_pred_target_eff),
        .if_pre_valid_i  (if_pre_valid    ),
        .id_instr_o      (id_instr_reg        ),
        .id_instr_addr_o (id_instr_addr_reg   ),
        .id_pred_taken_o (id_pred_taken_reg   ),
        .id_pred_target_o(id_pred_target_reg  )
    );

    //ID
    assign id_instr       = id_use_if_now ? if_instr_fwd        : id_instr_reg;
    assign id_instr_addr  = id_use_if_now ? if_instr_addr       : id_instr_addr_reg;
    assign id_pred_taken  = id_use_if_now ? if_pred_taken_eff   : id_pred_taken_reg;
    assign id_pred_target = id_use_if_now ? if_pred_target_eff  : id_pred_target_reg;

    id u_id(
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .id_instr_addr      (id_instr_addr      ),
        .id_instr           (id_instr           ),
        .id_regs_re         (id_regs_re         ),
        .id_rs1_addr        (id_rs1_addr        ),
        .id_rs2_addr        (id_rs2_addr        ),
        .id_rs1_data        (id_rs1_data_fwd    ),
        .id_rs2_data        (id_rs2_data_fwd    ),
        .id_rd_addr         (id_regs_w_addr     ),
        .id_regs_we         (id_regs_we         ),
        .id_alu_op          (id_alu_op          ),
        .id_alu_num1        (id_alu_num1        ),
        .id_alu_num2        (id_alu_num2        ),
        .id_mem_op          (id_mem_op          ),
        .id_dmem_we         (id_dmem_we         ),
        .id_dmem_re         (id_dmem_re         ),
        .id_dmem_w_data     (id_dmem_w_data     ),
        .id_branch_flag     (id_branch_flag     ),
        .id_branch_jump_addr(id_branch_jump_addr),
        .id_jump_flag       (id_jump_flag       ),
        .id_jalr_flag       (id_jalr_flag       ),
        .id_call_flag       (id_call_flag       ),
        .id_ret_flag        (id_ret_flag        )
    );
    
    //ID_EX
    id_ex u_id_ex(
        .clk                 (clk                 ),
        .rst_n               (rst_n               ),
        .pipeline_stall      (pipeline_stall      ),
        .pipeline_hold       (pipeline_hold_id    ),
        .pipeline_flush      (pipeline_flush_id_ex),

        .id_instr_addr       (id_instr_addr       ),
        .id_pred_taken       (id_pred_taken       ),
        .id_pred_target      (id_pred_target      ),
        .id_alu_num1         (id_alu_num1         ),
        .id_alu_num2         (id_alu_num2         ),
        .id_alu_op           (id_alu_op           ),
        .id_regs_w_addr      (id_regs_w_addr      ),
        .id_regs_we          (id_regs_we          ),
        .id_mem_op           (id_mem_op           ),
        .id_dmem_we          (id_dmem_we          ),
        .id_dmem_re          (id_dmem_re          ),
        .id_dmem_w_data      (id_dmem_w_data      ),
        .id_branch_flag      (id_branch_flag      ),
        .id_branch_jump_addr (id_branch_jump_addr ),
        .id_branch_hash      (id_branch_hash      ),
        .id_jump_flag        (id_jump_flag        ),
        .id_jalr_flag        (id_jalr_flag        ),
        .id_call_flag        (id_call_flag        ),
        .id_ret_flag         (id_ret_flag         ),

        .ex_instr_addr       (ex_instr_addr       ),
        .ex_pred_taken       (ex_pred_taken       ),
        .ex_pred_target      (ex_pred_target      ),
        .ex_alu_num1         (ex_alu_num1         ),
        .ex_alu_num2         (ex_alu_num2         ),
        .ex_alu_op           (ex_alu_op           ),
        .ex_regs_w_addr      (ex_regs_w_addr      ),
        .ex_regs_we          (ex_regs_we          ),
        .ex_mem_op           (ex_mem_op           ),
        .ex_dmem_we          (ex_dmem_we          ),
        .ex_dmem_re          (ex_dmem_re          ),
        .ex_dmem_w_data      (ex_dmem_w_data      ),
        .ex_branch_flag      (ex_branch_flag      ),
        .ex_branch_jump_addr (ex_branch_jump_addr ),
        .ex_branch_hash      (ex_branch_hash      ),
        .ex_jump_flag        (ex_jump_flag        ),
        .ex_jalr_flag        (ex_jalr_flag        ),
        .ex_call_flag        (ex_call_flag        ),
        .ex_ret_flag         (ex_ret_flag         )
    );
    

    //EX
    assign pipeline_flush = ex_mispredict;

    ex u_ex(
        .clk                   (clk                   ),
        .rst_n                 (rst_n                 ),
        .ex_instr_addr         (ex_instr_addr         ),
        .ex_pred_taken         (ex_pred_taken         ),
        .ex_pred_target        (ex_pred_target        ),
        .ex_alu_num1           (ex_alu_num1           ),
        .ex_alu_num2           (ex_alu_num2           ),
        .ex_alu_op             (ex_alu_op             ),
        .ex_mem_op             (ex_mem_op             ),
        .ex_branch_flag        (ex_branch_flag        ),
        .ex_branch_jump_addr   (ex_branch_jump_addr   ),
        .ex_jump_flag          (ex_jump_flag          ),
        .ex_regs_w_data        (ex_regs_w_data        ),
        .ex_dmem_wr_addr       (ex_dmem_wr_addr       ),
        .ex_actual_jump_flag   (ex_actual_jump_flag   ),
        .ex_actual_jump_addr   (ex_actual_jump_addr   ),
        .ex_mispredict         (ex_mispredict         ),
        .ex_redirect_addr      (ex_redirect_addr      ),
        .ex_mul_busy           (ex_mul_busy           )
    );
    
    //EX_MEM
    ex_mem u_ex_mem(
        .clk                    (clk                    ),
        .rst_n                  (rst_n                  ),
        .pipeline_hold          (pipeline_hold_exm      ),
        .ex_regs_we             (ex_regs_we             ),
        .ex_regs_w_addr         (ex_regs_w_addr         ),
        .ex_regs_w_data         (ex_regs_w_data         ),
        .ex_dmem_wr_addr        (ex_dmem_wr_addr        ),
        .ex_dmem_w_data         (ex_dmem_w_data         ),
        .ex_dmem_we             (ex_dmem_we             ),
        .ex_dmem_re             (ex_dmem_re             ),
        .ex_mem_op              (ex_mem_op              ),

        .mem_regs_we            (mem_regs_we            ),
        .mem_regs_w_addr        (mem_regs_w_addr        ),
        .mem_regs_w_data        (mem_regs_w_data        ),
        .mem_dmem_wr_addr       (mem_dmem_wr_addr       ),
        .mem_dmem_w_data        (mem_dmem_w_data        ),
        .mem_dmem_we            (mem_dmem_we            ),
        .mem_dmem_re            (mem_dmem_re            ),
        .mem_mem_op             (mem_mem_op             )
    );
    
    //MEM

    assign bus_m_stb = ex_dmem_we || ex_dmem_re;
    assign bus_m_we = ex_dmem_we;
    assign bus_m_dat_i = ex_dmem_w_data;
    assign bus_m_addr = ex_dmem_wr_addr;
    assign mem_dmem_r_data = bus_m_dat_o;

    bus_interconnect u_bus_interconnect(
        .clk          (clk          ),
        .rst_n        (rst_n        ),
        .bus_m_stb    (bus_m_stb    ),
        .bus_m_ack    (bus_m_ack    ),
        .bus_m_we     (bus_m_we     ),
        .bus_m_addr   (bus_m_addr   ),
        .bus_m_dat_i  (bus_m_dat_i  ),
        .bus_m_dat_o  (bus_m_dat_o  ),

        .bus_s0_stb   (bus_s0_stb   ),
        .bus_s0_ack   (bus_s0_ack   ),
        .bus_s0_we    (bus_s0_we    ),
        .bus_s0_addr  (bus_s0_addr  ),
        .bus_s0_dat_i (bus_s0_dat_i ),
        .bus_s0_dat_o (bus_s0_dat_o ),

        .bus_s1_stb   (bus_s1_stb   ),
        .bus_s1_ack   (bus_s1_ack   ),
        .bus_s1_we    (bus_s1_we    ),
        .bus_s1_addr  (bus_s1_addr  ),
        .bus_s1_dat_i (bus_s1_dat_i ),
        .bus_s1_dat_o (bus_s1_dat_o ),

        .bus_s2_stb   (bus_s2_stb   ),
        .bus_s2_ack   (bus_s2_ack   ),
        .bus_s2_we    (bus_s2_we    ),
        .bus_s2_addr  (bus_s2_addr  ),
        .bus_s2_dat_i (bus_s2_dat_i ),
        .bus_s2_dat_o (bus_s2_dat_o )
    );

    dmem u_dmem(
        .clk     (clk            ),
        .rst_n   (rst_n          ),
        .bus_stb (bus_s1_stb     ),
        .bus_ack (bus_s1_ack     ),
        .w_data  (bus_s1_dat_o   ),
        .wr_addr (bus_s1_addr    ),
        .bus_we  (bus_s1_we      ),
        .mem_op  (ex_mem_op      ),
        .r_data  (bus_s1_dat_i   )
    );

    mmio u_mmio(
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .bus_stb    (bus_s2_stb     ),
        .bus_ack    (bus_s2_ack     ),
        .bus_we     (bus_s2_we      ),
        .bus_addr   (bus_s2_addr    ),
        .w_data     (bus_s2_dat_o   ),
        .r_data     (bus_s2_dat_i   ),
        .led        (led            ),
        .uart_valid (uart_valid     ),
        .uart_data  (uart_data      ),
        .tohost     (tohost         ),
        .uart_busy  (uart_busy      ),
        .uart_ready (uart_ready     ),
        .uart_overflow (uart_overflow)
    );
    
    uart_tx #(
        .CLK_FREQ   (100_000_000),
        .BAUD_RATE  (UART_BAUD_RATE),
        .FIFO_DEPTH (4)
    ) u_uart_tx (
        .clk       (clk          ),
        .rst_n     (rst_n        ),
        .tx_valid  (uart_valid   ),
        .tx_data   (uart_data    ),
        .tx_busy   (uart_busy    ),
        .tx_ready  (uart_ready   ),
        .tx        (uart_line    ),
        .overflow  (uart_overflow)
    );

    assign uart_tx = uart_line;
    
    
    //WB
    mem_wb u_mem_wb(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .mem_dmem_re     (mem_dmem_re     ),
        .mem_regs_we     (mem_regs_we     ),
        .mem_regs_w_addr (mem_regs_w_addr ),
        .mem_regs_w_data (mem_actual_regs_w_data),
        .wb_dmem_re      (wb_dmem_re      ),
        .wb_regs_we      (wb_regs_we      ),
        .wb_regs_w_addr  (wb_regs_w_addr  ),
        .wb_regs_w_data  (wb_actual_regs_w_data)
    );
    
    //REGS
    regs u_regs(
        .clk      (clk                   ),
        .rst_n    (rst_n                 ),
        .re       (id_regs_re            ),
        .rs1_addr (id_rs1_addr           ),
        .rs2_addr (id_rs2_addr           ),
        .rs1_data (id_rs1_data           ),
        .rs2_data (id_rs2_data           ),
        .we       (wb_regs_we            ),
        .w_addr   (wb_regs_w_addr        ),
        .w_data   (wb_actual_regs_w_data )
    );

    //Forwarding Unit
    forwarding u_forwarding(
        .id_rs1_addr           (id_rs1_addr           ),
        .id_rs2_addr           (id_rs2_addr           ),
        .id_rs1_data           (id_rs1_data           ),
        .id_rs2_data           (id_rs2_data           ),

        .ex_regs_we            (ex_regs_we            ),
        .ex_regs_w_addr        (ex_regs_w_addr        ),
        .ex_regs_w_data        (ex_regs_w_data        ),

        .mem_regs_we           (mem_regs_we           ),
        .mem_regs_w_addr       (mem_regs_w_addr       ),
        .mem_regs_w_data       (mem_actual_regs_w_data),

        .wb_regs_we            (wb_regs_we            ),
        .wb_regs_w_addr        (wb_regs_w_addr        ),
        .wb_actual_regs_w_data (wb_actual_regs_w_data ),
        
        .id_rs1_data_fwd       (id_rs1_data_fwd       ),
        .id_rs2_data_fwd       (id_rs2_data_fwd       )
    );
    
    //Pipeline Stall
    pipeline_stall u_pipeline_stall(
        .id_rs1_addr     (id_rs1_addr     ),
        .id_rs2_addr     (id_rs2_addr     ),
        .ex_dmem_re      (ex_dmem_re      ),
        .ex_regs_w_addr  (ex_regs_w_addr  ),
        .mem_dmem_re     (mem_dmem_re     ),
        .mem_regs_w_addr (mem_regs_w_addr ),
        .pipeline_stall  (pipeline_stall  )
    );
    
    
endmodule
