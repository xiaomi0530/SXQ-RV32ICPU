# RV32M 乘法指令逻辑与时序实现分析

## 1. 分析范围与源码入口

本分析只针对当前工程中与乘法指令(`MUL/MULH/MULHSU/MULHU`)相关的路径，覆盖以下模块：

- `sources_1/new/id.v`：RV32M 乘法指令译码、`alu_op` 生成
- `sources_1/new/id_ex.v`：ID/EX 流水寄存器，`stall/hold/flush` 行为
- `sources_1/new/ex.v`：EX 级乘法启动、忙信号生成、结果选择
- `sources_1/new/mul_unit.v`：DSP48E1 乘法器实现、`ready` 时序
- `sources_1/new/cpu.v`：全局 `pipeline_hold`/`pipeline_block` 接线与冻结范围
- `sources_1/new/ex_mem.v`：EX/MEM 在 `pipeline_hold` 下的冻结行为
- `sources_1/new/forwarding.v`、`sources_1/new/pipeline_stall.v`：相关旁路与停顿逻辑

---

## 2. 指令译码与 ALU 操作码映射

### 2.1 译码条件（ID 级）

在 `id.v` 中：

- `rv32m_any = type_r && (funct7 == 7'b0000001)`
- `rv32m_mul = rv32m_any && (funct3[2] == 1'b0)`

含义：

- 仅当 `opcode=0110011`（R-type）且 `funct7=0000001` 才进入 RV32M 族
- 再用 `funct3[2]==0`筛选出 4 条乘法指令（`000~011`）

### 2.2 ALU_OP 编码

`id.v` 的映射如下：

- `MUL    -> ALU_OP_MUL    = 4'b1001`
- `MULH   -> ALU_OP_MULH   = 4'b1010`
- `MULHSU -> ALU_OP_MULHSU = 4'b1011`
- `MULHU  -> ALU_OP_MULHU  = 4'b1111`

同时注意：

- `rv32m_any` 但不属于上述 4 条（即 `DIV/REM` 族）会进入 `alu_op=4'b0000` 分支。
- 当前实现没有 `illegal instruction` trap 机制，因此 `DIV/REM` 不会被正确执行（这是实现边界，不是乘法路径本身问题）。

---

## 3. EX 级乘法控制逻辑

在 `ex.v` 中，乘法控制由以下信号构成：

- `is_mul/is_mulh/is_mulhsu/is_mulhu`：按 `ex_alu_op` 分类
- `mul_op`：四类乘法指令总使能
- `mul_inflight`：本条乘法是否处于“已发起未完成”状态
- `mul_start = mul_op && !mul_inflight`：一次乘法事务的启动脉冲条件
- `mul_ready`：来自 `mul_unit` 的完成脉冲

状态更新：

- `mul_start` 时：`mul_inflight <= 1`
- `mul_ready` 时：`mul_inflight <= 0`

流水冻结条件：

- `mul_hold = mul_start | (mul_inflight && !mul_ready)`
- `ex_mul_busy = mul_hold`

即：

- 启动当拍就冻结
- 计算期间持续冻结
- `ready` 到来的那拍释放冻结（组合上 `mul_inflight && !mul_ready` 变为 0）

---

## 4. 乘法签名（有符号/无符号）选择

`ex.v` 对输入符号位的控制：

- `signed_a = is_mul | is_mulh | is_mulhsu`
- `signed_b = is_mul | is_mulh`

对应 ISA 语义：

- `MUL`：A signed, B signed（低 32 位结果）
- `MULH`：A signed, B signed（高 32 位结果）
- `MULHSU`：A signed, B unsigned（高 32 位结果）
- `MULHU`：A unsigned, B unsigned（高 32 位结果）

结果选择：

- `MUL` 取 `mul_result[31:0]`
- `MULH/MULHSU/MULHU` 取 `mul_result[63:32]`

---

## 5. mul_unit 微结构实现（DSP48E1）

### 5.1 算法拆分

`mul_unit.v` 采用 32x32 -> 64 的分块乘法：

- `A = A_hi*2^16 + A_lo`
- `B = B_hi*2^16 + B_lo`

其中：

- `A_hi/B_hi` 为 17 位（按 signed_a/signed_b 决定是否符号扩展）
- `A_lo/B_lo` 为 17 位零扩展

并行计算 4 个 17x17 部分积：

- `pp_ll = A_lo * B_lo`
- `pp_lh = A_lo * B_hi`
- `pp_hl = A_hi * B_lo`
- `pp_hh = A_hi * B_hi`

最终组合：

- `product = pp_ll + (pp_lh<<16) + (pp_hl<<16) + (pp_hh<<32)`

### 5.2 DSP48E1 配置

`dsp_mul_17x17` 的关键寄存器配置：

- `AREG=1`, `BREG=1`, `MREG=1`, `PREG=1`
- `USE_MULT="MULTIPLY"`
- `OPMODE=7'b0000101`

每个部分积都通过 DSP 内部流水寄存。

### 5.3 延迟控制

模块内显式参数：

- `MUL_LATENCY = 3`

控制器行为：

- `start_en` 拉高后，`busy=1, latency_cnt=2`
- 每拍递减，`cnt==0` 时 `ready=1`（单拍脉冲）

> 实现假设 DSP 路径与 `MUL_LATENCY=3` 一致；若后续修改 DSP 寄存器级数，必须同步调整 `MUL_LATENCY`，否则 `ready` 与有效结果可能错拍。

---

## 6. 乘法指令在流水线中的拍级时序

