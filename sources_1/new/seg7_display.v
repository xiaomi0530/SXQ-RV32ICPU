`timescale 1ns / 1ps

module seg7_display(
    input  wire        clk,       // 100MHz
    input  wire        rst_n,
    input  wire [31:0] value,     // value to display
    output reg  [7:0]  an,        // digit select (active low)
    output reg  [6:0]  seg        // segment {CA,CB,CC,CD,CE,CF,CG} = {a,b,c,d,e,f,g} active low
);

    // ------------------------------------------------------------------------
    // Refresh counter
    // ------------------------------------------------------------------------
    reg [16:0] refresh_cnt;
    wire [2:0] digit_sel = refresh_cnt[16:14];

    always @(posedge clk) begin
        if (!rst_n)
            refresh_cnt <= 0;
        else
            refresh_cnt <= refresh_cnt + 1;
    end

    // ------------------------------------------------------------------------
    // Binary to BCD (Double Dabble), combinational
    // ------------------------------------------------------------------------
    reg [3:0] bcd_comb [0:9];
    integer i, j;

    always @* begin
        for (j = 0; j < 10; j = j + 1)
            bcd_comb[j] = 4'd0;

        for (i = 31; i >= 0; i = i - 1) begin
            // Step 1: add-3 if >= 5
            for (j = 0; j < 10; j = j + 1)
                if (bcd_comb[j] >= 5)
                    bcd_comb[j] = bcd_comb[j] + 3;

            // Step 2: shift all digits left by one and inject the next input bit.
            begin : shift_block
                reg [9:0] c;
                for (j = 0; j < 10; j = j + 1)
                    c[j] = bcd_comb[j][3];
                for (j = 9; j >= 1; j = j - 1)
                    bcd_comb[j] = {bcd_comb[j][2:0], c[j - 1]};
                bcd_comb[0] = {bcd_comb[0][2:0], value[i]};
            end
        end
    end

    // ------------------------------------------------------------------------
    // Register BCD to break deep combinational timing path
    // ------------------------------------------------------------------------
    reg [3:0] bcd [0:7];
    always @(posedge clk) begin
        if (!rst_n) begin
            for (j = 0; j < 8; j = j + 1)
                bcd[j] <= 4'd0;
        end else begin
            bcd[0] <= bcd_comb[0];
            bcd[1] <= bcd_comb[1];
            bcd[2] <= bcd_comb[2];
            bcd[3] <= bcd_comb[3];
            bcd[4] <= bcd_comb[4];
            bcd[5] <= bcd_comb[5];
            bcd[6] <= bcd_comb[6];
            bcd[7] <= bcd_comb[7];
        end
    end

    // ------------------------------------------------------------------------
    // Leading zero blanking
    // ------------------------------------------------------------------------
    reg [7:0] digit_active;
    always @* begin
        digit_active[7] = (bcd[7] != 0);
        digit_active[6] = (bcd[7] != 0) || (bcd[6] != 0);
        digit_active[5] = (bcd[7] != 0) || (bcd[6] != 0) || (bcd[5] != 0);
        digit_active[4] = (bcd[7] != 0) || (bcd[6] != 0) || (bcd[5] != 0) || (bcd[4] != 0);
        digit_active[3] = (bcd[7] != 0) || (bcd[6] != 0) || (bcd[5] != 0) || (bcd[4] != 0) || (bcd[3] != 0);
        digit_active[2] = (bcd[7] != 0) || (bcd[6] != 0) || (bcd[5] != 0) || (bcd[4] != 0) || (bcd[3] != 0) || (bcd[2] != 0);
        digit_active[1] = (bcd[7] != 0) || (bcd[6] != 0) || (bcd[5] != 0) || (bcd[4] != 0) || (bcd[3] != 0) || (bcd[2] != 0) || (bcd[1] != 0);
        digit_active[0] = 1'b1; // ones digit always shown
    end

    // ------------------------------------------------------------------------
    // Select current digit
    // ------------------------------------------------------------------------
    reg [3:0] cur_digit;
    always @* begin
        case (digit_sel)
            3'd0: cur_digit = bcd[0];
            3'd1: cur_digit = bcd[1];
            3'd2: cur_digit = bcd[2];
            3'd3: cur_digit = bcd[3];
            3'd4: cur_digit = bcd[4];
            3'd5: cur_digit = bcd[5];
            3'd6: cur_digit = bcd[6];
            3'd7: cur_digit = bcd[7];
            default: cur_digit = 4'd0;
        endcase
    end

    // ------------------------------------------------------------------------
    // Anode select (active low)
    // ------------------------------------------------------------------------
    always @* begin
        an = 8'b11111111;
        if (digit_active[digit_sel])
            an[digit_sel] = 1'b0;
    end

    // ------------------------------------------------------------------------
    // Seven-segment decode
    // ------------------------------------------------------------------------
    // seg[6:0] = {CA,CB,CC,CD,CE,CF,CG} = {a,b,c,d,e,f,g}, active low
    always @* begin
        case (cur_digit)
            4'd0: seg = 7'b0000001; // abcdef ON, g OFF
            4'd1: seg = 7'b1001111; // bc ON
            4'd2: seg = 7'b0010010; // abdeg ON  (a,b,g,e,d)
            4'd3: seg = 7'b0000110; // abcdg ON
            4'd4: seg = 7'b1001100; // bcfg ON
            4'd5: seg = 7'b0100100; // acdfg ON  (a,f,g,c,d)
            4'd6: seg = 7'b0100000; // acdefg ON
            4'd7: seg = 7'b0001111; // abc ON
            4'd8: seg = 7'b0000000; // all ON
            4'd9: seg = 7'b0000100; // abcdfg ON
            default: seg = 7'b1111111; // all OFF
        endcase
    end

endmodule
