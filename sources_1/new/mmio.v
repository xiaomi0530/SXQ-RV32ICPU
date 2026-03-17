`timescale 1ns / 1ps

//   0xF0000000  cycle_cnt_lo  只读，64位计数器低32位
//   0xF0000004  cycle_cnt_hi  只读，64位计数器高32位（锁存值）
//   0xF0000008  tohost        只写，写1表示程序结束
//   0xF000000C  led           只写，低16位驱动 LED
//   0xF0000010  uart          只写，低8位输出一个字符

module mmio(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        bus_stb,
    output reg         bus_ack,
    input  wire        bus_we,
    input  wire [31:0] bus_addr,
    input  wire [31:0] w_data,  
    output reg  [31:0] r_data,  

    output reg  [15:0] led,
    output reg         uart_valid,
    output reg  [7:0]  uart_data,
    output reg         tohost
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
                6'h08: tohost    <= w_data[0];
                6'h0C: led       <= w_data[15:0];
                6'h10: begin
                    uart_data  <= w_data[7:0];
                    uart_valid <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        case (bus_addr[5:0])
            6'h00:   r_data <= cycle_cnt[31:0];   // timer 低32位
            6'h04:   r_data <= cycle_cnt[63:32];  // timer 高32位
            default: r_data <= 32'h0;
        endcase
    end

endmodule