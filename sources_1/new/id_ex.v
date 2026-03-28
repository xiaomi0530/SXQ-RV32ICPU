`timescale 1ns / 1ps

module id_ex(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pipeline_stall,
    input  wire        pipeline_hold,
    input  wire        pipeline_flush,

    input  wire [31:0] id_instr_addr,

    input  wire [31:0] id_alu_num1,
    input  wire [31:0] id_alu_num2,
    input  wire [3:0]  id_alu_op,
    input  wire [4:0]  id_regs_w_addr,
    input  wire        id_regs_we,
    input  wire [2:0]  id_mem_op,
    input  wire        id_dmem_we,
    input  wire        id_dmem_re,
    input  wire [31:0] id_dmem_w_data,
    input  wire        id_branch_flag,
    input  wire [31:0] id_branch_jump_addr,
    input  wire        id_jump_flag,

    output reg  [31:0] ex_instr_addr,
    output reg  [31:0] ex_alu_num1,
    output reg  [31:0] ex_alu_num2,
    output reg  [3:0]  ex_alu_op,
    output reg  [4:0]  ex_regs_w_addr,
    output reg         ex_regs_we,
    output reg  [2:0]  ex_mem_op,
    output reg         ex_dmem_we,
    output reg         ex_dmem_re,
    output reg  [31:0] ex_dmem_w_data,
    output reg         ex_branch_flag,
    output reg  [31:0] ex_branch_jump_addr,
    output reg         ex_jump_flag
);

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || pipeline_flush) begin
            ex_regs_we     <= 1'b0;
            ex_dmem_we     <= 1'b0;
            ex_dmem_re     <= 1'b0;
            ex_branch_flag <= 1'b0;
            ex_jump_flag   <= 1'b0;
        end else if (pipeline_stall) begin
            ex_regs_we     <= 1'b0;
            ex_dmem_we     <= 1'b0;
            ex_dmem_re     <= 1'b0;
            ex_branch_flag <= 1'b0;
            ex_jump_flag   <= 1'b0;
        end else if (!pipeline_hold) begin
            ex_regs_we     <= id_regs_we;
            ex_dmem_we     <= id_dmem_we;
            ex_dmem_re     <= id_dmem_re;
            ex_branch_flag <= id_branch_flag;
            ex_jump_flag   <= id_jump_flag;
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || pipeline_flush) begin
            ex_instr_addr       <= 32'b0;
            ex_alu_num1         <= 32'b0;
            ex_alu_num2         <= 32'b0;
            ex_alu_op           <= 4'b0;
            ex_regs_w_addr      <= 5'b0;
            ex_mem_op           <= 3'b0;
            ex_dmem_w_data      <= 32'b0;
            ex_branch_jump_addr <= 32'b0;
        end else if(!(pipeline_stall || pipeline_hold))begin
            ex_instr_addr       <= id_instr_addr;
            ex_alu_num1         <= id_alu_num1;
            ex_alu_num2         <= id_alu_num2;
            ex_alu_op           <= id_alu_op;
            ex_regs_w_addr      <= id_regs_w_addr;
            ex_mem_op           <= id_mem_op;
            ex_dmem_w_data      <= id_dmem_w_data;
            ex_branch_jump_addr <= id_branch_jump_addr;
        end
    end

endmodule
