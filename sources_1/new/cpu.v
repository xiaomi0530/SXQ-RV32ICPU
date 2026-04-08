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
    
    wire pipeline_stall;
    wire pipeline_flush;
    wire ex_mul_busy;
    wire pipeline_hold = ex_mul_busy;
    wire pipeline_block = pipeline_stall | pipeline_hold;
    wire preif_valid;
    wire if_pre_valid;
    reg  if_pre_valid_q;
    wire [31:0] preif_pc_addr;

    wire [31:0] ex_instr_addr;
    wire        ex_branch_flag;
    wire        ex_actual_jump_flag;
    wire [31:0] ex_actual_jump_addr;
    wire [31:0] ex_branch_jump_addr;
    wire [2:0]  ex_mem_op;
    wire        bus_s0_stb;
    wire        bus_s0_ack;
    wire        bus_s0_we;
    wire [31:0] bus_s0_addr;
    wire [31:0] bus_s0_dat_i;
    wire [31:0] bus_s0_dat_o;
    
    wire        preif_pred_taken;
    wire [31:0] preif_pred_target;
    wire        preif_btb_hit;
    wire        preif_next_pred_taken;
    wire [31:0] preif_next_pred_target;
    wire        preif_next_btb_hit;
    wire        ex_mispredict;
    wire [31:0] ex_redirect_addr;
    wire        id_pred_taken_reg;
    wire [31:0] id_pred_target_reg;
    reg         if_pred_taken;
    reg  [31:0] if_pred_target;
    reg         if_pre_pred_taken;
    reg  [31:0] if_pre_pred_target;
    wire        slot1_pred_redirect = if_pre_valid && if_pre_pred_taken;
    wire        frontend_redirect_flag = ex_mispredict | slot1_pred_redirect;
    wire [31:0] frontend_redirect_addr = ex_mispredict ? ex_redirect_addr : if_pre_pred_target;
    (* keep = "true", max_fanout = 16 *) wire pipeline_hold_if = pipeline_hold;
    (* keep = "true", max_fanout = 16 *) wire pipeline_hold_id = pipeline_hold;
    (* keep = "true", max_fanout = 16 *) wire pipeline_hold_exm = pipeline_hold;
    (* keep = "true", max_fanout = 16 *) wire pipeline_block_pc = pipeline_block;
    (* keep = "true", max_fanout = 16 *) wire pipeline_block_imem = pipeline_block;
    (* keep = "true", max_fanout = 16 *) wire pipeline_block_if = pipeline_block;
    (* keep = "true", max_fanout = 16 *) wire pipeline_flush_if = pipeline_flush;
    (* keep = "true", max_fanout = 16 *) wire slot1_pred_redirect_if = slot1_pred_redirect;
    (* keep = "true", max_fanout = 16 *) wire frontend_redirect_flag_pc = frontend_redirect_flag;
    (* keep = "true", max_fanout = 16 *) wire [31:0] frontend_redirect_addr_pc = frontend_redirect_addr;

    branch_predictor #(
        .ENTRY_NUM  (16),
        .INDEX_BITS (4)
    ) u_branch_predictor (
        .clk         (clk               ),
        .rst_n       (rst_n             ),
        .lookup_pc0  (preif_pc_addr     ),
        .pred_taken0 (preif_pred_taken  ),
        .pred_target0(preif_pred_target ),
        .btb_hit0    (preif_btb_hit     ),
        .lookup_pc1  (preif_pc_addr + 32'd4),
        .pred_taken1 (preif_next_pred_taken ),
        .pred_target1(preif_next_pred_target),
        .btb_hit1    (preif_next_btb_hit),
        .update_en   (ex_branch_flag    ),
        .update_pc   (ex_instr_addr     ),
        .update_taken(ex_actual_jump_flag),
        .update_target(ex_branch_jump_addr)
    );
    //PREIF
    pc u_pc(
        .clk            (clk                  ),
        .rst_n          (rst_n                ),
        .redirect_flag  (frontend_redirect_flag_pc),
        .redirect_addr  (frontend_redirect_addr_pc),
        .pred_taken     (preif_pred_taken     ),
        .pred_target    (preif_pred_target    ),
        .pipeline_stall (pipeline_block_pc    ),
        .pc_o           (preif_pc_addr        ),
        .preif_valid_o  (preif_valid          )
    );

    wire [31:0] if_instr;
    wire [31:0] if_instr_addr;
    wire [31:0] id_instr_reg;
    wire [31:0] id_instr_addr_reg;
    wire [31:0] if_pre_instr;
    wire [31:0] if_pre_instr_addr;

    (* keep = "true", max_fanout = 32 *) wire pipeline_flush_imem  = pipeline_flush;
    (* keep = "true", max_fanout = 32 *) wire pipeline_flush_if_id = pipeline_flush;
    (* keep = "true", max_fanout = 32 *) wire pipeline_flush_id_ex = pipeline_flush;

    wire if_pre_valid_imem;

    imem u_imem(
        .clk                (clk               ),
        .rst_n              (rst_n             ),
        .pipeline_stall     (pipeline_block_imem),
        .pipeline_flush     (pipeline_flush_imem),
        .predict_taken_i    (preif_pred_taken  ),
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

    wire imem_bus_re = bus_s0_stb && !bus_s0_we;
    wire if_pre_capture_en = preif_valid && !preif_pred_taken && !imem_bus_re;
    assign if_pre_valid = if_pre_valid_q;

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            if_pre_valid_q    <= 1'b0;
            if_pred_taken     <= 1'b0;
            if_pred_target    <= 32'b0;
            if_pre_pred_taken <= 1'b0;
            if_pre_pred_target<= 32'b0;
        end else if (slot1_pred_redirect_if) begin
            if_pre_valid_q     <= 1'b0;
            if_pred_taken      <= 1'b0;
            if_pre_pred_taken  <= 1'b0;
        end else if (pipeline_flush_if) begin
            if_pre_valid_q     <= 1'b0;
            if_pred_taken      <= 1'b0;
            if_pre_pred_taken  <= 1'b0;
        end else if (!pipeline_block_if) begin
            if_pre_valid_q <= if_pre_capture_en;
            if_pred_taken  <= preif_pred_taken;
            if_pred_target <= preif_pred_target;
            if (if_pre_capture_en) begin
                if_pre_pred_taken  <= preif_next_pred_taken;
                if_pre_pred_target <= preif_next_pred_target;
            end else begin
                if_pre_pred_taken  <= 1'b0;
                if_pre_pred_target <= 32'b0;
            end
        end
    end

    if_id u_if_id(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .pipeline_stall  (pipeline_stall  ),
        .pipeline_hold   (pipeline_hold_if),
        .pipeline_flush  (pipeline_flush_if_id),
        .frontend_kill   (slot1_pred_redirect_if),
        .if_instr_i      (if_instr        ),
        .if_instr_addr_i (if_instr_addr   ),
        .if_pred_taken_i (if_pred_taken   ),
        .if_pred_target_i(if_pred_target  ),
        .if_pre_instr_i  (if_pre_instr    ),
        .if_pre_instr_addr_i(if_pre_instr_addr),
        .if_pre_pred_taken_i (if_pre_pred_taken),
        .if_pre_pred_target_i(if_pre_pred_target),
        .if_pre_valid_i  (if_pre_valid    ),
        .id_instr_o      (id_instr_reg        ),
        .id_instr_addr_o (id_instr_addr_reg   ),
        .id_pred_taken_o (id_pred_taken_reg   ),
        .id_pred_target_o(id_pred_target_reg  )
    );

    //ID
    wire        id_regs_re;
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    wire [31:0] id_rs1_data_fwd;
    wire [31:0] id_rs2_data_fwd;

    wire        id_regs_we;
    wire [4:0]  id_regs_w_addr;

    wire [3:0]  id_alu_op;
    wire [31:0] id_alu_num1;
    wire [31:0] id_alu_num2;

    wire [2:0]  id_mem_op;
    wire        id_dmem_we;
    wire        id_dmem_re;
    wire [31:0] id_dmem_w_data;

    wire        id_branch_flag;
    wire [31:0] id_branch_jump_addr;
    wire        id_jump_flag;

    wire [31:0] id_instr;
    wire [31:0] id_instr_addr;
    wire        id_pred_taken;
    wire [31:0] id_pred_target;
    wire [31:0] if_instr_fwd = if_instr; // fanout split helper
    assign id_instr = if_pre_valid? if_instr_fwd : id_instr_reg;
    assign id_instr_addr = if_pre_valid? if_instr_addr : id_instr_addr_reg;
    assign id_pred_taken = if_pre_valid ? if_pred_taken : id_pred_taken_reg;
    assign id_pred_target = if_pre_valid ? if_pred_target : id_pred_target_reg;

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
        .id_jump_flag       (id_jump_flag       )
    );
    
    //ID_EX
    wire        ex_pred_taken;
    wire [31:0] ex_pred_target;
    wire [31:0] ex_alu_num1;
    wire [31:0] ex_alu_num2;
    wire [3:0]  ex_alu_op;
    wire [4:0]  ex_regs_w_addr;
    wire        ex_regs_we;
    wire        ex_dmem_we;
    wire        ex_dmem_re;
    wire [31:0] ex_dmem_w_data; 
    wire        ex_jump_flag;

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
        .id_jump_flag        (id_jump_flag        ),

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
        .ex_jump_flag        (ex_jump_flag        )
    );
    

    //EX
    wire [31:0] ex_regs_w_data; 
    wire [31:0] ex_dmem_wr_addr;
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
    wire        mem_regs_we;
    wire [4:0]  mem_regs_w_addr;
    wire [31:0] mem_regs_w_data; 

    wire [31:0] mem_dmem_wr_addr;
    wire [31:0] mem_dmem_w_data; 
    wire        mem_dmem_we;
    wire        mem_dmem_re;
    wire [2:0]  mem_mem_op;
    
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

    // Master
    wire        bus_m_stb;
    wire        bus_m_ack;
    wire        bus_m_we;
    wire [31:0] bus_m_addr;
    wire [31:0] bus_m_dat_i;
    wire [31:0] bus_m_dat_o;

    // Slave 1
    wire        bus_s1_stb;
    wire        bus_s1_ack;
    wire        bus_s1_we;
    wire [31:0] bus_s1_addr;
    wire [31:0] bus_s1_dat_i;
    wire [31:0] bus_s1_dat_o;

    // Slave 2
    wire        bus_s2_stb;
    wire        bus_s2_ack;
    wire        bus_s2_we;
    wire [31:0] bus_s2_addr;
    wire [31:0] bus_s2_dat_i;
    wire [31:0] bus_s2_dat_o;

    wire [31:0] mem_dmem_r_data;

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

    wire uart_valid;
    wire [7:0] uart_data;
    wire       tohost;
    wire       uart_line;
    wire       uart_busy;
    wire       uart_ready;
    wire       uart_overflow;

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
    wire        wb_regs_we;
    wire [4:0]  wb_regs_w_addr;
    wire [31:0] wb_regs_w_data;
    wire        wb_dmem_re;

    mem_wb u_mem_wb(
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .mem_dmem_re     (mem_dmem_re     ),
        .mem_regs_we     (mem_regs_we     ),
        .mem_regs_w_addr (mem_regs_w_addr ),
        .mem_regs_w_data (mem_dmem_re ? mem_dmem_r_data : mem_regs_w_data),
        .wb_dmem_re      (wb_dmem_re      ),
        .wb_regs_we      (wb_regs_we      ),
        .wb_regs_w_addr  (wb_regs_w_addr  ),
        .wb_regs_w_data  (wb_regs_w_data  )
    );
    
    wire [31:0] wb_actual_regs_w_data;
    assign wb_actual_regs_w_data = wb_regs_w_data;
    
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
        .mem_regs_w_data       (mem_dmem_re ? mem_dmem_r_data : mem_regs_w_data),

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
