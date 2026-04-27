TOOLCHAIN := riscv64-unknown-elf
CC        := $(TOOLCHAIN)-gcc
OBJDUMP   := $(TOOLCHAIN)-objdump
SIZE      := $(TOOLCHAIN)-size
PYTHON    ?= python
PS        := powershell -NoProfile -Command

.DEFAULT_GOAL := all

ARCH_FLAGS := -march=rv32im -mabi=ilp32 -mstrict-align

EMBENCH_ROOT        := upstream/embench-iot
BENCH               ?= crc32
GLOBAL_SCALE_FACTOR ?= 1
WARMUP_HEAT         ?= 1
INSTALL_IMEM        ?= ../../sources_1/new/imem.mem

EMBENCH_CPU_FREQ_HZ  ?= 100000000UL
EMBENCH_CPU_FREQ_MHZ ?= 100UL

ifeq ($(BENCH),crc32)
BASELINE_MS := 4006UL
endif
ifeq ($(BENCH),matmult-int)
BASELINE_MS := 4010UL
endif
ifeq ($(BENCH),slre)
BASELINE_MS := 3995UL
endif
ifeq ($(BENCH),edn)
BASELINE_MS := 4006UL
endif
ifeq ($(BENCH),wikisort)
BASELINE_MS := 3622UL
endif
BASELINE_MS ?= 0UL

BENCH_DIR := $(EMBENCH_ROOT)/src/$(BENCH)
TARGET    := embench_$(BENCH)
OBJDIR    := build/$(BENCH)

BENCH_SRCS := $(wildcard $(BENCH_DIR)/*.c)
PORT_SRCS  := \
	platform/main.c \
	platform/boardsupport.c \
	$(EMBENCH_ROOT)/support/beebsc.c

ALL_SRCS := $(BENCH_SRCS) $(PORT_SRCS)
OBJS     := $(patsubst %.c,$(OBJDIR)/%.o,$(ALL_SRCS))

ifeq ($(strip $(BENCH_SRCS)),)
$(error Unknown BENCH='$(BENCH)'. Use 'make list' to see available Embench cases)
endif

CFLAGS := $(ARCH_FLAGS)                         \
          -O2                                   \
          -std=gnu11                            \
          -ffreestanding                        \
          -fno-builtin                          \
          -ffunction-sections                   \
          -fdata-sections                       \
          -Wall                                 \
          -Wno-unused-parameter                 \
          -Wno-sign-compare                     \
          -Wno-parentheses                      \
          -Wno-return-type                      \
          -Wno-unused-function                  \
          -DHAVE_CONFIG_H                       \
          -Iplatform                            \
          -I$(EMBENCH_ROOT)/support             \
          -I$(BENCH_DIR)                        \
          -DGLOBAL_SCALE_FACTOR=$(GLOBAL_SCALE_FACTOR) \
          -DWARMUP_HEAT=$(WARMUP_HEAT)          \
          -DEMBENCH_BENCH_NAME=\"$(BENCH)\"     \
          -DEMBENCH_BASELINE_MS=$(BASELINE_MS)  \
          -DEMBENCH_CPU_FREQ_HZ=$(EMBENCH_CPU_FREQ_HZ) \
          -DEMBENCH_CPU_FREQ_MHZ=$(EMBENCH_CPU_FREQ_MHZ)

LDFLAGS := $(ARCH_FLAGS)        \
           -T link.ld           \
           -nostartfiles        \
           -nodefaultlibs       \
           -Wl,--gc-sections    \
           -Wl,-Map=$(TARGET).map

.PHONY: all clean size dump list install help

all: imem.mem

imem.mem: $(TARGET).elf
	$(PYTHON) gen_mem.py $< $@
	@$(PS) "Copy-Item 'imem.mem' 'imem_$(BENCH).mem' -Force"
	@echo ""
	@echo "=============================================="
	@echo "  Generated: imem.mem"
	@echo "  Saved copy: imem_$(BENCH).mem"
	@echo "  BENCH=$(BENCH)"
	@echo "=============================================="

$(TARGET).elf: $(OBJS) crt0.o link.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) crt0.o -lgcc
	@$(MAKE) --no-print-directory size

crt0.o: crt0.S
	$(CC) $(ARCH_FLAGS) -c -o $@ $<

$(OBJDIR)/%.o: %.c
	@$(PS) "New-Item -ItemType Directory -Force -Path '$(dir $@)' | Out-Null"
	$(CC) $(CFLAGS) -c -o $@ $<

size: $(TARGET).elf
	@echo "---------- Section Size ----------"
	@$(SIZE) $(TARGET).elf

dump: $(TARGET).elf
	$(OBJDUMP) -d -S $(TARGET).elf > $(TARGET).dump

list:
	@$(PS) "Write-Output 'Available Embench cases:'; Get-ChildItem '$(EMBENCH_ROOT)/src' -Directory | ForEach-Object { '  ' + $$_.Name }"

install: imem.mem
	@$(PS) "Copy-Item 'imem.mem' '$(INSTALL_IMEM)' -Force"
	@echo "Installed imem.mem -> $(INSTALL_IMEM)"

clean:
	@$(PS) "if (Test-Path 'build') { Remove-Item 'build' -Recurse -Force }"
	@$(PS) "$$files = 'crt0.o','$(TARGET).elf','$(TARGET).map','$(TARGET).dump','imem.mem'; foreach ($$f in $$files) { if (Test-Path $$f) { Remove-Item $$f -Force } }; Get-ChildItem 'imem_*.mem' -ErrorAction SilentlyContinue | Remove-Item -Force"

help:
	@echo "  make BENCH=crc32            Build one Embench benchmark"
	@echo "  make list                   Show available benchmark names"
	@echo "  make BENCH=matmult-int      Build another benchmark"
	@echo "  make BENCH=crc32 install    Copy imem.mem into CPU image path"
	@echo "  make GLOBAL_SCALE_FACTOR=2  Adjust Embench run scale"
