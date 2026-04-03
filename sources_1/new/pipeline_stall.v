`timescale 1ns / 1ps

module pipeline_stall(
    input  wire [4:0]  id_rs1_addr,
    input  wire [4:0]  id_rs2_addr,

    input  wire        ex_dmem_re,
    input  wire [4:0]  ex_regs_w_addr,

    input  wire        mem_dmem_re,
    input  wire [4:0]  mem_regs_w_addr,

    output wire        pipeline_stall
);

    assign pipeline_stall = ex_dmem_re
                            && (ex_regs_w_addr != 0)
                            && (id_rs1_addr == ex_regs_w_addr || id_rs2_addr == ex_regs_w_addr);

endmodule
