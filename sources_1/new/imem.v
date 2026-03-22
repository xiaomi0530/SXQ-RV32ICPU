`timescale 1ns / 1ps
// imem.v — Instruction Memory (expanded to 32KB for CoreMark)
//
// CHANGE: 4096 → 8192 words, address index [14:2] instead of [13:2]

module imem(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pipeline_stall,
    input  wire        pipeline_flush,
    input  wire [31:0] instr_addr_i,
    output reg  [31:0] instr_o,
    output reg  [31:0] instr_addr_o,

    input  wire        bus_stb,
    output reg         bus_ack,
    input  wire [31:0] r_addr,
    input  wire        bus_we,
    input  wire [2:0]  mem_op,
    output reg  [31:0] r_data
);

    (* ram_style = "block" *) reg [31:0] imem [0:8191];

    wire [12:0] word_addr = r_addr[14:2];
    wire re = bus_stb && !bus_we;

    always @(posedge clk) begin
        if(rst_n == `RST_ENABLE || pipeline_flush)begin
            instr_o <= 1'b0;
            instr_addr_o <= 32'b0;
        end else if(!pipeline_stall)begin
            instr_o <= imem[instr_addr_i[14:2]];
            instr_addr_o <= instr_addr_i; 
        end 
    end
    
    initial begin
        $readmemh("imem.mem",imem);
    end

    reg [2:0]   mem_op_r;
    reg [1:0]   r_addr_r;
    reg         re_r;
    reg [31:0]  word_data;

    always@(posedge clk) begin
        bus_ack <= 1'b0;
        if(re)begin
            word_data <= imem[word_addr];  
            bus_ack <= 1'b1;
        end
        mem_op_r <= mem_op;
        r_addr_r <= r_addr[1:0];
        re_r <= re;
    end

    always @(*) begin
        if(re_r)begin
            case (mem_op_r)
                3'b000: // LB
                    case (r_addr_r[1:0])
                        2'b00: r_data = {{24{word_data[7]}},  word_data[7:0]};
                        2'b01: r_data = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: r_data = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: r_data = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                3'b001: // LH
                    case (r_addr_r[1])
                        1'b0: r_data = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: r_data = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                3'b010: r_data = word_data; // LW
                3'b100: // LBU
                    case (r_addr_r[1:0])
                        2'b00: r_data = {24'b0, word_data[7:0]};
                        2'b01: r_data = {24'b0, word_data[15:8]};
                        2'b10: r_data = {24'b0, word_data[23:16]};
                        2'b11: r_data = {24'b0, word_data[31:24]};
                    endcase
                3'b101: // LHU
                    case (r_addr_r[1])
                        1'b0: r_data = {16'b0, word_data[15:0]};
                        1'b1: r_data = {16'b0, word_data[31:16]};
                    endcase
                default: r_data = word_data; //LW
            endcase
        end else begin
            r_data = 32'h0;
        end
    end 
    
    
endmodule