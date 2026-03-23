# riscv-tests 官方测试套件 — LAIC-CPU 适配

## 概述

使用 RISC-V 官方 [riscv-tests](https://github.com/riscv-software-src/riscv-tests)
测试你的 RV32I CPU。本目录只包含适配文件，测试源码来自官方仓库。

适配原理：用自定义 `riscv_test.h` 替换官方的 CSR/异常初始化，
改为你的 MMIO（LED/UART/tohost）接口。官方的 `test_macros.h` 完全不改。

## 文件

```
rv32i_official/
├── riscv_test.h    ← 自定义环境头文件 (替代官方 env/p/riscv_test.h)
├── link.ld         ← 链接脚本 (IMEM 0x0, DMEM 0x10000)
├── bin2mem.py      ← bin → $readmemh 转换
├── Makefile        ← 构建系统
└── README.md       ← 本文件
```

## 第一步：获取官方测试源码

```bash
cd ..
git clone https://github.com/riscv-software-src/riscv-tests.git
cd riscv-tests
git submodule update --init
cd ../rv32i_official
```

目录结构应该是：
```
├── riscv-tests/        ← 官方仓库
└── rv32i_official/     ← 本目录
```

如果 riscv-tests 不在上一级目录，修改 Makefile 中的 `RVTEST_DIR` 路径。

## 第二步：编译并运行

```bash
make run TEST=add       # 编译 ADD 指令测试
make run TEST=sb        # 编译 SB 指令测试
```

然后：
1. 拷贝 `imem.mem` 到 Vivado 仿真目录
2. `restart` → `run 50 us`
3. 观察 UART 输出

## 第三步：看结果

- `PASS` → 全部子测试通过
- `FAIL 017` → 第 17 号子测试失败

失败时打开 `riscv-tests/isa/rv64ui/<指令>.S`（rv32ui 的实际测试代码在 rv64ui 中），
找到 `test_17:` 即可看到该子测试做了什么。

## 可用测试列表 (38 个)

```bash
make list
```

| 类别 | 测试 |
|------|------|
| 基础 | simple |
| 算术 | add addi sub |
| 逻辑 | and andi or ori xor xori |
| 移位 | sll slli srl srli sra srai |
| 比较 | slt slti sltu sltiu |
| 立即数 | lui auipc |
| 跳转 | jal jalr |
| 分支 | beq bne blt bge bltu bgeu |
| Load | lb lbu lh lhu lw |
| Store | sb sh sw |
| 综合 | ld_st st_ld |

**排除的测试：**
- `fence_i` — 需要 Zifencei 扩展
- `ma_data` — 需要非对齐访问支持

## 批量编译

```bash
make all          # 编译全部 .elf
make all_mem      # 编译全部并生成各自的 .mem 文件
```

## 查看反汇编

```bash
make disasm TEST=sb
```
