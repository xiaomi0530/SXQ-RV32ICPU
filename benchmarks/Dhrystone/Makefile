TOOLCHAIN := riscv64-unknown-elf
CC        := $(TOOLCHAIN)-gcc
OBJCOPY   := $(TOOLCHAIN)-objcopy
OBJDUMP   := $(TOOLCHAIN)-objdump
SIZE      := $(TOOLCHAIN)-size
ifeq ($(OS),Windows_NT)
PYTHON    ?= python
else
PYTHON    ?= python3
endif
BENCHUTIL := ../common/benchutil.py

.DEFAULT_GOAL := all

ARCH_FLAGS := -march=rv32im -mabi=ilp32 -mstrict-align

CFLAGS := $(ARCH_FLAGS)                     \
          -O2                              \
          -std=gnu89                       \
          -ffreestanding                   \
          -fno-builtin                     \
          -ffunction-sections              \
          -fdata-sections                  \
          -Wall                            \
          -Wno-implicit-int                \
          -Wno-old-style-definition        \
          -Wno-return-type                 \
          -DDHRY_HZ=100000000UL            \
          -DDHRY_MIN_CYCLES=1000000UL      \
          -I.

LDFLAGS := $(ARCH_FLAGS)               \
           -T link.ld                  \
           -nostartfiles               \
           -nodefaultlibs              \
           -Wl,--gc-sections           \
           -Wl,-Map=dhrystone.map

TARGET := dhrystone
SRCS   := dhrystone_main.c dhrystone.c dhry_port.c
OBJS   := $(SRCS:.c=.o) crt0.o

.PHONY: all clean size dump

all: imem.mem

imem.mem: $(TARGET).elf
	$(PYTHON) gen_mem.py $< $@

$(TARGET).elf: $(OBJS) link.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -lgcc
	@$(MAKE) --no-print-directory size

crt0.o: crt0.S
	$(CC) $(ARCH_FLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

size: $(TARGET).elf
	@$(SIZE) $(TARGET).elf

dump: $(TARGET).elf
	$(OBJDUMP) -d -S $(TARGET).elf > $(TARGET).dump

clean:
	$(PYTHON) $(BENCHUTIL) rm $(OBJS) $(TARGET).elf $(TARGET).map $(TARGET).dump imem.mem
