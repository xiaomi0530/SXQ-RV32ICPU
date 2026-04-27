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
volatile ee_s32 seed4_volatile    = 5000;
volatile ee_s32 seed5_volatile    = 0;
volatile ee_s32 memblock_volatile = 0;

/* ===========================================================================
 * 硬件计时器
 * ========================================================================= */
static CORE_TICKS g_start_ticks = 0;
static ee_u32     g_start_hi    = 0;
static CORE_TICKS g_stop_ticks  = 0;
static ee_u32     g_stop_hi     = 0;
static CORE_TICKS g_start_instret_lo = 0;
static ee_u32     g_start_instret_hi = 0;
static CORE_TICKS g_stop_instret_lo  = 0;
static ee_u32     g_stop_instret_hi  = 0;

/* Software long division to avoid relying on libgcc 64-bit divide helpers
 * on cores without DIV/REM instructions.
 */
static ee_u64 coremark_u64_divmod_u64(ee_u64 num, ee_u64 den, ee_u64 *rem_out)
{
    ee_u64 q = 0;
    ee_u64 r = 0;
    int    bit;

    if (den == 0ULL) {
        if (rem_out) *rem_out = 0ULL;
        return 0ULL;
    }

    for (bit = 63; bit >= 0; bit--) {
        r = (r << 1) | ((num >> bit) & 1ULL);
        if (r >= den) {
            r -= den;
            q |= (1ULL << bit);
        }
    }

    if (rem_out) *rem_out = r;
    return q;
}

static void snapshot_cycle(CORE_TICKS *lo, ee_u32 *hi)
{
    ee_u32     hi_before, hi_after;
    CORE_TICKS lo_val;

    do {
        hi_before = MMIO_CYCLE_HI;
        lo_val    = MMIO_CYCLE_LO;
        hi_after  = MMIO_CYCLE_HI;
    } while (hi_before != hi_after);

    *lo = lo_val;
    *hi = hi_after;
}

static void snapshot_instret(CORE_TICKS *lo, ee_u32 *hi)
{
    ee_u32     hi_before, hi_after;
    CORE_TICKS lo_val;

    do {
        hi_before = MMIO_INSTRET_HI;
        lo_val    = MMIO_INSTRET_LO;
        hi_after  = MMIO_INSTRET_HI;
    } while (hi_before != hi_after);

    *lo = lo_val;
    *hi = hi_after;
}

void start_time(void)
{
    snapshot_cycle(&g_start_ticks, &g_start_hi);
    snapshot_instret(&g_start_instret_lo, &g_start_instret_hi);
}

void stop_time(void)
{
    snapshot_cycle(&g_stop_ticks, &g_stop_hi);
    snapshot_instret(&g_stop_instret_lo, &g_stop_instret_hi);
}

CORE_TICKS get_time(void)
{
    return g_stop_ticks - g_start_ticks;
}
secs_ret time_in_secs(CORE_TICKS ticks)
{
#if HAS_FLOAT
    return (double)ticks / (double)EE_TICKS_PER_SEC;
#else
    return (secs_ret)(ticks / EE_TICKS_PER_SEC);
#endif
}

/* ===========================================================================
 * UART 输出工具
 * ========================================================================= */
static void uart_wait_ready(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_READY) == 0u) {
        /* busy wait */
    }
}

static void uart_drain(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_BUSY) != 0u) {
        /* busy wait */
    }
}

static void uart_write_byte(ee_u8 byte)
{
    uart_wait_ready();
    MMIO_UART_TX = (ee_u32)byte;
}

static int uart_putc_blocking(char ch)
{
    if (ch == '\n') {
        uart_write_byte('\r');
        uart_write_byte('\n');
        return 2;
    }
    uart_write_byte((ee_u8)ch);
    return 1;
}

static int uart_puts_blocking(const char *str)
{
    int count = 0;
    if (str == NULL) {
        str = "(null)";
    }
    while (*str != '\0') {
        count += uart_putc_blocking(*str++);
    }
    return count;
}

