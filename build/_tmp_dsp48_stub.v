module DSP48E1 #(
parameter AREG=0, BREG=0, CREG=0, DREG=0, MREG=0, PREG=0, ACASCREG=0, ADREG=0, ALUMODEREG=0,
parameter A_INPUT="DIRECT", B_INPUT="DIRECT", BCASCREG=0, CARRYINREG=0, CARRYINSELREG=0,
parameter CREG2=0, INMODEREG=0, MASK=48'h0, OPMODEREG=0, PATTERN=48'h0, PREG2=0,
parameter SEL_MASK="MASK", SEL_PATTERN="PATTERN", USE_DPORT="FALSE", USE_MULT="MULTIPLY",
parameter USE_PATTERN_DETECT="NO_PATDET", USE_SIMD="ONE48"
) (
input [29:0] A,
input [29:0] ACIN,
input [17:0] B,
input [17:0] BCIN,
input [47:0] C,
input [24:0] D,
input CARRYCASCIN,
input CARRYIN,
input [2:0] CARRYINSEL,
input CLK,
input [3:0] ALUMODE,
input [4:0] INMODE,
input MULTSIGNIN,
input [6:0] OPMODE,
input [47:0] PCIN,
input RSTA, input RSTALLCARRYIN, input RSTALUMODE, input RSTB, input RSTC, input RSTCTRL, input RSTD, input RSTINMODE, input RSTM, input RSTP,
input CEA1, input CEA2, input CEAD, input CEALUMODE, input CEB1, input CEB2, input CEC, input CECARRYIN, input CECTRL, input CED, input CEINMODE, input CEM, input CEP,
output [29:0] ACOUT,
output [17:0] BCOUT,
output CARRYCASCOUT,
output [3:0] CARRYOUT,
output MULTSIGNOUT,
output OVERFLOW,
output [47:0] P,
output PATTERNBDETECT,
output PATTERNDETECT,
output [47:0] PCOUT,
output UNDERFLOW
);
assign ACOUT = 30'd0;
assign BCOUT = 18'd0;
assign CARRYCASCOUT = 1'b0;
assign CARRYOUT = 4'd0;
assign MULTSIGNOUT = 1'b0;
assign OVERFLOW = 1'b0;
assign P = 48'd0;
assign PATTERNBDETECT = 1'b0;
assign PATTERNDETECT = 1'b0;
assign PCOUT = 48'd0;
assign UNDERFLOW = 1'b0;
endmodule