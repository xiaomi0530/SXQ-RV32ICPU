# ===========================================================================
# Makefile - CoreMark 1.0 for RV32IM soft CPU
# ===========================================================================

TOOLCHAIN  := riscv64-unknown-elf
CC         := $(TOOLCHAIN)-gcc
OBJCOPY    := $(TOOLCHAIN)-objcopy
OBJDUMP    := $(TOOLCHAIN)-objdump
SIZE       := $(TOOLCHAIN)-size
ifeq ($(OS),Windows_NT)
PYTHON     ?= python
else
PYTHON     ?= python3
endif
BENCHUTIL  := ../../common/benchutil.py

.DEFAULT_GOAL := all

ARCH_FLAGS := -march=rv32im -mabi=ilp32 -mstrict-align

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
          -DITERATIONS=5000                           \
          -DSEED_METHOD=SEED_VOLATILE                 \
          -DMEM_METHOD=MEM_STATIC                     \
          -DMULTITHREAD=1                             \
          -DHAS_FLOAT=1                               \
          -DHAS_TIME_H=0                              \
          -DUSE_CLOCK=0                               \
          -DHAS_STDIO=0                               \
          -DHAS_PRINTF=0                              \
          -DHAS_MEMCPY=1                              \
          -DCORE_DEBUG=0                              \
          -DVALIDATION_RUN=0

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

# Ensure macro changes in this Makefile trigger rebuilds.
$(OBJS): Makefile

.PHONY: all fetch size dump clean help

# ===========================================================================
all: imem.mem

# Canonical memory image for Vivado $readmemh
imem.mem: $(TARGET).elf
	$(PYTHON) gen_mem.py $< $@
	@echo ""
	@echo "=============================================="
	@echo "  Generated: $@"
	@echo "  Copy $@ into your Vivado simulation/synthesis run directory."
	@echo "=============================================="

# Backward-compatible alias target
$(TARGET).mem: imem.mem
	@$(PYTHON) $(BENCHUTIL) copy $< $@

$(TARGET).elf: $(OBJS) link.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -lgcc
	@echo "Linked: $@"
	@$(MAKE) --no-print-directory size

crt0.o: crt0.S
	$(CC) $(ARCH_FLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

size: $(TARGET).elf
	@echo "---------- Section Size ----------"
	@$(SIZE) $(TARGET).elf
	@echo "IMEM budget: 32768 bytes (.text + .data LMA)"
	@echo "DMEM budget: 32768 bytes (.data VMA + .bss + stack)"

dump: $(TARGET).elf
	$(OBJDUMP) -d -S $(TARGET).elf > $(TARGET).dump
	@echo "Disassembly: $(TARGET).dump"

fetch:
	@echo "CoreMark source is already included; fetch is not required."

clean:
	$(PYTHON) $(BENCHUTIL) rm $(OBJS) .cflags_* $(TARGET).elf $(TARGET).map $(TARGET).dump imem.mem $(TARGET).mem

help:
	@echo "  make fetch  Note that CoreMark source is already included"
	@echo "  make        Build and generate imem.mem"
	@echo "  make size   Show section sizes"
	@echo "  make dump   Generate disassembly"
	@echo "  make clean  Remove build outputs"
