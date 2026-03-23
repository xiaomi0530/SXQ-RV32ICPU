`timescale 1ns / 1ps

module id(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] id_instr_addr,
    input  wire [31:0] id_instr,

    output wire        regs_re,
    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,

    output wire [4:0]  rd_addr,
    output wire        regs_we,

    output reg  [3:0]  alu_op,
    output wire [31:0] alu_num1,
    output wire [31:0] alu_num2,

    output wire [2:0]  mem_op,

    output wire        dmem_we,
    output wire        dmem_re,
    output wire [31:0] dmem_w_data,

    output wire        branch_flag,
    output wire [31:0] branch_jump_addr,
    output wire        jump_flag
);
    
    wire [6:0] opcode = id_instr[6:0];
    wire [2:0] funct3 = id_instr[14:12];
    wire [6:0] funct7 = id_instr[31:25];

    wire type_r       = (opcode == 7'b0110011);
    wire type_i_alu   = (opcode == 7'b0010011);
    wire type_i_load  = (opcode == 7'b0000011);
    wire type_i_jalr  = (opcode == 7'b1100111);
    wire type_s       = (opcode == 7'b0100011);
    wire type_b       = (opcode == 7'b1100011);
    wire type_u_lui   = (opcode == 7'b0110111);
    wire type_u_auipc = (opcode == 7'b0010111);
    wire type_j_jal   = (opcode == 7'b1101111);

    reg [31:0] imm;
    wire [31:0] i_imm = {{21{id_instr[31]}}, id_instr[30:20]};
    wire [31:0] s_imm = {{21{id_instr[31]}}, id_instr[30:25], id_instr[11:7]};
    wire [31:0] b_imm = {{20{id_instr[31]}}, id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
    wire [31:0] u_imm = {id_instr[31:12], 12'b0};
    wire [31:0] j_imm = {{12{id_instr[31]}}, id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};

    always @(*) begin
        case (opcode)
            7'b0000011, 7'b0010011, 7'b1100111: imm = i_imm;
            7'b0100011:                         imm = s_imm;
            7'b1100011:                         imm = b_imm;
            7'b0110111, 7'b0010111:             imm = u_imm;
            7'b1101111:                         imm = j_imm;
            default:                            imm = 32'b0;
        endcase
    end

    assign rs1_addr = id_instr[19:15];
    assign rs2_addr = id_instr[24:20];
    assign rd_addr  = id_instr[11:7];

    assign regs_we  = type_r | type_i_alu | type_i_load | type_i_jalr | type_u_lui | type_u_auipc | type_j_jal;
    assign regs_re  = type_r | type_i_alu | type_i_load | type_i_jalr | type_s | type_b;
    
    assign dmem_we  = type_s;
    assign dmem_re  = type_i_load;
    assign dmem_w_data = rs2_data;
    assign mem_op   = funct3; 

    assign branch_flag = type_b;
    assign branch_jump_addr = b_imm + id_instr_addr;
    assign jump_flag   = type_j_jal | type_i_jalr;

    assign alu_num1 = (type_u_auipc | type_j_jal) ? id_instr_addr : (type_u_lui ? 32'b0 : rs1_data);
    assign alu_num2 = (type_r | type_b) ? rs2_data : imm;

    wire rv32m_any = type_r && (funct7 == 7'b0000001);
    wire rv32m_mul = rv32m_any && (funct3[2] == 1'b0);

    localparam [3:0] ALU_OP_MUL     = 4'b1001;
    localparam [3:0] ALU_OP_MULH    = 4'b1010;
    localparam [3:0] ALU_OP_MULHSU  = 4'b1011;
    localparam [3:0] ALU_OP_MULHU   = 4'b1111;

    always @(*) begin 
        if (rv32m_mul) begin
            case (funct3)
                3'b000: alu_op = ALU_OP_MUL;
                3'b001: alu_op = ALU_OP_MULH;
                3'b010: alu_op = ALU_OP_MULHSU;
                3'b011: alu_op = ALU_OP_MULHU;
                default: alu_op = 4'b0000;
            endcase
        end else if (rv32m_any) begin
            alu_op = 4'b0000;
        end else if (type_r || type_i_alu) begin
            alu_op = { ( (type_r && funct7[5]) || (type_i_alu && funct3==3'b101 && funct7[5]) ), funct3 };
        end else if (type_b) begin
            alu_op = 4'b1000;
        end else begin
            alu_op = 4'b0000; 
        end
    end

endmodule
