# SXQ-RV32I-CPU
Board: xc7a100tcsg324-1 (Artix-7)


***Version 3.12*** || CoreMark = **000.0 Iterations / sec** || **100MHz** || WNS **0.894ns** WHS **0.105ns** \
***Version 3.17*** || CoreMark = **000.0 Iterations / sec** || **100MHz** || WNS **0.977ns** WHS **0.141ns** \
***Version 3.22*** || CoreMark = **091.1 Iterations / sec** || **100MHz** || WNS **1.015ns** WHS **0.310ns** || LUT: **1775**

***Version 3.23*** || CoreMark = **209.6 Iterations / sec** || **100MHz** || WNS **0.789ns** WHS **0.053ns** || LUT: **2404**\
———CoreMark 1.0 : 209.575247 / riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -mstrict-align -mno-div -O2 / STATIC\
———1. 增加基于 DSP48E1 的乘法器。2. 增加带有 128 深度 FIFO 的 UART_TX。3. 修正 CoreMark 移植程序。
***Version 3.29*** || CoreMark = **209.6 Iterations / sec** || **100MHz** || WNS **0.930ns** WHS **0.022ns** || LUT: **2078**\
———1. 增加 preif 逻辑，动态调节流水线深度，使得在 IF 阶段便可取得 instruction。2. 优化时序，将 WNS 拉回 0.930ns。
***Version 4.03*** || CoreMark = **222.6 Iterations / sec** || **100MHz** || WNS **0.637ns** WHS **0.086ns** || LUT: **2017**\
———1. 将 MEM 阶段的信号输入不经过寄存器打拍，直接从 EX 连线，使得读写操作在 MEM 阶段可以完成，更改 pipeline stall 机制以适配。2. 优化时序。
***Version 4.08*** || CoreMark = **249.4 Iterations / sec** || **100MHz** || WNS **0.712ns** WHS **0.045ns** || LUT: **2785**\
———1. 新增 Bimodal 分支预测（Entry = 16，Index = 4 bits）。2. 优化时序。
***Version 4.10*** || CoreMark = **259.2 Iterations / sec** || **100MHz** || WNS **0.119ns** WHS **0.075ns** || LUT: **3257**\
———1. 优化分支预测。2. 加入跳转预测。具体改动较多，仍在持续优化中，此版本仅为 git 暂存版。
***Version 4.16*** || CoreMark = **265.6 Iterations / sec** || **100MHz** || WNS **0.025ns** WHS **0.066ns** || LUT: **2632**\
———1. 修正分支预测与预取机制。2. 时序优化。3. 将 mul 的操作数输入提前一个周期（至 ID 阶段）。
***Version 4.21*** || CoreMark = **267.7 Iterations / sec** || **100MHz** || WNS **0.024ns** WHS **0.084ns** || LUT: **3247**\
———1. 增加 RV32IM 低频使用场景友好的多拍迭代除法器，支持 DIV / DIVU / REM / REMU，尽量避免对主频与 LUT 造成额外压力。2. 将 Bimodal Branch Predictor 表项扩展到 64 项（Index = 6 bits）。3. 将分支预测相关配置宏统一收敛到 defines.v，并删除 branch_predictor_cfg.vh。