`timescale 1ns / 1ps

module ctrl_late_detect(
    input  wire       id_branch_flag,
    input  wire       id_jalr_flag,
    input  wire [4:0] id_rs1_addr,
    input  wire [4:0] id_rs2_addr,
    input  wire       id_rs1_used,
    input  wire       id_rs2_used,
    input  wire       ex_dmem_re,
    input  wire [4:0] ex_regs_w_addr,
    output wire       id_ctrl_defer,
    output wire       id_ctrl_dep_rs1,
    output wire       id_ctrl_dep_rs2,
    output wire       pipeline_stall
);

    wire load_rd_valid = ex_dmem_re && (ex_regs_w_addr != 5'd0);
    wire rs1_load_match = load_rd_valid && (id_rs1_addr == ex_regs_w_addr);
    wire rs2_load_match = load_rd_valid && (id_rs2_addr == ex_regs_w_addr);
    wire normal_load_hazard = (id_rs1_used && rs1_load_match)
                            || (id_rs2_used && rs2_load_match);

    assign id_ctrl_dep_rs1 = (id_branch_flag || id_jalr_flag) && rs1_load_match;
    assign id_ctrl_dep_rs2 = id_branch_flag && rs2_load_match;
    assign id_ctrl_defer = id_ctrl_dep_rs1 || id_ctrl_dep_rs2;
    assign pipeline_stall = normal_load_hazard && !id_ctrl_defer;

endmodule
