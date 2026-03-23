`timescale 1ns / 1ps

module mem_wb(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mem_dmem_re,
    input  wire        mem_regs_we,
    input  wire [4:0]  mem_regs_w_addr,
    input  wire [31:0] mem_regs_w_data,
    output reg         wb_dmem_re,
    output reg         wb_regs_we,
    output reg  [4:0]  wb_regs_w_addr,
    output reg  [31:0] wb_regs_w_data
);

    always@(posedge clk)begin
        if(rst_n == `RST_ENABLE)begin
            wb_regs_we <= 1'b0;
        end else begin
            wb_regs_we <= mem_regs_we; 
        end    
    end

    always@(posedge clk) begin
        wb_dmem_re <= mem_dmem_re;
        wb_regs_w_data <= mem_regs_w_data;
        wb_regs_w_addr <= mem_regs_w_addr;
    end

endmodule
