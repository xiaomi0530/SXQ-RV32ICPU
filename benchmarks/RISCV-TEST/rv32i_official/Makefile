# ==============================================================================
# Makefile - build riscv-tests rv32ui + rv32um cases
#
# Usage:
#   make run TEST=add
#   make run TEST=mul
#   make list
#   make clean
# ==============================================================================

RVTEST_DIR ?= ../riscv-tests

CROSS_COMPILE ?= riscv64-unknown-elf-
CC      := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
ifeq ($(OS),Windows_NT)
PYTHON  ?= python
else
PYTHON  ?= python3
endif
BENCHUTIL := ../../common/benchutil.py

ABI  := ilp32

INCLUDES := \
    -I. \
    -I$(RVTEST_DIR)/isa/macros/scalar \
    -I$(RVTEST_DIR)/env/p

M_TESTS := mul mulh mulhsu mulhu div divu rem remu

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
	@echo ==========================================
	@echo riscv-tests RV32I and RV32M builder
	@echo ==========================================
	@echo Usage
	@echo make run TEST=add - build RV32I test and generate imem.mem
	@echo make run TEST=mul - build RV32M test and generate imem.mem
	@echo make sim TEST=mul - build and copy imem.mem to SIM_DIR
	@echo make list - list available tests
	@echo make disasm TEST=mul - print disassembly
	@echo make clean - remove build outputs

.PHONY: list
list:
	@echo RV32I tests - $(words $(I_TESTS)) cases
	@echo $(I_TESTS)
	@echo RV32M tests - $(words $(M_TESTS)) cases
	@echo $(M_TESTS)

$(addsuffix .elf, $(M_TESTS)): %.elf: $(RVTEST_DIR)/isa/rv32um/%.S riscv_test.h link.ld
	$(CC) -march=rv32im -mabi=$(ABI) $(INCLUDES) -T link.ld -nostdlib -Wl,--gc-sections $< -o $@

$(addsuffix .elf, $(I_TESTS)): %.elf: $(RVTEST_DIR)/isa/rv32ui/%.S riscv_test.h link.ld
	$(CC) -march=rv32i -mabi=$(ABI) $(INCLUDES) -T link.ld -nostdlib -Wl,--gc-sections $< -o $@

.PHONY: run
run:
ifndef TEST
	@echo "ERROR: TEST is required, for example: make run TEST=mul"
	@exit 1
endif
	$(MAKE) $(TEST).elf
	$(OBJCOPY) -O binary $(TEST).elf $(TEST).bin
	$(PYTHON) bin2mem.py $(TEST).bin imem.mem 4096
	@echo ========================================
	@echo OK - imem.mem generated for TEST=$(TEST)
	@echo ========================================

.PHONY: sim
sim:
ifndef TEST
	@echo "ERROR: TEST is required, for example: make sim TEST=mul"
	@exit 1
endif
	$(MAKE) run TEST=$(TEST)
	$(PYTHON) $(BENCHUTIL) copy imem.mem $(SIM_DIR)/imem.mem
	@echo Copied imem.mem to $(SIM_DIR)/imem.mem
	@echo In Vivado simulation run restart then run 50 us

.PHONY: disasm
disasm:
ifndef TEST
	@echo "ERROR: TEST is required"
	@exit 1
endif
	$(MAKE) $(TEST).elf
	$(OBJDUMP) -d $(TEST).elf

.PHONY: all
all: $(addsuffix .elf, $(TESTS))
	@echo Built $(words $(TESTS)) tests.

.PHONY: clean
clean:
	$(PYTHON) $(BENCHUTIL) rm *.elf *.bin *.mem *.o
