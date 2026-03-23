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

    cpu u_cpu(
        .clk   (clk  ),
        .rst_n (rst_n),
        .led   (led  )
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // ── MMIO 读写监控 ──────────────────────────────────────
    always @(posedge clk) begin
        if (u_cpu.bus_m_stb && !u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF) begin
            $display("[%0t ns] MMIO READ  addr=%08x",
                     $time, u_cpu.bus_m_addr);
            #10;
            $display("data=%08x ",
                     u_cpu.bus_m_dat_o);
        end
        if (u_cpu.bus_m_stb && u_cpu.bus_m_we
                && u_cpu.bus_m_addr[31:28] == 4'hF) begin
            $display("[%0t ns] MMIO WRITE  addr=%08x",
                     $time, u_cpu.bus_m_addr);
            #10;
            $display("data=%08x ",
                     u_cpu.bus_m_dat_o);
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
       always @(posedge clk) begin
        if (u_cpu.u_mmio.uart_valid)
            $write("%c", u_cpu.u_mmio.uart_data);
    end
    always @(posedge clk) begin
        if (u_cpu.u_mmio.tohost) begin
            $display("");
            $display("LED = %04X", u_cpu.u_mmio.led);
            if (u_cpu.u_mmio.led == 16'h0000)
                $display(">>> PASSED <<<");
            else
                $display(">>> FAILED at sub-test %0d <<<", u_cpu.u_mmio.led);
            $finish;
        end
    end

endmodule
