`timescale 1ns / 1ps

module ex_mem(
    input  wire clk,
    input  wire rst_n,
    input  wire pipeline_hold,

    input  wire        ex_regs_we,
    input  wire [4:0]  ex_regs_w_addr,
    input  wire [31:0] ex_regs_w_data,
    input  wire [31:0] ex_dmem_wr_addr,
    input  wire [31:0] ex_dmem_w_data,
    input  wire        ex_dmem_we,
    input  wire        ex_dmem_re,
    input  wire [2:0]  ex_mem_op,

    output reg         mem_regs_we,
    output reg  [4:0]  mem_regs_w_addr,
    output reg  [31:0] mem_regs_w_data,
    output reg  [31:0] mem_dmem_wr_addr,
    output reg  [31:0] mem_dmem_w_data,
    output reg         mem_dmem_we,
    output reg         mem_dmem_re,
    output reg  [2:0]  mem_mem_op
);

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            mem_regs_we <= 1'b0;
            mem_dmem_we <= 1'b0;
            mem_dmem_re <= 1'b0;
        end else if (!pipeline_hold) begin
            mem_regs_we <= ex_regs_we;
            mem_dmem_we <= ex_dmem_we;
            mem_dmem_re <= ex_dmem_re;
        end
    end

    always @(posedge clk) begin
        if (!pipeline_hold) begin
            mem_regs_w_addr  <= ex_regs_w_addr;
            mem_regs_w_data  <= ex_regs_w_data;
            mem_dmem_wr_addr <= ex_dmem_wr_addr;
            mem_dmem_w_data  <= ex_dmem_w_data;
            mem_mem_op       <= ex_mem_op;
        end
    end

endmodule
