`timescale 1ns / 1ps

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
