`timescale 1ns / 1ps

module pc(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        redirect_flag,
    input  wire [31:0] redirect_addr,
    input  wire        preif_ready,
    input  wire        pipeline_stall,
    output reg  [31:0] pc_o,
    output reg         preif_valid_o
);

    wire [31:0] pc_plus4 = pc_o + 32'd4;
    wire [31:0] pc_plus8 = pc_o + 32'd8;
    wire        preif_fire = preif_valid_o && preif_ready;
    wire [31:0] pc_next    = preif_fire ? pc_plus8 : pc_plus4;

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            pc_o <= 32'h0;
        end else if (redirect_flag) begin
            pc_o <= {17'b0, redirect_addr[14:0]};
        end else if (!pipeline_stall) begin
            pc_o <= {17'b0, pc_next[14:0]};
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || redirect_flag) begin
            preif_valid_o <= 1'b1;
        end else if (!pipeline_stall) begin
            if (preif_fire)
                preif_valid_o <= 1'b0;
        end
    end
endmodule
