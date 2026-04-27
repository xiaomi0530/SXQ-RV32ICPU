#include "dhrystone.h"
#include <stdarg.h>
#include <stddef.h>

#define MMIO_BASE      0xF0000000UL
#define MMIO_CYCLE_LO  (*(volatile unsigned long *)(MMIO_BASE + 0x00UL))
#define MMIO_CYCLE_HI  (*(volatile unsigned long *)(MMIO_BASE + 0x04UL))
#define MMIO_TOHOST    (*(volatile unsigned long *)(MMIO_BASE + 0x08UL))
#define MMIO_LED       (*(volatile unsigned long *)(MMIO_BASE + 0x0CUL))
#define MMIO_UART_TX   (*(volatile unsigned long *)(MMIO_BASE + 0x10UL))
#define MMIO_UART_STAT (*(volatile unsigned long *)(MMIO_BASE + 0x14UL))
#define MMIO_INSTRET_LO (*(volatile unsigned long *)(MMIO_BASE + 0x18UL))
#define MMIO_INSTRET_HI (*(volatile unsigned long *)(MMIO_BASE + 0x1CUL))

#define UART_STATUS_TX_READY  (1UL << 0)
#define UART_STATUS_TX_BUSY   (1UL << 1)

unsigned long dhrystone_get_cycles(void)
{
    return MMIO_CYCLE_LO;
}

static unsigned long long mmio_read_counter64(volatile unsigned long *lo_reg,
                                              volatile unsigned long *hi_reg)
{
    unsigned long hi0;
    unsigned long lo;
    unsigned long hi1;

    do {
        hi0 = *hi_reg;
        lo  = *lo_reg;
        hi1 = *hi_reg;
    } while (hi0 != hi1);

    return (((unsigned long long)hi1) << 32) | (unsigned long long)lo;
}

unsigned long long dhrystone_get_cycles64(void)
{
    return mmio_read_counter64((volatile unsigned long *)&MMIO_CYCLE_LO,
                               (volatile unsigned long *)&MMIO_CYCLE_HI);
}

unsigned long long dhrystone_get_instret64(void)
{
    return mmio_read_counter64((volatile unsigned long *)&MMIO_INSTRET_LO,
                               (volatile unsigned long *)&MMIO_INSTRET_HI);
}

void setStats(int enable)
{
    volatile unsigned long sink;
    (void)enable;
    sink = MMIO_CYCLE_LO;
    sink = MMIO_CYCLE_HI;
    (void)sink;
}

static void uart_wait_ready(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_READY) == 0UL) {
    }
}

static void uart_drain(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_BUSY) != 0UL) {
    }
}

static int uart_putc_blocking(char ch)
{
    uart_wait_ready();
    if (ch == '\n') {
        MMIO_UART_TX = (unsigned long)'\r';
        uart_wait_ready();
    }
    MMIO_UART_TX = (unsigned long)(unsigned char)ch;
    return (ch == '\n') ? 2 : 1;
}

static int uart_puts_blocking(const char *str)
{
    int count = 0;
    if (str == 0) {
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
    int pad;
    int count = 0;

    do {
        buf[idx++] = (char)('0' + (value % 10UL));
        value /= 10UL;
    } while ((value != 0UL) && (idx < (int)sizeof(buf)));

    pad = width - idx;
    while (pad-- > 0) {
        count += uart_putc_blocking(zero_pad ? '0' : ' ');
    }
    while (idx-- > 0) {
        count += uart_putc_blocking(buf[idx]);
    }
    return count;
}

static int uart_put_u64(unsigned long long value)
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
        absval = (unsigned long)(-(value + 1L)) + 1UL;
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
    int pad;
    int count = 0;

    do {
        unsigned long nib = value & 0xFUL;
        buf[idx++] = (char)((nib < 10UL) ? ('0' + nib) : ('a' + (nib - 10UL)));
        value >>= 4;
    } while ((value != 0UL) && (idx < (int)sizeof(buf)));

    pad = width - idx;
    while (pad-- > 0) {
        count += uart_putc_blocking(zero_pad ? '0' : ' ');
    }
    while (idx-- > 0) {
        count += uart_putc_blocking(buf[idx]);
    }
    return count;
}

