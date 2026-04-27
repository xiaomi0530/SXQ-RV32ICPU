/*
 * link.ld — riscv-tests 适配 LAIC-CPU
 *
 * IMEM  0x00000000  16 KB  (代码 + 只读数据 + .data 镜像)
 * DMEM  0x00010000  32 KB  (.data VMA + .bss + 栈)
 *
 * 启动时 crt0 将 .data 从 IMEM(LMA) 拷贝到 DMEM(VMA)
 */

MEMORY
{
    IMEM : ORIGIN = 0x00000000, LENGTH = 32K
    DMEM : ORIGIN = 0x00010000, LENGTH = 32K
}

ENTRY(_start)

SECTIONS
{
    .text.init : {
        *(.text.init)
    } > IMEM

    .text : {
        *(.text .text.*)
    } > IMEM

    .rodata : {
        *(.rodata .rodata.*)
        . = ALIGN(4);
        _text_end = .;
    } > IMEM

    /* .tohost 放在 DMEM, LMA 也在 DMEM (不需要拷贝, 初始值为 0) */
    .tohost : {
        *(.tohost)
        . = ALIGN(4);
    } > DMEM

    /* .data VMA 在 DMEM, LMA 紧跟 IMEM 的 _text_end */
    .data : AT(_text_end) {
        _data_lma   = LOADADDR(.data);
        _data_start = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        _data_end = .;
    } > DMEM

    .bss : {
        _bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        . = ALIGN(4);
        _bss_end = .;
    } > DMEM

    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}

