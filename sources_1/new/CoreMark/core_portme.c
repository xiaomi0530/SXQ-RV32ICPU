/*===========================================================================
 * core_portme.c — CoreMark 1.0 平台移植实现 (v5)
 *===========================================================================*/

#include "coremark.h"
#include <stddef.h>
#include <stdarg.h>

/* ===========================================================================
 * 全局配置
 * ========================================================================= */
ee_u32 default_num_contexts = 1;

/* EEMBC 标准种子，seed1~seed5 全部提供（core_util.c 的 get_seed_32 引用所有） */
volatile ee_s32 seed1_volatile    = 0;
volatile ee_s32 seed2_volatile    = 0;
volatile ee_s32 seed3_volatile    = 0x66;
volatile ee_s32 seed4_volatile    = 1000; //修改这个可以固定ITERATIOONS
volatile ee_s32 seed5_volatile    = 0;
volatile ee_s32 memblock_volatile = 0;

/* ===========================================================================
 * 硬件计时器
 * ========================================================================= */
static CORE_TICKS g_start_ticks = 0;
static ee_u32     g_start_hi    = 0;
static CORE_TICKS g_stop_ticks  = 0;
static ee_u32     g_stop_hi     = 0;

void start_time(void)
{
    g_start_ticks = MMIO_CYCLE_LO;
    g_start_hi    = MMIO_CYCLE_HI;
}

void stop_time(void)
{
    g_stop_ticks = MMIO_CYCLE_LO;
    g_stop_hi    = MMIO_CYCLE_HI;
}

CORE_TICKS get_time(void)
{
    return g_stop_ticks - g_start_ticks;
}
secs_ret time_in_secs(CORE_TICKS ticks)
{
    secs_ret s = (secs_ret)(ticks / EE_TICKS_PER_SEC);
    return (s == 0u) ? 1u : s;
}

/* ===========================================================================
 * align_mem — 对齐到 8 字节边界（core_matrix.c 调用）
 * ee_ptr_int 在 RV32I 下是 ee_u32（32-bit），与指针等宽，安全转换。
 * ========================================================================= */
void *align_mem(void *ptr)
{
    ee_ptr_int p    = (ee_ptr_int)ptr;
    ee_ptr_int rem  = p & (ee_ptr_int)7;
    return rem ? (void *)(p + (8u - rem)) : ptr;
}

/* ===========================================================================
 * portable_malloc / portable_free（MEM_STATIC 下不调用，链接符号必须存在）
 * ========================================================================= */
void *portable_malloc(ee_size_t size) { (void)size; return NULL; }
void  portable_free(void *p)          { (void)p; }

/* ===========================================================================
 * portable_init — 基准开始前回调
 * 签名: void portable_init(core_portable *p, int *argc, char *argv[])
 * ========================================================================= */
void portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;
    p->portable_id = 1;
    p->report_iterations = ITERATIONS;
    MMIO_LED = LED_RUNNING;
}

void coremark_set_report_iterations(core_portable *p, ee_u32 iterations)
{
    if (p == NULL) return;
    p->report_iterations = (iterations == 0u) ? 1u : iterations;
}

/* ===========================================================================
 * portable_fini -- CoreMark benchmark end callback
 *
 * LED = score x 10 (raw integer, NO BCD packing)
 *
 * seg7_display converts LED via Double-Dabble to decimal digits.
 * Storing BCD in LED causes wrong display:
 *   BCD score=82.8 -> LED=0x0828=2088 decimal -> shows "2088" -> misread 208.8  WRONG
 *   Raw score=82.8 -> LED=828          -> shows "828"  -> read   82.8           OK
 *
 * Reading: last digit on display is tenths place.
 *   "828"  -> 82.8  CoreMark
 *   "1234" -> 123.4 CoreMark
 *   Max displayable: 65535 -> 6553.5 CoreMark
 *
 * Timer: 64-bit to avoid 32-bit wrap at ~42.9 s (ITER=2000 may exceed this).
 * ========================================================================= */
void portable_fini(core_portable *p)
{
    ee_u32 report_iterations =
        (p != NULL && p->report_iterations != 0u)
            ? p->report_iterations
            : ITERATIONS;

    /* Reconstruct 64-bit elapsed from hi+lo snapshots */
    ee_u64 stop64  = ((ee_u64)g_stop_hi  << 32) | (ee_u64)g_stop_ticks;
    ee_u64 start64 = ((ee_u64)g_start_hi << 32) | (ee_u64)g_start_ticks;
    ee_u64 elapsed = stop64 - start64;

    if (elapsed == 0ULL) {
        MMIO_LED = 0xDEADu; MMIO_TOHOST = 1u; for (;;) {}
    }

    /* score_x10 = actual_iterations * 10 * CLK_HZ / elapsed_cycles */
    ee_u64 score_x10 =
        (ee_u64)report_iterations * 10ULL * (ee_u64)EE_TICKS_PER_SEC
        / elapsed;

    /* Clamp to 16-bit LED max (65535 -> 6553.5 CoreMark) */
    if (score_x10 > 65535ULL) score_x10 = 65535ULL;

    /* Write raw integer; seg7 handles decimal conversion */
    MMIO_LED    = (ee_u32)score_x10;
    MMIO_TOHOST = 1u;
    for (;;) {}
}

/* ===========================================================================
 * ee_printf — 静默丢弃
 * ========================================================================= */
int ee_printf(const char *fmt, ...)
{
    va_list ap; (void)fmt; va_start(ap, fmt); va_end(ap); return 0;
}

/* ===========================================================================
 * C 运行时（替代 libc）
 * ========================================================================= */
void *memcpy(void *dst, const void *src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) *d++ = *s++;
    return dst;
}

void *memset(void *s, int c, size_t n)
{
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

void *memmove(void *dst, const void *src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    if (d < s || d >= s + n) { while (n--) *d++ = *s++; }
    else { d += n; s += n; while (n--) *--d = *--s; }
    return dst;
}

int strcmp(const char *a, const char *b)
{
    while (*a && ((unsigned char)*a == (unsigned char)*b)) { a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}

size_t strlen(const char *str)
{
    const char *p = str; while (*p) p++; return (size_t)(p - str);
}

/* ===========================================================================
 * 异常桩
 * ========================================================================= */
void abort(void) { MMIO_LED=0xFFFFu; MMIO_TOHOST=1u; for(;;){} }
void exit(int c) { (void)c; MMIO_LED=0xE0E0u; MMIO_TOHOST=1u; for(;;){} }
