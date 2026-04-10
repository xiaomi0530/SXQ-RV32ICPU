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
    input  wire        update_en,
    input  wire [31:0] update_pc,
    input  wire        update_taken,
    input  wire [31:0] update_target
);

    localparam integer TAG_BITS = 30 - INDEX_BITS;
    localparam integer OFFSET_BITS = 13;

    reg [ENTRY_NUM-1:0]              btb_valid;
    reg [TAG_BITS-1:0]               btb_tag    [0:ENTRY_NUM-1];
    reg [OFFSET_BITS-1:0]            btb_offset [0:ENTRY_NUM-1];
    reg [1:0]                        bht_ctr    [0:ENTRY_NUM-1];

    wire [INDEX_BITS-1:0] lookup_idx0 = lookup_pc0[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   lookup_tag0 = lookup_pc0[31:INDEX_BITS+2];
    wire [INDEX_BITS-1:0] update_idx = update_pc[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag = update_pc[31:INDEX_BITS+2];
    wire [31:0]           lookup_offset0 = {{(32 - OFFSET_BITS){btb_offset[lookup_idx0][OFFSET_BITS-1]}}, btb_offset[lookup_idx0]};
    wire [31:0]           update_offset = update_target - update_pc;

    assign btb_hit0     = btb_valid[lookup_idx0] && (btb_tag[lookup_idx0] == lookup_tag0);
    assign pred_taken0  = btb_hit0 && bht_ctr[lookup_idx0][1];
    assign pred_target0 = lookup_pc0 + lookup_offset0;

    integer i;
    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            btb_valid <= {ENTRY_NUM{1'b0}};
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                btb_tag[i]    <= {TAG_BITS{1'b0}};
                btb_offset[i] <= {OFFSET_BITS{1'b0}};
                bht_ctr[i]    <= 2'b01;
            end
        end else if (update_en) begin
            if (btb_valid[update_idx] && (btb_tag[update_idx] == update_tag)) begin
                if (update_taken)
                    btb_offset[update_idx] <= update_offset[OFFSET_BITS-1:0];

                if (update_taken) begin
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
            end else if (update_taken) begin
                btb_valid[update_idx]  <= 1'b1;
                btb_tag[update_idx]    <= update_tag;
                btb_offset[update_idx] <= update_offset[OFFSET_BITS-1:0];
                bht_ctr[update_idx]    <= 2'b10;
            end
        end
    end

endmodule
