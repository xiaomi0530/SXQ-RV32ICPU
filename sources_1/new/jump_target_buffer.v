`timescale 1ns / 1ps

module jump_target_buffer #(
    parameter integer ENTRY_NUM  = 8,
    parameter integer INDEX_BITS = 3
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] lookup_pc0,
    output wire        hit0,
    output wire [31:0] target0,
    input  wire [31:0] lookup_pc1,
    output wire        hit1,
    output wire [31:0] target1,
    input  wire        update_en,
    input  wire [31:0] update_pc,
    input  wire [31:0] update_target
);

    localparam integer TAG_BITS = 30 - INDEX_BITS;

    reg [ENTRY_NUM-1:0]              jtb_valid;
    reg [TAG_BITS-1:0]               jtb_tag    [0:ENTRY_NUM-1];
    reg [31:0]                       jtb_target [0:ENTRY_NUM-1];

    wire [INDEX_BITS-1:0] lookup_idx0 = lookup_pc0[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag0 = lookup_pc0[31:INDEX_BITS+2];
    wire [INDEX_BITS-1:0] lookup_idx1 = lookup_pc1[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag1 = lookup_pc1[31:INDEX_BITS+2];
    wire [INDEX_BITS-1:0] update_idx = update_pc[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag = update_pc[31:INDEX_BITS+2];

    assign hit0    = jtb_valid[lookup_idx0] && (jtb_tag[lookup_idx0] == lookup_tag0);
    assign target0 = jtb_target[lookup_idx0];
    assign hit1    = jtb_valid[lookup_idx1] && (jtb_tag[lookup_idx1] == lookup_tag1);
    assign target1 = jtb_target[lookup_idx1];

    integer i;
    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            jtb_valid <= {ENTRY_NUM{1'b0}};
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                jtb_tag[i]    <= {TAG_BITS{1'b0}};
                jtb_target[i] <= 32'b0;
            end
        end else if (update_en) begin
            jtb_valid[update_idx]  <= 1'b1;
            jtb_tag[update_idx]    <= update_tag;
            jtb_target[update_idx] <= update_target;
        end
    end

endmodule
