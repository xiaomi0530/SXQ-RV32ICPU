`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/06 14:25:50
// Design Name: 
// Module Name: cpu_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu_tb();

    reg  clk;
    reg  rst_n;
    wire [15:0] led;

    // 直接实例化 cpu，绕过 PLL
    cpu u_cpu(
        .clk   (clk  ),
        .rst_n (rst_n),
        .led   (led  )
    );

    // 10ns 周期 = 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // 复位：低有效，先拉低再释放
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // ── MMIO 读写监控 ──────────────────────────────────────
    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && !u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF) begin
            $display("[%0t ns] MMIO READ   addr=%08x  data=%08x  ack=%b",
                     $time, u_cpu.bus_m_addr,
                     u_cpu.bus_m_dat_o, u_cpu.bus_m_ack);
        end
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF) begin
            $display("[%0t ns] MMIO WRITE  addr=%08x  data=%08x  ack=%b",
                     $time, u_cpu.bus_m_addr,
                     u_cpu.bus_m_dat_i, u_cpu.bus_m_ack);
        end
    end

    // ── LED 变化监控 ───────────────────────────────────────
    always @(led) begin
        $display("[%0t ns] LED = %04x", $time, led);
    end

    // ── tohost 监控：写入即结束仿真 ────────────────────────
    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr == 32'hF0000008) begin
            $display("[%0t ns] TOHOST WRITE = %08x", $time, u_cpu.bus_m_dat_i);
            if (u_cpu.bus_m_dat_i != 0) begin
                $display("=== Simulation END, LED=%04x ===", led);
                #100;
                $finish;
            end
        end
    end

    // ── 超时保护 ───────────────────────────────────────────
    initial begin
        #50000000; // 50ms = 5,000,000 cycles @ 100MHz
        $display("TIMEOUT");
        $finish;
    end

endmodule
