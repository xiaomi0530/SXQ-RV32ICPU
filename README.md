# SXQ-RV32IM-CPU
Board: `xc7a100tcsg324-1` (Artix-7)

***Version 3.12*** || CoreMark = **000.0 Iterations / sec** || **100MHz** || WNS **0.894ns** WHS **0.105ns** \
***Version 3.17*** || CoreMark = **000.0 Iterations / sec** || **100MHz** || WNS **0.977ns** WHS **0.141ns** \
***Version 3.22*** || CoreMark = **091.1 Iterations / sec** || **100MHz** || WNS **1.015ns** WHS **0.310ns** || LUT: **1775**

***Version 3.23*** || CoreMark = **209.6 Iterations / sec** || **100MHz** || WNS **0.789ns** WHS **0.053ns** || LUT: **2404** \
- CoreMark 1.0 首次稳定跑通，并引入基于 `DSP48E1` 的乘法器与 `UART_TX`。

***Version 3.29*** || CoreMark = **209.6 Iterations / sec** || **100MHz** || WNS **0.930ns** WHS **0.022ns** || LUT: **2078** \
- 增加 `preif` 逻辑，利用压缩前端机制在 IF 阶段更早拿到指令，并同步做了一轮时序优化。

***Version 4.03*** || CoreMark = **222.6 Iterations / sec** || **100MHz** || WNS **0.637ns** WHS **0.086ns** || LUT: **2017** \
- 调整访存相关路径，使部分读写操作在 MEM 阶段即可完成，并重整相应的 `pipeline stall` 机制。

***Version 4.08*** || CoreMark = **249.4 Iterations / sec** || **100MHz** || WNS **0.712ns** WHS **0.045ns** || LUT: **2785** \
- 新增 `Bimodal Branch Predictor`（`Entry = 16`，`Index = 4 bits`），继续优化前端时序。

***Version 4.10*** || CoreMark = **259.2 Iterations / sec** || **100MHz** || WNS **0.119ns** WHS **0.075ns** || LUT: **3257** \
- 继续优化分支预测，并加入跳转预测；此版本主要用于功能验证与阶段性收敛。

***Version 4.16*** || CoreMark = **265.6 Iterations / sec** || **100MHz** || WNS **0.025ns** WHS **0.066ns** || LUT: **2632** \
- 修正分支预测与预取机制，并将 `mul` 的部分操作数准备前移到 ID 阶段。

***Version 4.21*** || CoreMark = **267.7 Iterations / sec** || **100MHz** || WNS **0.024ns** WHS **0.084ns** || LUT: **3247** \
- 增加面向 `RV32IM` 的多拍迭代除法器，支持 `DIV / DIVU / REM / REMU`；同时将 `Bimodal Branch Predictor` 扩展到 `64` 项，并把相关配置统一收敛到 `defines.v`。

***Version 4.26*** || CoreMark = **275.9 Iterations / sec** || **100MHz** || WNS **0.050ns** WHS **0.142ns** || LUT: **3581** || FF: **2741** || BRAM: **16** || DSP: **4** \
- 拆分并模块化控制路径，新增 ctrl_late_detect 与 mem_ctrl_resolve，整理前后级控制接口。
- 加入只针对 J/B 控制指令的晚转发：当分支或 JALR 依赖前一条 LOAD 结果时，在 ID 标记 defer，并将比较、方向判定与 JALR 目标计算后移到 MEM 完成。
- 当前 benchmark 结果：`CoreMark = 275.921925 Iter/s`，`Dhrystone = 166000 Dhrystones/s`，`Embench-WikiSort = 122.58`。
- 当前 `CoreMark` 正式配置使用 `-march=rv32im -mabi=ilp32 -mstrict-align -O2`，并按硬件 `RV32IM` 路径运行。

## CoreMark Trend
```mermaid
---
config:
  theme: base
  xyChart:
    width: 960
    height: 420
    showDataLabel: true
    showDataLabelOutsideBar: true
  themeVariables:
    background: "#ffffff"
    textColor: "#111827"
    xyChart:
      plotColorPalette: "transparent, #1d4ed8"
      dataLabelColor: "#0f172a"
---
xychart-beta
    title "CoreMark Trend"
    x-axis ["3.12","3.17","3.22","3.23","3.29","4.03","4.08","4.10","4.16","4.21","4.26"]
    y-axis "Iterations / sec" 0 --> 285
    bar [0.0,0.0,91.1,209.6,209.6,222.6,249.4,259.2,265.6,267.7,275.9]
    line [0.0,0.0,91.1,209.6,209.6,222.6,249.4,259.2,265.6,267.7,275.9]
```

## Version 4.26 Summary
### CPU Architecture
![4.26 CPU Architecture](docs/figures/sxqcpu_architecture.png)
### Benchmark Summary

Raw logs: `docs/benchmark_raw_results.md`

| Benchmark | Build Flags / Config | Score | IPC | Cycles (`C`) | Instret (`I`) | Extra |
| --- | --- | --- | --- | ---: | ---: | --- |
| CoreMark | `-march=rv32im -mabi=ilp32 -mstrict-align -O2` ; `ITERATIONS=5000` | `275.921925 Iter/s` | `0.851` | `362458` | `308288` | `18.121068 s`, valid run |
| Dhrystone | `-march=rv32im -mabi=ilp32 -mstrict-align -O2 -std=gnu89` ; `DHRY_HZ=100000000` ; `1800 runs` | `166000 Dhrystones/s` | `0.907` | `1081810` | `980993` | `6 us/run`, `0.945 DMIPS/MHz` |
| Embench-WikiSort | `-march=rv32im -mabi=ilp32 -mstrict-align -O2 -std=gnu11` ; `GLOBAL_SCALE_FACTOR=1` ; `WARMUP_HEAT=1` | `122.58` | `0.786` | `2965138` | `2330989` | `WS V=1` |

| Item | Value |
| --- | --- |
| FPGA Device | xc7a100tcsg324-1 |
| Clock | 100MHz |
| CoreMark | 275.921925 Iterations / sec |
| Dhrystone | 166000 Dhrystones / sec |
| Embench-WikiSort | 122.58 |
| DMIPS/MHz | 0.945 |
| WNS / WHS | 0.050ns / 0.142ns |
| LUT / FF / BRAM / DSP | 3581 / 2741 / 16 / 4 |
