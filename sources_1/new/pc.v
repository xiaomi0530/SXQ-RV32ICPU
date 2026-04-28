`timescale 1ns / 1ps
`include "defines.v"

module pc(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        redirect_flag,
    input  wire        redirect_force,
    input  wire [`IMEM_ADDR_BITS-1:0] redirect_addr,
    input  wire        preif_ready,
    input  wire        pipeline_stall,
    output reg   [31:0] pc_o,
    output reg          preif_valid_o
);
    localparam integer IMEM_ADDR_BITS = `IMEM_ADDR_BITS;
    localparam integer IMEM_PAD_BITS  = `CPU_ADDR_BITS - IMEM_ADDR_BITS;
    localparam [IMEM_ADDR_BITS-1:0] ADDR_INC4 = {{(IMEM_ADDR_BITS-3){1'b0}}, 3'd4};
    localparam [IMEM_ADDR_BITS-1:0] ADDR_INC8 = {{(IMEM_ADDR_BITS-4){1'b0}}, 4'd8};

    wire        preif_fire   = preif_valid_o && preif_ready;
    wire [IMEM_ADDR_BITS-1:0] pc_inc_low   = preif_fire ? ADDR_INC8 : ADDR_INC4;
    wire [IMEM_ADDR_BITS-1:0] pc_next_low  = pc_o[IMEM_ADDR_BITS-1:0] + pc_inc_low;
    wire        pc_write_en  = redirect_force || !pipeline_stall;
    wire        redirect_commit = redirect_flag && pc_write_en;
    wire [IMEM_ADDR_BITS-1:0] pc_write_low = redirect_flag ? redirect_addr : pc_next_low;

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            pc_o <= 32'h0;
        end else if (pc_write_en) begin
            pc_o <= {{IMEM_PAD_BITS{1'b0}}, pc_write_low};
        end
    end

    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE || redirect_commit) begin
            preif_valid_o <= 1'b1;
        end else if (!pipeline_stall) begin
            if (preif_fire)
                preif_valid_o <= 1'b0;
        end
    end
endmodule
