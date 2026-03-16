`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/12 11:05:14
// Design Name: 
// Module Name: pipeline_stall
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module pipeline_stall(
    input  wire [4:0]  id_rs1_addr,
    input  wire [4:0]  id_rs2_addr,

    input  wire        ex_dmem_re,
    input  wire [4:0]  ex_regs_w_addr,

    input  wire        mem_dmem_re,
    input  wire [4:0]  mem_regs_w_addr,

    output wire        pipeline_stall
);

    wire when_ex  = ex_dmem_re
                    && (ex_regs_w_addr != 0)
                    && (id_rs1_addr == ex_regs_w_addr || id_rs2_addr == ex_regs_w_addr);

    wire when_mem = mem_dmem_re
                    && (mem_regs_w_addr != 0)
                    && (id_rs1_addr == mem_regs_w_addr || id_rs2_addr == mem_regs_w_addr);

    assign pipeline_stall = when_ex || when_mem;

endmodule
