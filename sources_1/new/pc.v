`timescale 1ns / 1ps

module pc(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        redirect_flag,
    input  wire [31:0] redirect_addr,
    input  wire        pred_taken,
    input  wire [31:0] pred_target,
    input  wire        pipeline_stall,
    output reg  [31:0] pc_o,
    output reg         preif_valid_o
);

    wire [31:0] pc_plus4 = pc_o + 32'd4;
    wire [31:0] pc_plus8 = pc_o + 32'd8;
    wire [31:0] seq_next = preif_valid_o ? pc_plus8 : pc_plus4;
    wire [31:0] pc_next  = pred_taken ? pred_target : seq_next;

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            pc_o <= 32'h0;
        end else if (redirect_flag) begin
            pc_o <= redirect_addr;
        end else if (!pipeline_stall) begin
            pc_o <= pc_next;
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || redirect_flag) begin
            preif_valid_o <= 1'b1;
        end else if (!pipeline_stall) begin
            if (pred_taken)
                preif_valid_o <= 1'b0;
            else if (preif_valid_o)
                preif_valid_o <= 1'b0;
        end
    end
endmodule
