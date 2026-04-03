`timescale 1ns / 1ps

module if_id(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pipeline_stall,
    input  wire        pipeline_hold,
    input  wire        pipeline_flush,

    input  wire [31:0] if_instr_i,
    input  wire [31:0] if_instr_addr_i,
    input  wire [31:0] if_pre_instr_i,
    input  wire [31:0] if_pre_instr_addr_i,
    input  wire        if_pre_valid_i,

    output reg  [31:0] id_instr_o,
    output reg  [31:0] id_instr_addr_o
);

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            id_instr_o      <= 32'b0;
            id_instr_addr_o <= 32'b0;
        end else if (pipeline_flush) begin
            id_instr_o      <= 32'b0;
            id_instr_addr_o <= 32'b0;
        end else if (!(pipeline_stall || pipeline_hold)) begin
            if (if_pre_valid_i) begin
                id_instr_o      <= if_pre_instr_i;
                id_instr_addr_o <= if_pre_instr_addr_i;
            end else begin
                id_instr_o      <= if_instr_i;
                id_instr_addr_o <= if_instr_addr_i;
            end
        end
    end

endmodule