static int uart_put_uint(unsigned long value, int width, int zero_pad)
{
    char buf[32];
    int idx = 0;
    do {
        buf[idx++] = (char)('0' + (value % 10UL));
        value /= 10UL;
    } while ((value != 0UL) && (idx < (int)sizeof(buf)));
    if (idx == 0) {
        buf[idx++] = '0';
    }
    if (width > 32) width = 32;
    int pad = width - idx;
    int count = 0;
    while (pad-- > 0) {
        count += uart_putc_blocking(zero_pad ? '0' : ' ');
    }
    while (idx-- > 0) {
        count += uart_putc_blocking(buf[idx]);
    }
    return count;
}

static int uart_put_u64(ee_u64 value)
{
    char buf[32];
    int idx = 0;
    int count = 0;

    do {
        buf[idx++] = (char)('0' + (value % 10ULL));
        value /= 10ULL;
    } while ((value != 0ULL) && (idx < (int)sizeof(buf)));

    while (idx-- > 0) {
        count += uart_putc_blocking(buf[idx]);
    }
    return count;
}

static int uart_put_int(long value, int width, int zero_pad)
{
    int count = 0;
    unsigned long absval;
    if (value < 0) {
        count += uart_putc_blocking('-');
        unsigned long mag = (unsigned long)(-(value + 1L)) + 1UL;
        absval = mag;
        if (width > 0) {
            width -= 1;
        }
    } else {
        absval = (unsigned long)value;
    }
    count += uart_put_uint(absval, width, zero_pad);
    return count;
}

static int uart_put_hex(unsigned long value, int width, int zero_pad)
{
    char buf[32];
    int idx = 0;
    do {
        unsigned long nib = value & 0xFUL;
        buf[idx++] = (char)((nib < 10UL) ? ('0' + nib) : ('a' + (nib - 10UL)));
        value >>= 4;
    } while ((value != 0UL) && (idx < (int)sizeof(buf)));
    if (idx == 0) {
        buf[idx++] = '0';
    }
    if (width > 32) width = 32;
    int pad = width - idx;
    int count = 0;
    while (pad-- > 0) {
        count += uart_putc_blocking(zero_pad ? '0' : ' ');
    }
    while (idx-- > 0) {
        count += uart_putc_blocking(buf[idx]);
    }
    return count;
}

static int uart_put_double(double value, int precision)
{
    int count = 0;
    if (precision < 0) precision = 6;
    if (value < 0.0) {
        count += uart_putc_blocking('-');
        value = -value;
    }
    double rounding = 0.5;
    for (int i = 0; i < precision; i++) rounding /= 10.0;
    value += rounding;
    unsigned long int_part = (unsigned long)value;
    double frac = value - (double)int_part;
    count += uart_put_uint(int_part, 0, 0);
    if (precision > 0) {
        count += uart_putc_blocking('.');
        for (int i = 0; i < precision; i++) {
            frac *= 10.0;
            int digit = (int)frac;
            if (digit > 9) digit = 9;
            count += uart_putc_blocking((char)('0' + digit));
            frac -= (double)digit;
        }
    }
    return count;
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
    p->report_iterations = 1234u;
    MMIO_LED = LED_RUNNING;
}

