`timescale 1ns / 1ps

module branch_predictor #(
    parameter integer ENTRY_NUM  = 16,
    parameter integer INDEX_BITS = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] lookup_pc0,
    output wire        pred_taken0,
    output wire [31:0] pred_target0,
    output wire        btb_hit0,
    input  wire [31:0] lookup_pc1,
    output wire        pred_taken1,
    output wire [31:0] pred_target1,
    output wire        btb_hit1,
    input  wire        update_en,
    input  wire [31:0] update_pc,
    input  wire        update_taken,
    input  wire [31:0] update_target
);

    localparam integer TAG_BITS = 30 - INDEX_BITS;

    reg [ENTRY_NUM-1:0]              btb_valid;
    reg [TAG_BITS-1:0]               btb_tag    [0:ENTRY_NUM-1];
    reg [31:0]                       btb_target [0:ENTRY_NUM-1];
    reg [1:0]                        bht_ctr    [0:ENTRY_NUM-1];

    wire [INDEX_BITS-1:0] lookup_idx0 = lookup_pc0[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag0 = lookup_pc0[31:INDEX_BITS+2];
    wire [INDEX_BITS-1:0] lookup_idx1 = lookup_pc1[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag1 = lookup_pc1[31:INDEX_BITS+2];

    wire [INDEX_BITS-1:0] update_idx = update_pc[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag = update_pc[31:INDEX_BITS+2];

    assign btb_hit0     = btb_valid[lookup_idx0] && (btb_tag[lookup_idx0] == lookup_tag0);
    assign pred_taken0  = btb_hit0 && bht_ctr[lookup_idx0][1];
    assign pred_target0 = btb_target[lookup_idx0];

    assign btb_hit1     = btb_valid[lookup_idx1] && (btb_tag[lookup_idx1] == lookup_tag1);
    assign pred_taken1  = btb_hit1 && bht_ctr[lookup_idx1][1];
    assign pred_target1 = btb_target[lookup_idx1];

    integer i;
    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            btb_valid <= {ENTRY_NUM{1'b0}};
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                btb_tag[i]    <= {TAG_BITS{1'b0}};
                btb_target[i] <= 32'b0;
                bht_ctr[i]    <= 2'b01;
            end
        end else if (update_en) begin
            btb_valid[update_idx]  <= 1'b1;
            btb_tag[update_idx]    <= update_tag;
            btb_target[update_idx] <= update_target;

            if (!btb_valid[update_idx] || (btb_tag[update_idx] != update_tag)) begin
                bht_ctr[update_idx] <= update_taken ? 2'b10 : 2'b01;
            end else if (update_taken) begin
                case (bht_ctr[update_idx])
                    2'b00: bht_ctr[update_idx] <= 2'b01;
                    2'b01: bht_ctr[update_idx] <= 2'b10;
                    default: bht_ctr[update_idx] <= 2'b11;
                endcase
            end else begin
                case (bht_ctr[update_idx])
                    2'b11: bht_ctr[update_idx] <= 2'b10;
                    2'b10: bht_ctr[update_idx] <= 2'b01;
                    default: bht_ctr[update_idx] <= 2'b00;
                endcase
            end
        end
    end

endmodule