下面给出“单条 MUL 进入 EX 后”的典型时序（`t0` 为该条指令首次处于 EX 组合逻辑的周期）：

| 周期 | 关键组合信号 | 关键时序动作 | 备注 |
|---|---|---|---|
| `t0` | `mul_start=1`, `mul_hold=1` | 下个上升沿发起乘法 | 当拍立即冻结前级 |
| `t1` | `mul_inflight=1`, `mul_ready=0`, `mul_hold=1` | 计数递减 | 持续冻结 |
| `t2` | `mul_hold=1` | 计数递减 | 持续冻结 |
| `t3` | `mul_hold=1` | 计数递减到 0 | 持续冻结 |
| `t4` | `mul_ready=1`（单拍），`mul_hold` 释放 | 乘法结果有效 | 此后流水可恢复推进 |
| `t5` | `mul_inflight` 清零 | 下一条指令可正常启动 | 事务结束 |

结论：

- 该实现使乘法指令在 EX 级占用多拍，形成全流水冻结窗口。
- 相对于 1-cycle ALU 指令，乘法会引入显著气泡（经验上约 +3 拍额外停顿）。

---

## 7. 全局冻结传播路径

`cpu.v` 中：

- `pipeline_hold = ex_mul_busy`
- `pipeline_block = pipeline_stall | pipeline_hold`

冻结影响范围：

1. IF 级
- `pc.v` 在 `pipeline_stall`（这里接的是 `pipeline_block`）时保持 `pc_o`
- `imem.v` 在 `pipeline_stall`（同样接 `pipeline_block`）时保持 `instr_o/instr_addr_o`

2. ID/EX
- `id_ex.v`：
  - `pipeline_hold=1` 时，数据与控制均保持（不前推）
  - `pipeline_stall=1` 时，控制位被清零插泡（优先级高于 hold）

3. EX/MEM
- `ex_mem.v`：`pipeline_hold=1` 时，所有 EX->MEM 输出保持

---

## 8. 旁路与停顿对乘法的影响

### 8.1 前递

`forwarding.v` 的优先级：

- EX 优先
- 其次 MEM
- 再次 WB

对 MUL 来说：

- 结果在 EX 端通过 `ex_regs_w_data` 输出；恢复流水后可被正常前递。

### 8.2 load-use 停顿

`pipeline_stall.v` 只针对 load 相关冲突：

- `ex_dmem_re` 或 `mem_dmem_re` 命中 ID 的 `rs1/rs2` 才停顿。
- 乘法本身不是 `dmem_re`，因此不会被该单元直接识别为 hazard 源。

---

## 9. 与乘法实现直接相关的时序/行为风险点（当前版本）

以下为“乘法多拍冻结机制”带来的实现级风险，建议重点验证：

### 9.1 EX/MEM 冻结导致 MEM 级事务保持

`ex_mem.v` 在 `pipeline_hold=1` 时保持 `mem_dmem_we/re/addr/data`。

可能后果：

- 若 MUL 后面（更老指令）MEM 级正好是一次 load/store，则该事务信号会在 hold 窗口内保持多拍。
- 在当前总线/存储实现下，这可能表现为“同一访问被重复发起”。
- 对普通 RAM 写同值通常无害，但对 MMIO（有副作用）需谨慎。

### 9.2 `id_ex` 中 `pipeline_stall` 优先于 `pipeline_hold`

`id_ex.v` 控制寄存器更新顺序是：

1. reset/flush
2. `pipeline_stall` -> 清零控制位
3. `!pipeline_hold` -> 正常更新

因此在某些“`stall` 与 `hold` 同时为 1”的窗口，可能出现控制位被清零而数据位保持的组合状态，需要做定向仿真验证（尤其是 MUL 与前后 load 交织时）。

### 9.3 `MUL_LATENCY` 与 DSP 实际流水级耦合

- 乘法 ready 逻辑是手工计数，并非来自 DSP 有效位。
- 任何 DSP 参数（`AREG/BREG/MREG/PREG`）变化，都可能打破 ready 与结果对齐。

---

## 10. 建议的仿真观测点（针对乘法路径）

建议在 testbench 中至少抓以下信号波形：

- EX 控制：`ex_alu_op`, `mul_start`, `mul_inflight`, `mul_ready`, `ex_mul_busy`
- 流水冻结：`pipeline_hold`, `pipeline_block`, `id_ex.*`, `ex_mem.*`
- 乘法结果：`mul_result`, `ex_regs_w_data`, `wb_actual_regs_w_data`
- 访存副作用：`mem_dmem_we`, `mem_dmem_re`, `bus_m_stb`, `bus_m_addr`

推荐覆盖场景：

1. 单条 `MUL/MULH/MULHSU/MULHU` 与软件黄金模型比对
2. 背靠背乘法序列
3. `load -> mul -> use` 与 `mul -> load -> use`
4. `store/mmio_write` 与 `mul` 相邻排列，检查是否重复访存
5. `branch` 与 `mul` 邻接，观察 `flush + hold` 交互

---

## 11. 结论

当前实现已经具备：

- 完整 4 条 RV32M 乘法指令译码
- 基于 4xDSP48E1 的 32x32 乘法硬件
- 有符号/无符号组合正确分流
- 多拍 busy/ready 与全流水冻结机制

同时，乘法相关时序正确性不仅取决于 `mul_unit` 本身，还强依赖：

- `hold` 在全流水的传播粒度
- `stall/hold` 优先级策略
- MEM 级在 hold 时的副作用控制

因此，后续优化重点应围绕“冻结窗口内 MEM/控制信号行为”与“ready 对齐鲁棒性”进行系统验证。