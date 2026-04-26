`timescale 1ns / 1ps

module ctrl_late_detect(
    input  wire       id_branch_flag,
    input  wire       id_jalr_flag,
    input  wire [4:0] id_rs1_addr,
    input  wire [4:0] id_rs2_addr,
    input  wire       ex_dmem_re,
    input  wire [4:0] ex_regs_w_addr,
    output wire       id_ctrl_defer,
    output wire       id_ctrl_dep_rs1,
    output wire       id_ctrl_dep_rs2
);

    wire load_hazard = ex_dmem_re && (ex_regs_w_addr != 5'd0);
    wire branch_dep_rs1 = id_branch_flag && (id_rs1_addr == ex_regs_w_addr);
    wire branch_dep_rs2 = id_branch_flag && (id_rs2_addr == ex_regs_w_addr);
    wire jalr_dep_rs1 = id_jalr_flag && (id_rs1_addr == ex_regs_w_addr);

    assign id_ctrl_dep_rs1 = load_hazard && (branch_dep_rs1 || jalr_dep_rs1);
    assign id_ctrl_dep_rs2 = load_hazard && branch_dep_rs2;
    assign id_ctrl_defer = id_ctrl_dep_rs1 || id_ctrl_dep_rs2;

endmodule
