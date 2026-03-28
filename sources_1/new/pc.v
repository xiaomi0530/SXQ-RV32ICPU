`timescale 1ns / 1ps

module pc(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        jump_flag,
    input  wire [31:0] jump_addr,
    input  wire        pipeline_stall,
    output reg  [31:0] pc_o,
    output reg         preif_valid_o
);

    wire [31:0] pc_plus4 = pc_o + 32'd4;
    wire [31:0] pc_plus8 = pc_o + 32'd8;
    wire [31:0] pc_next  = jump_flag ? jump_addr
                          : (preif_valid_o ? pc_plus8 : pc_plus4);

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            pc_o <= 32'h0;
        end else if (jump_flag) begin
            pc_o <= jump_addr;
        end else if (!pipeline_stall) begin
            pc_o <= pc_next;
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || jump_flag) begin
            preif_valid_o <= 1'b1;
        end else if (!pipeline_stall && preif_valid_o) begin
            preif_valid_o <= 1'b0;
        end
    end
endmodule
