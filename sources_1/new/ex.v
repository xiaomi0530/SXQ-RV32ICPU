`timescale 1ns / 1ps

module ex(
    input wire        clk,
    input wire        rst_n,
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
    output wire [31:0] ex_actual_jump_addr,
    output wire        ex_mul_busy
);
    
    wire [31:0] sub_res = ex_alu_num1 - ex_alu_num2;
    wire is_equal = (sub_res == 32'b0);
    wire is_less_signed = (ex_alu_num1[31] != ex_alu_num2[31]) ? ex_alu_num1[31] : sub_res[31];
    wire is_less_unsigned = (ex_alu_num1 < ex_alu_num2);

    localparam [3:0] ALU_OP_ADD    = 4'b0000;
    localparam [3:0] ALU_OP_SUB    = 4'b1000;
    localparam [3:0] ALU_OP_AND    = 4'b0111;
    localparam [3:0] ALU_OP_OR     = 4'b0110;
    localparam [3:0] ALU_OP_XOR    = 4'b0100;
    localparam [3:0] ALU_OP_SLL    = 4'b0001;
    localparam [3:0] ALU_OP_SRL    = 4'b0101;
    localparam [3:0] ALU_OP_SRA    = 4'b1101;
    localparam [3:0] ALU_OP_SLT    = 4'b0010;
    localparam [3:0] ALU_OP_SLTU   = 4'b0011;
    localparam [3:0] ALU_OP_MUL    = 4'b1001;
    localparam [3:0] ALU_OP_MULH   = 4'b1010;
    localparam [3:0] ALU_OP_MULHSU = 4'b1011;
    localparam [3:0] ALU_OP_MULHU  = 4'b1111;

    wire is_mul    = (ex_alu_op == ALU_OP_MUL);
    wire is_mulh   = (ex_alu_op == ALU_OP_MULH);
    wire is_mulhsu = (ex_alu_op == ALU_OP_MULHSU);
    wire is_mulhu  = (ex_alu_op == ALU_OP_MULHU);
    wire mul_op    = is_mul | is_mulh | is_mulhsu | is_mulhu;

    reg mul_inflight;
    wire mul_start = mul_op && !mul_inflight;
    wire signed_a  = is_mul | is_mulh | is_mulhsu;
    wire signed_b  = is_mul | is_mulh;

    wire [63:0] mul_result;
    wire        mul_ready;

    mul_unit u_mul_unit (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (mul_start),
        .signed_a(signed_a),
        .signed_b(signed_b),
        .op_a    (ex_alu_num1),
        .op_b    (ex_alu_num2),
        .result  (mul_result),
        .ready   (mul_ready)
    );

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE)
            mul_inflight <= 1'b0;
        else if (mul_ready)
            mul_inflight <= 1'b0;
        else if (mul_start)
            mul_inflight <= 1'b1;
    end

    wire mul_hold = mul_start | (mul_inflight && !mul_ready);
    assign ex_mul_busy = mul_hold;

    reg [31:0] alu_out;

    always @(*) begin
        case (ex_alu_op)
            ALU_OP_ADD:    alu_out = ex_alu_num1 + ex_alu_num2;
            ALU_OP_SUB:    alu_out = sub_res;
            ALU_OP_AND:    alu_out = ex_alu_num1 & ex_alu_num2;
            ALU_OP_OR:     alu_out = ex_alu_num1 | ex_alu_num2;
            ALU_OP_XOR:    alu_out = ex_alu_num1 ^ ex_alu_num2;
            ALU_OP_SLL:    alu_out = ex_alu_num1 << ex_alu_num2[4:0];
            ALU_OP_SRL:    alu_out = ex_alu_num1 >> ex_alu_num2[4:0];
            ALU_OP_SRA:    alu_out = $signed(ex_alu_num1) >>> ex_alu_num2[4:0];
            ALU_OP_SLT:    alu_out = {31'b0, is_less_signed};
            ALU_OP_SLTU:   alu_out = {31'b0, is_less_unsigned};
            ALU_OP_MUL:    alu_out = mul_result[31:0];
            ALU_OP_MULH,
            ALU_OP_MULHSU,
            ALU_OP_MULHU:  alu_out = mul_result[63:32];
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

    assign ex_dmem_wr_addr = ex_alu_num1 + ex_alu_num2;

endmodule
