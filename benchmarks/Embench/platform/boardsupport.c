#include "boardsupport.h"

#include <stdarg.h>
#include <stddef.h>

#define MMIO_BASE      0xF0000000UL
#define MMIO_CYCLE_LO  (*(volatile unsigned long *)(MMIO_BASE + 0x00UL))
#define MMIO_CYCLE_HI  (*(volatile unsigned long *)(MMIO_BASE + 0x04UL))
#define MMIO_TOHOST    (*(volatile unsigned long *)(MMIO_BASE + 0x08UL))
#define MMIO_LED       (*(volatile unsigned long *)(MMIO_BASE + 0x0CUL))
#define MMIO_UART_TX   (*(volatile unsigned long *)(MMIO_BASE + 0x10UL))
#define MMIO_UART_STAT (*(volatile unsigned long *)(MMIO_BASE + 0x14UL))

#define UART_STATUS_TX_READY  (1UL << 0)
#define UART_STATUS_TX_BUSY   (1UL << 1)

unsigned long board_cycle_lo(void)
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

unsigned long long board_cycle_count(void)
{
    return mmio_read_counter64((volatile unsigned long *)&MMIO_CYCLE_LO,
                               (volatile unsigned long *)&MMIO_CYCLE_HI);
}

void initialise_board(void)
{
    MMIO_LED = 0xE001UL;
}

void start_trigger(void)
{
    volatile unsigned long sink;
    sink = MMIO_CYCLE_LO;
    sink = MMIO_CYCLE_HI;
    (void)sink;
}

void stop_trigger(void)
{
    volatile unsigned long sink;
    sink = MMIO_CYCLE_LO;
    sink = MMIO_CYCLE_HI;
    (void)sink;
}

static void uart_wait_ready(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_READY) == 0UL) {
    }
}

int putchar(int ch)
{
    uart_wait_ready();
    if (ch == '\n') {
        MMIO_UART_TX = (unsigned long)'\r';
        uart_wait_ready();
    }
    MMIO_UART_TX = (unsigned long)(unsigned char)ch;
    return ch;
}

int puts(const char *str)
{
    int count = 0;
    if (str == 0) {
        str = "(null)";
    }
    while (*str != '\0') {
        putchar(*str++);
        count++;
    }
    putchar('\n');
    return count + 1;
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
        putchar(zero_pad ? '0' : ' ');
        count++;
    }
    while (idx-- > 0) {
        putchar(buf[idx]);
        count++;
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
        putchar(buf[idx]);
        count++;
    }
    return count;
}

void board_put_u64(unsigned long long value)
{
    (void)uart_put_u64(value);
}

void board_uart_drain(void)
{
    while ((MMIO_UART_STAT & UART_STATUS_TX_BUSY) != 0UL) {
    }
}

static int uart_put_int(long value, int width, int zero_pad)
{
    int count = 0;
    unsigned long absval;

    if (value < 0) {
        putchar('-');
        count++;
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
        putchar(zero_pad ? '0' : ' ');
        count++;
    }
    while (idx-- > 0) {
        putchar(buf[idx]);
        count++;
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
            putchar(*fmt++);
            count++;
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
                putchar((char)va_arg(ap, int));
                count++;
                break;
            case 's': {
                const char *str = va_arg(ap, const char *);
                if (str == 0) {
                    str = "(null)";
                }
                while (*str != '\0') {
                    putchar(*str++);
                    count++;
                }
                break;
            }
            case 'd':
            case 'i':
                if (long_flag > 0) {
                    count += uart_put_int(va_arg(ap, long), width, zero_pad);
                } else {
                    count += uart_put_int((long)va_arg(ap, int), width, zero_pad);
                }
                break;
            case 'u':
                if (long_flag > 1) {
                    count += uart_put_u64(va_arg(ap, unsigned long long));
                } else if (long_flag > 0) {
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
                putchar('%');
                count++;
                break;
            default:
                putchar('%');
                count++;
                if (spec != '\0') {
                    putchar(spec);
                    count++;
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

double fabs(double x)
{
    return (x < 0.0) ? -x : x;
}

float fabsf(float x)
{
    return (x < 0.0f) ? -x : x;
}

double sqrt(double x)
{
    double guess;
    int iter;

    if (x <= 0.0) {
        return 0.0;
    }

    guess = (x >= 1.0) ? x : 1.0;
    for (iter = 0; iter < 20; iter++) {
        guess = 0.5 * (guess + x / guess);
    }
    return guess;
}

float sqrtf(float x)
{
    return (float)sqrt((double)x);
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

int memcmp(const void *lhs, const void *rhs, size_t n)
{
    const unsigned char *a = (const unsigned char *)lhs;
    const unsigned char *b = (const unsigned char *)rhs;
    while (n--) {
        if (*a != *b) {
            return (int)*a - (int)*b;
        }
        a++;
        b++;
    }
    return 0;
}

size_t strlen(const char *str)
{
    const char *p = str;
    while (*p) {
        p++;
    }
    return (size_t)(p - str);
}

int strcmp(const char *a, const char *b)
{
    while (*a && ((unsigned char)*a == (unsigned char)*b)) {
        a++;
        b++;
    }
    return (unsigned char)*a - (unsigned char)*b;
}

int strncmp(const char *a, const char *b, size_t n)
{
    while (n != 0) {
        if ((unsigned char)*a != (unsigned char)*b || *a == '\0' || *b == '\0') {
            return (unsigned char)*a - (unsigned char)*b;
        }
        a++;
        b++;
        n--;
    }
    return 0;
}

char *strcpy(char *dst, const char *src)
{
    char *ret = dst;
    while ((*dst++ = *src++) != '\0') {
    }
    return ret;
}

char *strchr(const char *str, int ch)
{
    while (*str != '\0') {
        if (*str == (char)ch) {
            return (char *)str;
        }
        str++;
    }
    return (ch == 0) ? (char *)str : (char *)0;
}

void abort(void)
{
    board_uart_drain();
    MMIO_LED = 0xE0FFUL;
    MMIO_TOHOST = 1UL;
    for (;;) {
    }
}

void exit(int code)
{
    board_uart_drain();
    MMIO_LED = (code == 0) ? 0xE000UL : (0xE100UL | (unsigned long)(code & 0xFF));
    MMIO_TOHOST = 1UL;
    for (;;) {
    }
}

void board_finish(unsigned int led_value)
{
    board_uart_drain();
    MMIO_LED = (unsigned long)led_value;
    MMIO_TOHOST = 1UL;
    for (;;) {
    }
}
