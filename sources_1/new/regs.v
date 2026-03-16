`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 17:24:10
// Design Name: 
// Module Name: regs
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


module regs(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        re,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output reg  [31:0] rs1_data,
    output reg  [31:0] rs2_data,

    input  wire        we,
    input  wire [4:0]  w_addr,
    input  wire [31:0] w_data
);

    integer i; 
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end //DEBUG
    
    reg [31:0] regs [0:31];

    always@(posedge clk)begin
        if(rst_n == `RST_ENABLE)begin
            regs[0] <= 32'h0;
        end else if (we)begin
            regs[w_addr] <= (w_addr==1'b0)? 32'h0 : w_data;
        end
    end

    always@(*)begin
        if(rst_n == `RST_ENABLE)begin
            rs1_data = 32'h0;
            rs2_data = 32'h0;
        end else if (re)begin
            rs1_data = regs[rs1_addr];
            rs2_data = regs[rs2_addr];
        end else begin
            rs1_data = 32'h0;
            rs2_data = 32'h0;
        end
    end 

endmodule
