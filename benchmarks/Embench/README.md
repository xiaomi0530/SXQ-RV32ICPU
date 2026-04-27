# Embench 接入说明

这个目录提供了一个适配当前 `RV32IM + MMIO` 平台的 `Embench` 构建入口。

当前做法：

- 将官方 `embench-iot` 的 `src/` 与 `support/` 快照放在 `upstream/embench-iot/`
- 额外补一层本地平台封装，复用当前 CPU 的：
  - `MMIO cycle counter`
  - `UART`
  - `LED`
  - `tohost`
- 输出风格与现有 `CoreMark` / `Dhrystone` 保持一致，生成 `imem.mem`

## 快速使用

列出可用 benchmark：

```sh
make list
```

构建一个 benchmark：

```sh
make BENCH=crc32
```

构建完成后会生成：

- `imem.mem`
- `imem_crc32.mem`

再例如：

```sh
make BENCH=matmult-int
make BENCH=edn
make BENCH=wikisort
```

如果要直接覆盖当前 CPU 使用的程序镜像：

```sh
make BENCH=crc32 install
```

默认会写到：

```sh
../../sources_1/new/imem.mem
```

也可以自定义目标路径：

```sh
make BENCH=crc32 install INSTALL_IMEM=../../sim/imem.mem
```

## 可调参数

- `BENCH`：选择具体 Embench case
- `GLOBAL_SCALE_FACTOR`：调节 benchmark 主体执行规模，默认 `1`
- `WARMUP_HEAT`：调节热身次数，默认 `1`

示例：

```sh
make BENCH=crc32 GLOBAL_SCALE_FACTOR=2 WARMUP_HEAT=1
```

## 当前建议

对于你这颗核，建议先挑几类代表性 workload：

- `crc32`：轻量整数/循环类
- `matmult-int`：算术密集
- `edn`：DSP 风格整数计算
- `slre`：分支与字符串处理
- `wikisort`：访存和控制混合

这样比只看 `CoreMark` 更容易判断：

- 分支预测泛化能力
- `load-use hazard` 的真实影响
- `mul/div` 长延迟对不同负载的影响
- 晚转发与控制路径优化是否只对单一程序有效

## 说明

- 这里集成的是 **Embench IoT** 的本地快照
- 目标是让它在当前工程里直接生成 `imem.mem`，便于你替换程序镜像做仿真
- 如需后续做统一跑分脚本，可以再往上包一层批量构建与结果汇总
