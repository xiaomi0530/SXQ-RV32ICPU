`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 19:14:17
// Design Name: 
// Module Name: ex
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

module ex(
    input wire [31:0] ex_instr_addr, 
    input wire [31:0] ex_alu_num1,   
    input wire [31:0] ex_alu_num2,  

    input wire [3:0]  ex_alu_op,
    input wire [2:0]  ex_mem_op,
    input wire        ex_branch_flag,  
    input wire [31:0] ex_branch_jump_addr,
    input wire        ex_jump_flag,   

    output reg [31:0] ex_regs_w_data, 
    output wire [31:0] ex_dmem_wr_addr, 

    output reg         ex_actual_jump_flag, 
    output wire [31:0] ex_actual_jump_addr
);

    wire [31:0] sub_res = ex_alu_num1 - ex_alu_num2;
    wire is_equal = (sub_res == 32'b0);
    wire is_less_signed = (ex_alu_num1[31] != ex_alu_num2[31]) ? ex_alu_num1[31] : sub_res[31];
    wire is_less_unsigned = (ex_alu_num1 < ex_alu_num2);

    reg [31:0] alu_out;

    always @(*) begin
        case (ex_alu_op)
            4'b0000: alu_out = ex_alu_num1 + ex_alu_num2;
            4'b1000: alu_out = sub_res;
            4'b0111: alu_out = ex_alu_num1 & ex_alu_num2;
            4'b0110: alu_out = ex_alu_num1 | ex_alu_num2;
            4'b0100: alu_out = ex_alu_num1 ^ ex_alu_num2;
            4'b0001: alu_out = ex_alu_num1 << ex_alu_num2[4:0];
            4'b0101: alu_out = ex_alu_num1 >> ex_alu_num2[4:0];
            4'b1101: alu_out = $signed(ex_alu_num1) >>> ex_alu_num2[4:0];
            4'b0010: alu_out = {31'b0, is_less_signed};
            4'b0011: alu_out = {31'b0, is_less_unsigned};
            default: alu_out = 32'b0;
        endcase
    end

    assign ex_actual_jump_addr = ex_branch_flag? ex_branch_jump_addr : alu_out;

    always @(*) begin
        if (ex_jump_flag) begin
            ex_actual_jump_flag = 1'b1;
        end else if (ex_branch_flag) begin
            case (ex_mem_op)
                3'b000: ex_actual_jump_flag = is_equal;
                3'b001: ex_actual_jump_flag = !is_equal;
                3'b100: ex_actual_jump_flag = is_less_signed;
                3'b101: ex_actual_jump_flag = !is_less_signed;
                3'b110: ex_actual_jump_flag = is_less_unsigned;
                3'b111: ex_actual_jump_flag = !is_less_unsigned;
                default: ex_actual_jump_flag = 1'b0;
            endcase
        end else begin
            ex_actual_jump_flag = 1'b0;
        end
    end

    always @(*) begin
        if (ex_jump_flag)
            ex_regs_w_data = ex_instr_addr + 4;
        else
            ex_regs_w_data = alu_out;
    end

    assign ex_dmem_wr_addr = alu_out;

endmodule
