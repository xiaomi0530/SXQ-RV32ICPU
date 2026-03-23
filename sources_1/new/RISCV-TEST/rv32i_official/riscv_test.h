// riscv_test.h — 替换官方 env/p/riscv_test.h
// 适配 LAIC-CPU (RV32I/RV32IM, 无 CSR/异常/中断)
// 启动时自动拷贝 .data 并清零 .bss

#ifndef _ENV_PHYSICAL_SINGLE_CORE_H
#define _ENV_PHYSICAL_SINGLE_CORE_H

#define TESTNUM gp

#ifndef __riscv_xlen
#define __riscv_xlen 32
#endif

#define RVTEST_RV32U                                                    \
  .macro init;                                                          \
  .endm

#define RVTEST_RV64U                                                    \
  .macro init;                                                          \
  .endm

//-----------------------------------------------------------------------
// RVTEST_CODE_BEGIN — 程序入口
// 包含 .data 拷贝 (IMEM→DMEM) 和 .bss 清零
//-----------------------------------------------------------------------

#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .align  2;                                                      \
        .globl _start;                                                  \
_start:                                                                 \
        la   sp, _stack_top;                                            \
        /* ---- 拷贝 .data: IMEM(LMA) → DMEM(VMA) ---- */              \
        la   a0, _data_start;                                          \
        la   a1, _data_lma;                                            \
        la   a2, _data_end;                                            \
        beq  a0, a2, _skip_data_copy;                                  \
_copy_data:                                                             \
        lw   a3, 0(a1);                                                \
        sw   a3, 0(a0);                                                \
        addi a0, a0, 4;                                                \
        addi a1, a1, 4;                                                \
        blt  a0, a2, _copy_data;                                       \
_skip_data_copy:                                                        \
        /* ---- 清零 .bss ---- */                                       \
        la   a0, _bss_start;                                           \
        la   a1, _bss_end;                                             \
        beq  a0, a1, _skip_bss_clear;                                  \
_clear_bss:                                                             \
        sw   zero, 0(a0);                                              \
        addi a0, a0, 4;                                                \
        blt  a0, a1, _clear_bss;                                       \
_skip_bss_clear:                                                        \
        /* ---- 初始化 TESTNUM ---- */                                   \
        li   TESTNUM, 0;                                               \
        init;                                                           \

//-----------------------------------------------------------------------
// RVTEST_CODE_END
//-----------------------------------------------------------------------

#define RVTEST_CODE_END                                                 \
        unimp

//-----------------------------------------------------------------------
// RVTEST_PASS
//-----------------------------------------------------------------------

#define RVTEST_PASS                                                     \
        li   t0, 0xF000000C;                                           \
        sw   zero, 0(t0);                                              \
        li   t1, 0xF0000010;                                           \
        li   t2, 'P'; sw t2, 0(t1);                                   \
        li   t2, 'A'; sw t2, 0(t1);                                   \
        li   t2, 'S'; sw t2, 0(t1);                                   \
        li   t2, 'S'; sw t2, 0(t1);                                   \
        li   t2, '\n'; sw t2, 0(t1);                                  \
        li   t0, 0xF0000008;                                           \
        li   t1, 1;                                                    \
        sw   t1, 0(t0);                                                \
1:      j    1b;

//-----------------------------------------------------------------------
// RVTEST_FAIL
//-----------------------------------------------------------------------

#define RVTEST_FAIL                                                     \
        li   t0, 0xF000000C;                                           \
        sw   TESTNUM, 0(t0);                                           \
        li   t1, 0xF0000010;                                           \
        li   t2, 'F'; sw t2, 0(t1);                                   \
        li   t2, 'A'; sw t2, 0(t1);                                   \
        li   t2, 'I'; sw t2, 0(t1);                                   \
        li   t2, 'L'; sw t2, 0(t1);                                   \
        li   t2, ' '; sw t2, 0(t1);                                   \
        mv   t4, TESTNUM;                                              \
        li   t5, 0;                                                    \
        li   t3, 100;                                                  \
2:      blt  t4, t3, 3f;                                               \
        addi t4, t4, -100;                                             \
        addi t5, t5, 1;                                                \
        j    2b;                                                       \
3:      addi t5, t5, '0';                                              \
        sw   t5, 0(t1);                                                \
        li   t5, 0;                                                    \
        li   t3, 10;                                                   \
4:      blt  t4, t3, 5f;                                               \
        addi t4, t4, -10;                                              \
        addi t5, t5, 1;                                                \
        j    4b;                                                       \
5:      addi t5, t5, '0';                                              \
        sw   t5, 0(t1);                                                \
        addi t4, t4, '0';                                              \
        sw   t4, 0(t1);                                                \
        li   t2, '\n'; sw t2, 0(t1);                                  \
        li   t0, 0xF0000008;                                           \
        li   t1, 1;                                                    \
        sw   t1, 0(t0);                                                \
1:      j    1b;

//-----------------------------------------------------------------------
// Data Section Macros
//-----------------------------------------------------------------------

#define EXTRA_DATA

#define RVTEST_DATA_BEGIN                                               \
        EXTRA_DATA                                                      \
        .pushsection .tohost,"aw",@progbits;                           \
        .align 4; .global tohost; tohost: .word 0;                     \
        .align 4; .global fromhost; fromhost: .word 0;                 \
        .popsection;                                                    \
        .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END .align 4; .global end_signature; end_signature:

#endif
