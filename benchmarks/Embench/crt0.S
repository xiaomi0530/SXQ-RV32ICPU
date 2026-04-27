/* ==========================================================================
 * crt0.S — RV32I 裸机启动代码
 *
 * 内存布局:
 *   IMEM : 0x00000000 – 0x00007FFF  (32KB, 存放 .text + .rodata + .data_LMA)
 *   DMEM : 0x00010000 – 0x00017FFF  (32KB, 存放 .data_VMA + .bss + stack)
 *
 * 启动流程:
 *   1. 设置栈指针 sp = _stack_top (DMEM顶端)
 *   2. 将 .data 段从 IMEM (LMA) 复制到 DMEM (VMA)
 *   3. 将 .bss 段清零
 *   4. 调用 main(1, NULL)
 *   5. main 返回后 → 无限循环（通常不会到达，portable_fini 已停机）
 * ========================================================================= */

    .section .text.start, "ax", @progbits
    .global  _start
    .type    _start, @function

_start:
    /* ------------------------------------------------------------------ */
    /* Step 1: 初始化栈指针                                               */
    /* ------------------------------------------------------------------ */
    la   sp, _stack_top          /* sp = DMEM 末尾 (0x00018000)           */

    /* 清零 gp / tp / fp，防止野指针 */
    li   gp, 0
    li   tp, 0
    li   s0, 0

    /* ------------------------------------------------------------------ */
    /* Step 2: 将 .data 从 LMA (IMEM) 复制到 VMA (DMEM)                  */
    /* ------------------------------------------------------------------ */
    la   a0, _data_lma           /* 源: IMEM 中 .data 镜像起址            */
    la   a1, _data_start         /* 目的: DMEM VMA 起址                   */
    la   a2, _data_end           /* 目的: DMEM VMA 末址                   */
    beq  a1, a2, .Lbss_init     /* 若 .data 为空则跳过                    */
.Ldata_loop:
    lw   t0, 0(a0)
    sw   t0, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    blt  a1, a2, .Ldata_loop

    /* ------------------------------------------------------------------ */
    /* Step 3: 将 .bss 清零                                               */
    /* ------------------------------------------------------------------ */
.Lbss_init:
    la   a0, _bss_start
    la   a1, _bss_end
    beq  a0, a1, .Lmain_call
.Lbss_loop:
    sw   zero, 0(a0)
    addi a0, a0, 4
    blt  a0, a1, .Lbss_loop

    /* ------------------------------------------------------------------ */
    /* Step 4: 调用 main(argc=1, argv=NULL)                               */
    /* SEED_VOLATILE 模式下 argc/argv 不被 CoreMark 使用，传 1/NULL 即可  */
    /* ------------------------------------------------------------------ */
.Lmain_call:
    li   a0, 1                   /* argc = 1                               */
    li   a1, 0                   /* argv = NULL                            */
    call main
    call exit

    /* ------------------------------------------------------------------ */
    /* Step 5: main 返回后停机（portable_fini 通常已执行 for(;;)）        */
    /* ------------------------------------------------------------------ */
.Lhalt:
    j    .Lhalt

    .size _start, . - _start
