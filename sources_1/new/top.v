`timescale 1ns / 1ps

module top(
    input  wire        clk,
    input  wire        rst_n,
    output wire [15:0] led,
    output wire [7:0]  an,    
    output wire [6:0]  seg,
    output wire        uart_tx
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
        .clk    (clk_100mhz ),
        .rst_n  (cpu_rst_n  ),
        .led    (led        ),
        .uart_tx(uart_tx    )
    );
 

    wire [31:0] display_value = {16'b0, led};
 
    seg7_display u_seg7(
        .clk   (clk_100mhz ),
        .rst_n (cpu_rst_n   ),
        .value (display_value),
        .an    (an          ),
        .seg   (seg         )
    );
    
endmodule
