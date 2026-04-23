`timescale 1ns / 1ps
`include "defines.v"

module ras #(
    parameter integer DEPTH = `RAS_DEPTH,
    parameter integer PTR_W = `RAS_PTR_W
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        slot0_jump_pred_base,
    input  wire        if_is_call,
    input  wire        if_is_ret,
    input  wire [31:0] if_instr_addr,
    output wire        ras_valid,
    output wire [14:0] ras_top_target_low,
    output wire        slot1_valid_shadow,
    output wire [14:0] slot1_top_target_shadow_low,
    input  wire        ex_jump_flag,
    input  wire        ex_call_flag,
    input  wire        ex_ret_flag,
    input  wire [31:0] ex_instr_addr
);

    reg [31:0] ras_stack [0:DEPTH-1];
    reg [PTR_W-1:0] ras_sp;
    reg [PTR_W:0]   ras_count;
    reg [31:0]      ras_top_target_q;
    reg [31:0]      ras_next_target_q;

    assign ras_valid = (ras_count != 0);
    assign ras_top_target_low = ras_top_target_q[14:0];
    assign slot1_valid_shadow = slot0_jump_pred_base && if_is_ret
                              ? (ras_count > 1)
                              : (slot0_jump_pred_base && if_is_call)
                              ? 1'b1
                              : ras_valid;
    assign slot1_top_target_shadow_low = (slot0_jump_pred_base && if_is_call)
                                       ? (if_instr_addr[14:0] + 15'd4)
                                       : ((slot0_jump_pred_base && if_is_ret)
                                       ? ras_next_target_q[14:0]
                                       : ras_top_target_q[14:0]);

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            ras_sp            <= {PTR_W{1'b0}};
            ras_count         <= {(PTR_W+1){1'b0}};
            ras_top_target_q  <= 32'b0;
            ras_next_target_q <= 32'b0;
        end else if (ex_jump_flag) begin
            if (ex_ret_flag) begin
                if (ras_count != 0) begin
                    ras_sp           <= ras_sp - 1'b1;
                    ras_count        <= ras_count - 1'b1;
                    ras_top_target_q <= (ras_count > 1) ? ras_next_target_q : 32'b0;
                    if (ras_count > 2)
                        ras_next_target_q <= ras_stack[ras_sp - 3'd3];
                    else
                        ras_next_target_q <= 32'b0;
                end
            end else if (ex_call_flag) begin
                ras_stack[ras_sp] <= ex_instr_addr + 32'd4;
                ras_sp            <= ras_sp + 1'b1;
                if (ras_count != DEPTH)
                    ras_count <= ras_count + 1'b1;
                ras_next_target_q <= ras_valid ? ras_top_target_q : 32'b0;
                ras_top_target_q  <= ex_instr_addr + 32'd4;
            end
        end
    end

endmodule
