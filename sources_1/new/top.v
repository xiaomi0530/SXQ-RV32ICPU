`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/09 11:46:46
// Design Name: 
// Module Name: top
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


module top(
    input  wire        clk,
    input  wire        rst_n,
    output wire [15:0] led
);
    
    wire locked;
    wire clk_100mhz;
    wire cpu_rst_n;
    clk_main_100mhz u_clk_main_100mhz(
      .clk_out1(clk_100mhz),
      .resetn(rst_n),
      .locked(locked),
      .clk_in1(clk)
     );

    assign cpu_rst_n = locked; 
    cpu u_cpu(
        .clk   (clk_100mhz  ),
        .rst_n (cpu_rst_n   ),
        .led   (led         )
    );
    
endmodule
