`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 14:25:00
// Design Name: 
// Module Name: pc
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


module pc(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        jump_flag,
    input  wire [31:0] jump_addr,
    input  wire        pipeline_stall,
    output reg  [31:0] pc_o
);

    always@(posedge clk)begin
        if(rst_n == `RST_ENABLE)begin
            pc_o <= 32'h0;
        end else if(jump_flag)begin
            pc_o <= jump_addr;
        end else if(pipeline_stall)begin
            pc_o <= pc_o;
        end else begin
            pc_o <= pc_o + 32'h00000004;
        end
    end
endmodule
