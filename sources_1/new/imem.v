`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 14:25:00
// Design Name: 
// Module Name: imem
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


module imem(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pipeline_stall,
    input  wire        pipeline_flush,
    input  wire [31:0] instr_addr_i,
    output reg  [31:0] instr_o,
    output reg  [31:0] instr_addr_o
);

    (* ram_style = "block" *) reg [31:0] imem [0:1023];

    always @(posedge clk) begin
        if(rst_n == `RST_ENABLE || pipeline_flush)begin
            instr_o <= 1'b0;
            instr_addr_o <= 32'b0;
        end else if(!pipeline_stall)begin
            instr_o <= imem[instr_addr_i>>2];
            instr_addr_o <= instr_addr_i; 
        end 
    end
    
    initial begin
        $readmemh("imem.mem",imem);
    end
    
    
endmodule
