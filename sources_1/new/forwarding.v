`timescale 1ns / 1ps

module forwarding(
    input  wire [4:0]  id_rs1_addr,
    input  wire [4:0]  id_rs2_addr,
    input  wire [31:0] id_rs1_data,
    input  wire [31:0] id_rs2_data,

    input  wire        ex_regs_we,
    input  wire [4:0]  ex_regs_w_addr,
    input  wire [31:0] ex_regs_w_data,

    input  wire        mem_regs_we,
    input  wire [4:0]  mem_regs_w_addr,
    input  wire [31:0] mem_regs_w_data,

    input  wire        wb_regs_we,
    input  wire [4:0]  wb_regs_w_addr,
    input  wire [31:0] wb_actual_regs_w_data,

    output reg  [31:0] id_rs1_data_fwd,
    output reg  [31:0] id_rs2_data_fwd
);

    wire when_ex_rs1  = ex_regs_we  && (ex_regs_w_addr  != 0) && (id_rs1_addr == ex_regs_w_addr);
    wire when_mem_rs1 = mem_regs_we && (mem_regs_w_addr  != 0) && (id_rs1_addr == mem_regs_w_addr);
    wire when_wb_rs1  = wb_regs_we  && (wb_regs_w_addr   != 0) && (id_rs1_addr == wb_regs_w_addr);

    wire when_ex_rs2  = ex_regs_we  && (ex_regs_w_addr  != 0) && (id_rs2_addr == ex_regs_w_addr);
    wire when_mem_rs2 = mem_regs_we && (mem_regs_w_addr  != 0) && (id_rs2_addr == mem_regs_w_addr);
    wire when_wb_rs2  = wb_regs_we  && (wb_regs_w_addr   != 0) && (id_rs2_addr == wb_regs_w_addr);

    always @(*) begin
        if      (when_ex_rs1)  id_rs1_data_fwd = ex_regs_w_data;
        else if (when_mem_rs1) id_rs1_data_fwd = mem_regs_w_data;
        else if (when_wb_rs1)  id_rs1_data_fwd = wb_actual_regs_w_data;
        else                   id_rs1_data_fwd = id_rs1_data;
    end

    always @(*) begin
        if      (when_ex_rs2)  id_rs2_data_fwd = ex_regs_w_data;
        else if (when_mem_rs2) id_rs2_data_fwd = mem_regs_w_data;
        else if (when_wb_rs2)  id_rs2_data_fwd = wb_actual_regs_w_data;
        else                   id_rs2_data_fwd = id_rs2_data;
    end

endmodule