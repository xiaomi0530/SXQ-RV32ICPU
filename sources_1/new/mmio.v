`timescale 1ns / 1ps
`include "defines.v"

// Register map (base = 0xF0000000)
//   0x00  cycle_cnt_lo   [RO] 64-bit cycle counter low word
//   0x04  cycle_cnt_hi   [RO] 64-bit cycle counter high word
//   0x08  tohost         [WO] bit0=1 indicates program completed
//   0x0C  led            [WO] drive LED[15:0]
//   0x10  uart_tx_data   [WO] enqueue one byte to UART
//   0x14  uart_status    [RO] {overflow, busy, ready}

module mmio(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        bus_stb,
    output reg          bus_ack,
    input  wire        bus_we,
    input  wire [31:0] bus_addr,
    input  wire [31:0] w_data,
    output reg   [31:0] r_data,

    output reg   [15:0] led,
    output reg          uart_valid,
    output reg   [7:0]  uart_data,
    output reg          tohost,
    input  wire        uart_busy,
    input  wire        uart_ready,
    input  wire        uart_overflow
);

    reg [63:0] cycle_cnt;
    always @(posedge clk) begin
        if (!rst_n) cycle_cnt <= 64'h0;
        else        cycle_cnt <= cycle_cnt + 1;
    end

    always @(posedge clk) begin
        if (!rst_n) bus_ack <= 1'b0;
        else        bus_ack <= bus_stb;
    end

    always @(posedge clk) begin
        uart_valid <= 1'b0;
        if (!rst_n) begin
            tohost    <= 1'b0;
            led       <= 16'h0;
            uart_data <= 8'h0;
        end else if (bus_stb && bus_we) begin
            case (bus_addr[5:0])
                `MMIO_TOHOST_OFFSET: tohost <= w_data[0];
                `MMIO_LED_OFFSET:    led    <= w_data[15:0];
                `MMIO_UART_TX_OFFSET: begin
                    uart_data  <= w_data[7:0];
                    uart_valid <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        case (bus_addr[5:0])
            `MMIO_TIMER_LO_OFFSET:   r_data <= cycle_cnt[31:0];
            `MMIO_TIMER_HI_OFFSET:   r_data <= cycle_cnt[63:32];
            `MMIO_INSTRET_LO_OFFSET: r_data <= 32'h0;
            `MMIO_INSTRET_HI_OFFSET: r_data <= 32'h0;
            `MMIO_UART_STATUS_OFFSET:r_data <= {29'd0, uart_overflow, uart_busy, uart_ready};
            default:                 r_data <= 32'h0;
        endcase
    end

endmodule
