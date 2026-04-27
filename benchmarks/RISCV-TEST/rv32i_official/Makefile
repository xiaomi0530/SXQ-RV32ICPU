# ==============================================================================
# Makefile — 编译 riscv-tests 官方 rv32ui + rv32um 测试
#
# 用法:
#   make run TEST=add       # RV32I 测试
#   make run TEST=mul       # RV32M 测试 (自动检测)
#   make run TEST=rem       # RV32M 测试
#   make list               # 列出所有可用测试
#   make clean
# ==============================================================================

RVTEST_DIR ?= ../riscv-tests

CROSS_COMPILE ?= riscv64-unknown-elf-
CC      := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
PYTHON  ?= python3

ABI  := ilp32

INCLUDES := \
    -I. \
    -I$(RVTEST_DIR)/isa/macros/scalar \
    -I$(RVTEST_DIR)/env/p

# rv32um 测试列表
M_TESTS := mul mulh mulhsu mulhu div divu rem remu

# rv32ui 测试列表
I_TESTS := \
    simple \
    add addi sub \
    and andi or ori xor xori \
    sll slli srl srli sra srai \
    slt slti sltu sltiu \
    lui auipc \
    jal jalr \
    beq bne blt bge bltu bgeu \
    lb lbu lh lhu lw \
    sb sh sw \
    ld_st st_ld

TESTS := $(I_TESTS) $(M_TESTS)

SIM_DIR ?= /mnt/hgfs/xsim

# ==============================================================================

.PHONY: help
help:
	@echo "=========================================="
	@echo " riscv-tests 官方 RV32I + RV32M 测试"
	@echo "=========================================="
	@echo ""
	@echo "用法:"
	@echo "  make run TEST=add     RV32I 测试"
	@echo "  make run TEST=mul     RV32M 测试"
	@echo "  make run TEST=rem     RV32M 测试"
	@echo "  make sim TEST=mul     编译+自动拷贝到仿真目录"
	@echo "  make list             列出所有测试"
	@echo "  make disasm TEST=mul  查看反汇编"
	@echo "  make clean"

.PHONY: list
list:
	@echo "=== RV32I 测试 ($(words $(I_TESTS)) 个) ==="
	@for t in $(I_TESTS); do echo "  $$t"; done
	@echo ""
	@echo "=== RV32M 测试 ($(words $(M_TESTS)) 个) ==="
	@for t in $(M_TESTS); do echo "  $$t"; done

# ---- rv32um 测试: 用 rv32im, 源码在 rv32um/ ----
$(addsuffix .elf, $(M_TESTS)): %.elf: $(RVTEST_DIR)/isa/rv32um/%.S riscv_test.h link.ld
	$(CC) -march=rv32im -mabi=$(ABI) $(INCLUDES) -T link.ld -nostdlib -Wl,--gc-sections $< -o $@

# ---- rv32ui 测试: 用 rv32i, 源码在 rv32ui/ ----
$(addsuffix .elf, $(I_TESTS)): %.elf: $(RVTEST_DIR)/isa/rv32ui/%.S riscv_test.h link.ld
	$(CC) -march=rv32i -mabi=$(ABI) $(INCLUDES) -T link.ld -nostdlib -Wl,--gc-sections $< -o $@

# ---- 编译并生成 imem.mem ----
.PHONY: run
run:
ifndef TEST
	@echo "ERROR: 请指定 TEST, 例如: make run TEST=mul"
	@exit 1
endif
	$(MAKE) $(TEST).elf
	$(OBJCOPY) -O binary $(TEST).elf $(TEST).bin
	$(PYTHON) bin2mem.py $(TEST).bin imem.mem 4096
	@echo ""
	@echo "========================================"
	@echo " OK! imem.mem 已生成 ($(TEST))"
	@echo "========================================"

# ---- 编译+拷贝到仿真目录 ----
.PHONY: sim
sim:
ifndef TEST
	@echo "ERROR: 请指定 TEST, 例如: make sim TEST=mul"
	@exit 1
endif
	$(MAKE) run TEST=$(TEST)
	cp imem.mem $(SIM_DIR)/imem.mem
	@echo "已同步, Vivado 中执行: restart; run 50 us"

# ---- 反汇编 ----
.PHONY: disasm
disasm:
ifndef TEST
	@echo "ERROR: 请指定 TEST"
	@exit 1
endif
	$(MAKE) $(TEST).elf
	$(OBJDUMP) -d $(TEST).elf

# ---- 编译全部 ----
.PHONY: all
all: $(addsuffix .elf, $(TESTS))
	@echo "全部 $(words $(TESTS)) 个测试编译完成"

# ---- 清理 ----
.PHONY: clean
clean:
	rm -f *.elf *.bin *.mem *.o
