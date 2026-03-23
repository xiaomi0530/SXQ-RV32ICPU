`timescale 1ns / 1ps
/*
 * UART TX module for RV32I CoreMark output
 *
 * Features:
 *  - Parameterised clock frequency / baud rate (default 100 MHz / 115200 baud)
 *  - Simple FIFO buffer to absorb burst writes from mmio (default 64 bytes)
 *  - 8N1 framing, LSB first, idle high
 */

module uart_tx #(
    parameter integer CLK_FREQ   = 100_000_000,
    parameter integer BAUD_RATE  = 115_200,
    parameter integer FIFO_DEPTH = 128
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_valid,
    input  wire [7:0] tx_data,
    output wire       tx_busy,
    output wire       tx_ready,
    output reg        tx,          // UART TX line
    output reg        overflow     // set when FIFO overflows (sticky)
);
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1) begin
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam integer BAUD_DIV = CLK_FREQ / BAUD_RATE;
    initial begin
        if (BAUD_DIV < 8) begin
            $error("uart_tx: BAUD_DIV too small. Check clock/baud settings.");
        end
    end

    localparam integer FIFO_ADDR_WIDTH =
        (FIFO_DEPTH <= 2)   ? 1 :
        (FIFO_DEPTH <= 4)   ? 2 :
        (FIFO_DEPTH <= 8)   ? 3 :
        (FIFO_DEPTH <= 16)  ? 4 :
        (FIFO_DEPTH <= 32)  ? 5 :
        (FIFO_DEPTH <= 64)  ? 6 :
        (FIFO_DEPTH <= 128) ? 7 :
        (FIFO_DEPTH <= 256) ? 8 :
        (FIFO_DEPTH <= 512) ? 9 : 10;

    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_WIDTH-1:0] wr_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] rd_ptr;
    reg [FIFO_ADDR_WIDTH:0]   fifo_count;

    wire fifo_not_full  = (fifo_count < FIFO_DEPTH);
    wire fifo_not_empty = (fifo_count != 0);
    reg       tx_active;

    // Transmission state
    localparam integer BAUD_CNT_WIDTH = (BAUD_DIV <= 2) ? 1 : clog2(BAUD_DIV);

    reg [9:0] shifter;
    reg [3:0] bit_count;
    reg [BAUD_CNT_WIDTH-1:0] baud_cnt;

    wire push_req = tx_valid && fifo_not_full;
    wire pop_req  = (!tx_active) && fifo_not_empty;

    assign tx_busy  = tx_active | fifo_not_empty;
    assign tx_ready = fifo_not_full;

    integer i;
    initial begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo_mem[i] = 8'h00;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr     <= {FIFO_ADDR_WIDTH{1'b0}};
            rd_ptr     <= {FIFO_ADDR_WIDTH{1'b0}};
            fifo_count <= { (FIFO_ADDR_WIDTH+1){1'b0} };
            tx_active  <= 1'b0;
            bit_count  <= 4'd0;
            baud_cnt   <= {BAUD_CNT_WIDTH{1'b0}};
            shifter    <= 10'b1111111111;
            tx         <= 1'b1;
            overflow   <= 1'b0;
        end else begin
            // enqueue request
            if (tx_valid) begin
                if (fifo_not_full) begin
                    fifo_mem[wr_ptr] <= tx_data;
                    wr_ptr <= wr_ptr + 1'b1;
                end else begin
                    overflow <= 1'b1;
                end
            end

            if (pop_req) begin
                shifter   <= {1'b1, fifo_mem[rd_ptr], 1'b0};
                rd_ptr    <= rd_ptr + 1'b1;
                tx        <= 1'b0; // start bit
                tx_active <= 1'b1;
                bit_count <= 4'd0;
                baud_cnt  <= {BAUD_CNT_WIDTH{1'b0}};
            end else if (tx_active) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= {BAUD_CNT_WIDTH{1'b0}};
                    shifter  <= {1'b1, shifter[9:1]};
                    if (bit_count == 4'd9) begin
                        tx_active <= 1'b0;
                        tx        <= 1'b1; // idle high after stop bit
                    end else begin
                        bit_count <= bit_count + 1'b1;
                        tx        <= shifter[1];
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end else begin
                tx <= 1'b1;
            end

            case ({push_req, pop_req})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end
endmodule
