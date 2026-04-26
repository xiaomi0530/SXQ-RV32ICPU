`timescale 1ns / 1ps

module pipeline_stall(
    input  wire [4:0]  id_rs1_addr,
    input  wire [4:0]  id_rs2_addr,
    input  wire        id_rs1_used,
    input  wire        id_rs2_used,
    input  wire        id_ctrl_defer,

    input  wire        ex_dmem_re,
    input  wire [4:0]  ex_regs_w_addr,

    input  wire        mem_dmem_re,
    input  wire [4:0]  mem_regs_w_addr,

    output wire        pipeline_stall
);

    wire rs1_hazard = id_rs1_used && (id_rs1_addr == ex_regs_w_addr);
    wire rs2_hazard = id_rs2_used && (id_rs2_addr == ex_regs_w_addr);
    wire load_hazard = ex_dmem_re
                    && (ex_regs_w_addr != 0)
                    && (rs1_hazard || rs2_hazard);

    assign pipeline_stall = load_hazard && !id_ctrl_defer;

endmodule
