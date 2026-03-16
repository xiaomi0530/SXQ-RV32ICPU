`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 14:25:50
// Design Name: 
// Module Name: cpu_tb
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


module cpu_tb();
    reg clk;
    reg rst_n;
    wire [15:0] led;
    
    top u_top(
    .clk   (clk   ),
    .rst_n (rst_n ),
    .led   (led   )
    );
    
    initial begin
        rst_n = 0;
        #10;           
        rst_n = 1;    
    end
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
endmodule
