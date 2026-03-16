`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 20:58:49
// Design Name: 
// Module Name: dmem
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


module dmem(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] w_data,
    input  wire [31:0] wr_addr,
    input  wire        we,
    input  wire        re,
    input  wire [2:0]  mem_op,
    output reg  [31:0] r_data
);

    (* ram_style = "block" *) reg [7:0] dmem0 [0:1023];
    (* ram_style = "block" *) reg [7:0] dmem1 [0:1023];
    (* ram_style = "block" *) reg [7:0] dmem2 [0:1023];
    (* ram_style = "block" *) reg [7:0] dmem3 [0:1023];

    wire [9:0] word_addr = wr_addr[11:2];

    always@(posedge clk)begin
        if(we)begin
            case(mem_op)
                3'b000: // SB
                case (wr_addr[1:0])
                    2'b00: dmem0[word_addr] <= w_data[7:0];
                    2'b01: dmem1[word_addr] <= w_data[7:0];
                    2'b10: dmem2[word_addr] <= w_data[7:0];
                    2'b11: dmem3[word_addr] <= w_data[7:0];
                endcase
                3'b001: // SH
                    case (wr_addr[1])
                        1'b0: begin
                            dmem0[word_addr] <= w_data[7:0];
                            dmem1[word_addr] <= w_data[15:8];
                        end
                        1'b1: begin
                            dmem2[word_addr] <= w_data[7:0];
                            dmem3[word_addr] <= w_data[15:8];
                        end
                    endcase
                3'b010: begin // SW
                    dmem0[word_addr] <= w_data[7:0];
                    dmem1[word_addr] <= w_data[15:8];
                    dmem2[word_addr] <= w_data[23:16];
                    dmem3[word_addr] <= w_data[31:24];
                end
            endcase
        end
    end

    reg [31:0]  word_data;
    reg [2:0]   mem_op_r;
    reg [1:0]   wr_addr_r;
    reg         re_r;
    
    always@(posedge clk) begin
        if(re)begin
            word_data <= {dmem3[word_addr], dmem2[word_addr],dmem1[word_addr], dmem0[word_addr]};  
        end
        mem_op_r <= mem_op;
        wr_addr_r <= wr_addr;
        re_r <= re;

    end
    

    always @(*) begin
        if(re_r)begin
            case (mem_op_r)
                3'b000: // LB
                    case (wr_addr_r[1:0])
                        2'b00: r_data = {{24{word_data[7]}},  word_data[7:0]};
                        2'b01: r_data = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: r_data = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: r_data = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                3'b001: // LH
                    case (wr_addr_r[1])
                        1'b0: r_data = {{16{word_data[15]}}, word_data[15:0]};
                        1'b1: r_data = {{16{word_data[31]}}, word_data[31:16]};
                    endcase
                3'b010: r_data = word_data; // LW
                3'b100: // LBU
                    case (wr_addr_r[1:0])
                        2'b00: r_data = {24'b0, word_data[7:0]};
                        2'b01: r_data = {24'b0, word_data[15:8]};
                        2'b10: r_data = {24'b0, word_data[23:16]};
                        2'b11: r_data = {24'b0, word_data[31:24]};
                    endcase
                3'b101: // LHU
                    case (wr_addr_r[1])
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
