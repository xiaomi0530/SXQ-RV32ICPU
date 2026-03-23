`timescale 1ns / 1ps

module bus_interconnect(
    input  wire clk,
    input  wire rst_n,
    
    input  wire bus_m_stb,
    output wire bus_m_ack,
    input  wire bus_m_we,
    input  wire [31:0] bus_m_addr,
    input  wire [31:0] bus_m_dat_i,
    output wire [31:0] bus_m_dat_o,
 
    output wire bus_s0_stb,
    input  wire bus_s0_ack,
    output wire bus_s0_we,
    output wire [31:0] bus_s0_addr,
    input  wire [31:0] bus_s0_dat_i,
    output wire [31:0] bus_s0_dat_o,
 
    output wire bus_s1_stb,
    input  wire bus_s1_ack,
    output wire bus_s1_we,
    output wire [31:0] bus_s1_addr,
    input  wire [31:0] bus_s1_dat_i,
    output wire [31:0] bus_s1_dat_o,
 
    output wire bus_s2_stb,
    input  wire bus_s2_ack,
    output wire bus_s2_we,
    output wire [31:0] bus_s2_addr,
    input  wire [31:0] bus_s2_dat_i,
    output wire [31:0] bus_s2_dat_o
    );
 
    wire m_sel_s0;
    wire m_sel_s1;
    wire m_sel_s2;
 
    reg m_sel_s0_r;
    reg m_sel_s1_r;
    reg m_sel_s2_r;
 
    assign m_sel_s0 = bus_m_stb && (bus_m_addr <= 32'h7FFC);                             //0x00000000 - 0x00007FFC 32KB IMEM
    assign m_sel_s1 = bus_m_stb && (bus_m_addr <= 32'h1FFFC && bus_m_addr >= 32'h10000); //0x00010000 - 0x0001FFFC 32KB DMEM
    assign m_sel_s2 = bus_m_stb && (bus_m_addr[31:28] == 4'hF);                          //0xF0000000                   MMIO
 
    assign bus_s0_stb = bus_m_stb && m_sel_s0;
    assign bus_s1_stb = bus_m_stb && m_sel_s1;
    assign bus_s2_stb = bus_m_stb && m_sel_s2;
    
    assign bus_s0_we = bus_m_we;
    assign bus_s1_we = bus_m_we;
    assign bus_s2_we = bus_m_we;
 
    assign bus_s0_addr = bus_m_addr;
    assign bus_s1_addr = bus_m_addr;
    assign bus_s2_addr = bus_m_addr;
 
    assign bus_s0_dat_o = bus_m_dat_i; //write_data
    assign bus_s1_dat_o = bus_m_dat_i;
    assign bus_s2_dat_o = bus_m_dat_i;
 
    assign bus_m_dat_o = m_sel_s0_r ? bus_s0_dat_i : //read_data
                         m_sel_s1_r ? bus_s1_dat_i :
                         m_sel_s2_r ? bus_s2_dat_i : 32'h0;
 
    assign bus_m_ack = m_sel_s0_r ? bus_s0_ack :
                       m_sel_s1_r ? bus_s1_ack :
                       m_sel_s2_r ? bus_s2_ack : 1'b0;
    
    localparam IDLE = 2'b01;
    localparam BUSY = 2'b10;
    reg [1:0] status;
 
    always@(posedge clk)begin
        if(rst_n == `RST_ENABLE)begin
            m_sel_s0_r <= 1'b0;
            m_sel_s1_r <= 1'b0;
            m_sel_s2_r <= 1'b0;
            status <= IDLE;
        end else if(bus_m_stb && status == IDLE) begin
            m_sel_s0_r <= m_sel_s0;
            m_sel_s1_r <= m_sel_s1;
            m_sel_s2_r <= m_sel_s2;
            status <= BUSY;
        end else if(status == BUSY) begin
            if(bus_m_stb) begin
                m_sel_s0_r <= m_sel_s0;
                m_sel_s1_r <= m_sel_s1;
                m_sel_s2_r <= m_sel_s2;
                // stay BUSY
            end else begin
                m_sel_s0_r <= 0;
                m_sel_s1_r <= 0;
                m_sel_s2_r <= 0;
                status <= IDLE;
            end
        end
    end
 
endmodule
