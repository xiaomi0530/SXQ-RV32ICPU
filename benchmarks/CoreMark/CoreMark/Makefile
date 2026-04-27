# ===========================================================================
# Makefile - CoreMark 1.0 for RV32IM soft CPU
# ===========================================================================

TOOLCHAIN  := riscv64-unknown-elf
CC         := $(TOOLCHAIN)-gcc
OBJCOPY    := $(TOOLCHAIN)-objcopy
OBJDUMP    := $(TOOLCHAIN)-objdump
SIZE       := $(TOOLCHAIN)-size
PYTHON     ?= python3

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

# Ensure macro changes in this Makefile (e.g. HAS_FLOAT) trigger full rebuild
# to avoid ABI-mismatched mixed objects.
$(OBJS): Makefile

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
	@cp -f $< $@

$(TARGET).elf: $(CFLAGS_STAMP) $(OBJS) link.ld
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
	@echo "Fetching CoreMark source from GitHub..."
	@if [ -d coremark ] && [ -f coremark/coremark.h ]; then \
	    echo "coremark/ already exists; skip. Remove it first to re-fetch."; \
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
	    echo "CoreMark source extracted to coremark/"; \
	fi

clean:
	rm -f $(OBJS) .cflags_*
	rm -f $(TARGET).elf $(TARGET).map $(TARGET).dump imem.mem $(TARGET).mem

help:
	@echo "  make fetch  Download official CoreMark source"
	@echo "  make        Build and generate imem.mem"
	@echo "  make size   Show section sizes"
	@echo "  make dump   Generate disassembly"
	@echo "  make clean  Remove build outputs"
