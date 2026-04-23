`timescale 1ns / 1ps
`include "defines.v"

module branch_hash_mix #(
    parameter integer INDEX_BITS = `BR_PRED_INDEX_BITS,
    parameter integer PC_CANON_BITS = `BR_PRED_PC_CANON_BITS
)(
    input  wire [31:0] pc_value,
    input  wire [10:1] imm_lo_value,
    output reg   [INDEX_BITS-1:0] hash_value
);

    integer bit_idx;
    always @* begin
        hash_value = {INDEX_BITS{1'b0}};
        for (bit_idx = 0; bit_idx < INDEX_BITS; bit_idx = bit_idx + 1) begin
            if (((6 + bit_idx) < PC_CANON_BITS) && ((5 + bit_idx) <= 10))
                hash_value[bit_idx] = pc_value[6 + bit_idx] ^ imm_lo_value[5 + bit_idx];
        end
    end

endmodule