static int mini_vprintf(const char *fmt, va_list ap)
{
    int count = 0;

    while (*fmt != '\0') {
        int zero_pad = 0;
        int width = 0;
        int long_flag = 0;
        char spec;

        if (*fmt != '%') {
            count += uart_putc_blocking(*fmt++);
            continue;
        }

        fmt++;
        while (*fmt == '0') {
            zero_pad = 1;
            fmt++;
        }
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }
        while (*fmt == 'l') {
            long_flag++;
            fmt++;
        }

        spec = *fmt ? *fmt++ : '\0';
        switch (spec) {
            case 'c':
                count += uart_putc_blocking((char)va_arg(ap, int));
                break;
            case 's':
                count += uart_puts_blocking(va_arg(ap, const char *));
                break;
            case 'd':
            case 'i':
                if (long_flag > 0) {
                    count += uart_put_int(va_arg(ap, long), width, zero_pad);
                } else {
                    count += uart_put_int((long)va_arg(ap, int), width, zero_pad);
                }
                break;
            case 'u':
                if (long_flag > 0) {
                    count += uart_put_uint(va_arg(ap, unsigned long), width, zero_pad);
                } else {
                    count += uart_put_uint((unsigned long)va_arg(ap, unsigned int), width, zero_pad);
                }
                break;
            case 'x':
            case 'X':
                if (long_flag > 0) {
                    count += uart_put_hex(va_arg(ap, unsigned long), width, zero_pad);
                } else {
                    count += uart_put_hex((unsigned long)va_arg(ap, unsigned int), width, zero_pad);
                }
                break;
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

    return count;
}

int printf(const char *fmt, ...)
{
    int count;
    va_list ap;

    va_start(ap, fmt);
    count = mini_vprintf(fmt, ap);
    va_end(ap);
    return count;
}

void debug_printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    (void)mini_vprintf(fmt, ap);
    va_end(ap);
}

int putchar(int ch)
{
    return uart_putc_blocking((char)ch);
}

void dhrystone_print_ipc(unsigned long long cycles, unsigned long long instret)
{
    unsigned long long ipc_x1000 = 0ULL;
    unsigned long frac;

    if (cycles != 0ULL) {
        ipc_x1000 = (instret * 1000ULL) / cycles;
    }

    uart_puts_blocking("IPC=");
    uart_put_u64(ipc_x1000 / 1000ULL);
    uart_putc_blocking('.');
    frac = (unsigned long)(ipc_x1000 % 1000ULL);
    uart_putc_blocking((char)('0' + ((frac / 100UL) % 10UL)));
    uart_putc_blocking((char)('0' + ((frac / 10UL) % 10UL)));
    uart_putc_blocking((char)('0' + (frac % 10UL)));
    uart_puts_blocking("  C=");
    uart_put_u64(cycles);
    uart_puts_blocking("  I=");
    uart_put_u64(instret);
    uart_putc_blocking('\n');
}

void *memcpy(void *dst, const void *src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) {
        *d++ = *s++;
    }
    return dst;
}

void *memset(void *dst, int c, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    while (n--) {
        *d++ = (unsigned char)c;
    }
    return dst;
}

void *memmove(void *dst, const void *src, size_t n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;

    if (d < s || d >= s + n) {
        while (n--) {
            *d++ = *s++;
        }
    } else {
        d += n;
        s += n;
        while (n--) {
            *--d = *--s;
        }
    }
    return dst;
}

int strcmp(const char *a, const char *b)
{
    while (*a && ((unsigned char)*a == (unsigned char)*b)) {
        a++;
        b++;
    }
    return (unsigned char)*a - (unsigned char)*b;
}

char *strcpy(char *dst, const char *src)
{
    char *ret = dst;
    while ((*dst++ = *src++) != '\0') {
    }
    return ret;
}

size_t strlen(const char *str)
{
    const char *p = str;
    while (*p) {
        p++;
    }
    return (size_t)(p - str);
}

void abort(void)
{
    uart_drain();
    MMIO_LED = 0x8000UL;
    MMIO_TOHOST = 1UL;
    for (;;) {
    }
}

void exit(int code)
{
    uart_drain();
    MMIO_LED = (code == 0) ? 0UL : (0x8000UL | (unsigned long)(code & 0xFF));
    MMIO_TOHOST = 1UL;
    for (;;) {
    }
}
