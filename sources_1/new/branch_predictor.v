`timescale 1ns / 1ps

module branch_predictor #(
    parameter integer ENTRY_NUM  = 16,
    parameter integer INDEX_BITS = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        lookup_is_branch0,
    input  wire [31:0] lookup_pc0,
    input  wire [INDEX_BITS-1:0] lookup_hash0,
    output wire        pred_taken0,
    output wire        branch_hit0,
    input  wire        update_en,
    input  wire [31:0] update_pc,
    input  wire [INDEX_BITS-1:0] update_hash,
    input  wire        update_taken
);

    localparam integer TAG_BITS = 30 - INDEX_BITS;

    reg [ENTRY_NUM-1:0]              branch_valid;
    reg [TAG_BITS-1:0]               branch_tag    [0:ENTRY_NUM-1];
    reg [1:0]                        bht_ctr    [0:ENTRY_NUM-1];

    wire [INDEX_BITS-1:0] lookup_idx0 = lookup_pc0[INDEX_BITS+1:2] ^ lookup_hash0;
    wire [TAG_BITS-1:0]   lookup_tag0 = lookup_pc0[31:INDEX_BITS+2];
    wire [INDEX_BITS-1:0] update_idx = update_pc[INDEX_BITS+1:2] ^ update_hash;
    wire [TAG_BITS-1:0]   update_tag = update_pc[31:INDEX_BITS+2];

    assign branch_hit0     = lookup_is_branch0 && branch_valid[lookup_idx0] && (branch_tag[lookup_idx0] == lookup_tag0);
    assign pred_taken0  = branch_hit0 && bht_ctr[lookup_idx0][1];

    integer i;
    always @(posedge clk) begin
        if (rst_n == `RST_ENABLE) begin
            branch_valid <= {ENTRY_NUM{1'b0}};
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                branch_tag[i]    <= {TAG_BITS{1'b0}};
                bht_ctr[i]    <= 2'b01;
            end
        end else if (update_en) begin
            if (branch_valid[update_idx] && (branch_tag[update_idx] == update_tag)) begin
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
                branch_valid[update_idx]  <= 1'b1;
                branch_tag[update_idx]    <= update_tag;
                bht_ctr[update_idx]    <= 2'b10;
            end
        end
    end

endmodule

