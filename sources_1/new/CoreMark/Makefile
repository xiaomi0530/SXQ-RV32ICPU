# ===========================================================================
# Makefile — CoreMark 1.0 for RV32I 裸机 CPU
# ===========================================================================

TOOLCHAIN  := riscv64-unknown-elf
CC         := $(TOOLCHAIN)-gcc
OBJCOPY    := $(TOOLCHAIN)-objcopy
OBJDUMP    := $(TOOLCHAIN)-objdump
SIZE       := $(TOOLCHAIN)-size
PYTHON     := python3

ARCH_FLAGS := -march=rv32i -mabi=ilp32 -mstrict-align

CM_CFLAGS_MACRO := '"-march=rv32i -mabi=ilp32 -mstrict-align -O2"'

CFLAGS := $(ARCH_FLAGS)                              \
          -O2                                         \
          -ffreestanding                              \
          -fno-builtin                                \
          -ffunction-sections                         \
          -fdata-sections                             \
          -Wall                                       \
          -Wno-unused-parameter                       \
          -I.                                         \
          -Icoremark                                  \
          -DITERATIONS=20000                              \
          -DSEED_METHOD=SEED_VOLATILE                 \
          -DMEM_METHOD=MEM_STATIC                     \
          -DMULTITHREAD=1                             \
          -DHAS_FLOAT=0                               \
          -DHAS_TIME_H=0                              \
          -DUSE_CLOCK=0                               \
          -DHAS_STDIO=0                               \
          -DHAS_PRINTF=0                              \
          -DHAS_MEMCPY=1                              \
          -DCORE_DEBUG=0                              \
          -DVALIDATION_RUN=0                          \
          -DCOMPILER_VERSION='"riscv64-unknown-elf-gcc"' \
          -DCOMPILER_FLAGS=$(CM_CFLAGS_MACRO)         \
          -DMEM_LOCATION='"STATIC"'

TARGET  := coremark

LDFLAGS := $(ARCH_FLAGS)          \
           -T link.ld             \
           -nostartfiles          \
           -nodefaultlibs         \
           -Wl,--gc-sections      \
           -Wl,-Map=$(TARGET).map

COREMARK_SRCS := \
    coremark/core_list_join.c \
    coremark/core_main.c      \
    coremark/core_matrix.c    \
    coremark/core_state.c     \
    coremark/core_util.c

PORT_SRCS := core_portme.c
ALL_SRCS  := $(COREMARK_SRCS) $(PORT_SRCS)
OBJS      := $(ALL_SRCS:.c=.o) crt0.o

# ---------------------------------------------------------------------------
# CFLAGS 变化时自动重编所有 .o
# (注意: %.o 规则写两遍——带stamp和不带stamp各一条——是因为 make 的模式规则
#  不支持多个同级依赖覆盖，用 FORCE 配合 .PHONY 实现同样效果)
# ---------------------------------------------------------------------------
CFLAGS_HASH  := $(shell echo '$(CFLAGS)' | md5sum | cut -c1-8)
CFLAGS_STAMP := .cflags_$(CFLAGS_HASH)

.PHONY: all fetch size dump clean help FORCE

$(CFLAGS_STAMP): FORCE
	@if [ ! -f $@ ]; then \
	    echo "CFLAGS changed, removing stale objects..."; \
	    rm -f $(OBJS) .cflags_*; \
	    touch $@; \
	fi

# ===========================================================================
all: $(TARGET).mem

$(TARGET).mem: $(TARGET).elf
	$(PYTHON) gen_mem.py $< imem.mem
	@echo ""
	@echo "=============================================="
	@echo "  生成完成: imem.mem"
	@echo "  将 imem.mem 放入 Vivado 仿真/综合目录即可。"
	@echo "=============================================="

$(TARGET).elf: $(CFLAGS_STAMP) $(OBJS) link.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -lgcc
	@echo "链接完成: $@"
	@$(MAKE) --no-print-directory size

crt0.o: crt0.S
	$(CC) $(ARCH_FLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

size: $(TARGET).elf
	@echo "---------- 段大小 ----------"
	@$(SIZE) $(TARGET).elf
	@echo "IMEM 预算: 32768 字节 (.text + .data LMA)"
	@echo "DMEM 预算: 32768 字节 (.data VMA + .bss + stack)"

dump: $(TARGET).elf
	$(OBJDUMP) -d -S $(TARGET).elf > $(TARGET).dump
	@echo "反汇编 → $(TARGET).dump"

fetch:
	@echo "从 GitHub 下载 CoreMark 源码..."
	@if [ -d coremark ] && [ -f coremark/coremark.h ]; then \
	    echo "coremark/ 已存在，跳过。如需重新下载请先 rm -rf coremark/"; \
	else \
	    git clone --depth=1 https://github.com/eembc/coremark.git _cm_tmp; \
	    mkdir -p coremark; \
	    cp _cm_tmp/core_list_join.c coremark/; \
	    cp _cm_tmp/core_main.c      coremark/; \
	    cp _cm_tmp/core_matrix.c    coremark/; \
	    cp _cm_tmp/core_state.c     coremark/; \
	    cp _cm_tmp/core_util.c      coremark/; \
	    cp _cm_tmp/coremark.h       coremark/; \
	    rm -rf _cm_tmp; \
	    echo "CoreMark 源码已提取到 coremark/"; \
	fi

clean:
	rm -f $(OBJS) .cflags_*
	rm -f $(TARGET).elf $(TARGET).map $(TARGET).dump imem.mem

help:
	@echo "  make fetch  下载 CoreMark 官方源码"
	@echo "  make        编译 → imem.mem"
	@echo "  make size   检查段大小"
	@echo "  make dump   反汇编"
	@echo "  make clean  清理"