void coremark_set_report_iterations(core_portable *p, ee_u32 iterations)
{
    if (p == NULL) return;
    if (iterations == 0u) {
        p->report_iterations = 1234u;
    } else {
        p->report_iterations = iterations;
    }
}

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
    ee_u64 stop_instret64  = ((ee_u64)g_stop_instret_hi  << 32) | (ee_u64)g_stop_instret_lo;
    ee_u64 start_instret64 = ((ee_u64)g_start_instret_hi << 32) | (ee_u64)g_start_instret_lo;
    ee_u64 elapsed_instret = stop_instret64 - start_instret64;
    ee_u64 ipc_x1000 = 0ULL;
    ee_u64 ipc_frac;

    if (elapsed == 0ULL) {
        MMIO_LED = 0x8000u;
        MMIO_TOHOST = 1u;
        for (;;) {}
    }

    /* score_x10 = round(actual_iterations * 10 * CLK_HZ / elapsed_cycles) */
    ee_u64 numer = (ee_u64)report_iterations * 10ULL * (ee_u64)EE_TICKS_PER_SEC;
    ee_u64 rem = 0ULL;
    ee_u64 score_x10 = coremark_u64_divmod_u64(numer, elapsed, &rem);
    /* Round to nearest integer without multiplying rem by 2 (overflow-safe). */
    if (rem >= (elapsed - rem)) {
        score_x10++;
    }

    ipc_x1000 = coremark_u64_divmod_u64(elapsed_instret * 1000ULL, elapsed, NULL);
    ipc_frac = ipc_x1000 % 1000ULL;

    uart_puts_blocking("IPC=");
    uart_put_u64(ipc_x1000 / 1000ULL);
    uart_putc_blocking('.');
    uart_putc_blocking((char)('0' + (int)((ipc_frac / 100ULL) % 10ULL)));
    uart_putc_blocking((char)('0' + (int)((ipc_frac / 10ULL) % 10ULL)));
    uart_putc_blocking((char)('0' + (int)(ipc_frac % 10ULL)));
    uart_puts_blocking("  C=");
    uart_put_u64(elapsed);
    uart_puts_blocking("  I=");
    uart_put_u64(elapsed_instret);
    uart_putc_blocking('\n');
    uart_drain();

    /* Clamp to 16-bit LED max (65535 -> 6553.5 CoreMark) */
    if (score_x10 > 65535ULL) score_x10 = 0ULL;

    /* Write raw integer; seg7 handles decimal conversion */
    MMIO_LED    = (ee_u32)score_x10;
    MMIO_TOHOST = 1u;
    for (;;) {}
}

/* ===========================================================================
 * ee_printf — 通过 UART 打印，支持 %d/%u/%x/%s/%c/%%（满足 CoreMark 输出需求）
 * ========================================================================= */
int ee_printf(const char *fmt, ...)
{
    if (fmt == NULL) {
        return 0;
    }

    va_list ap;
    va_start(ap, fmt);
    int count = 0;

    while (*fmt != '\0') {
        if (*fmt != '%') {
            count += uart_putc_blocking(*fmt++);
            continue;
        }

        fmt++; /* skip '%' */
        int zero_pad = 0;
        int width = 0;
        while (*fmt == '0') {
            zero_pad = 1;
            fmt++;
        }
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }
        if (width > 32) width = 32;

        int long_flag = 0;
        if (*fmt == 'l') {
            long_flag = 1;
            fmt++;
        }

        char spec = *fmt ? *fmt++ : '\0';
        switch (spec) {
            case 'c': {
                int ch = va_arg(ap, int);
                count += uart_putc_blocking((char)ch);
                break;
            }
            case 's': {
                const char *str = va_arg(ap, const char *);
                count += uart_puts_blocking(str);
                break;
            }
            case 'd':
            case 'i': {
                long val = long_flag ? va_arg(ap, long)
                                     : (long)va_arg(ap, int);
                count += uart_put_int(val, width, zero_pad);
                break;
            }
            case 'u': {
                unsigned long val = long_flag
                    ? va_arg(ap, unsigned long)
                    : (unsigned long)va_arg(ap, unsigned int);
                count += uart_put_uint(val, width, zero_pad);
                break;
            }
            case 'f': {
                double val = va_arg(ap, double);
                count += uart_put_double(val, 6);
                break;
            }
            case 'x':
            case 'X': {
                unsigned long val = long_flag
                    ? va_arg(ap, unsigned long)
                    : (unsigned long)va_arg(ap, unsigned int);
                count += uart_put_hex(val, width, zero_pad);
                break;
            }
            case '%':
                count += uart_putc_blocking('%');
                break;
            default:
                count += uart_putc_blocking('%');
                if (spec != '\0') {
                    count += uart_putc_blocking(spec);
                }
                break;
        }
    }

    va_end(ap);
    return count;
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
void abort(void) { uart_drain(); MMIO_LED=0x8000u; MMIO_TOHOST=1u; for(;;){} }
void exit(int c) { (void)c; uart_drain(); MMIO_LED=0x8000u; MMIO_TOHOST=1u; for(;;){} }
