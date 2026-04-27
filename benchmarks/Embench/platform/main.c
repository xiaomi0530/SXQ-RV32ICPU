#include "support.h"
#include "boardsupport.h"
#include <stdio.h>

static void uart_puts_raw(const char *str)
{
    if (str == 0) {
        return;
    }
    while (*str != '\0') {
        putchar(*str++);
    }
}

static void uart_put_newline(void)
{
    putchar('\n');
}

static void uart_put_label_u64(const char *label, unsigned long long value)
{
    uart_puts_raw(label);
    board_put_u64(value);
    uart_put_newline();
}

static void uart_put_label_u32(const char *label, unsigned long value)
{
    uart_put_label_u64(label, (unsigned long long)value);
}

static void uart_put_label_fixed3(const char *label, unsigned long long value_x1000)
{
    unsigned long frac;

    uart_puts_raw(label);
    board_put_u64(value_x1000 / 1000ULL);
    putchar('.');
    frac = (unsigned long)(value_x1000 % 1000ULL);
    putchar((int)('0' + ((frac / 100UL) % 10UL)));
    putchar((int)('0' + ((frac / 10UL) % 10UL)));
    putchar((int)('0' + (frac % 10UL)));
    uart_put_newline();
}

static void uart_put_fixed3(unsigned long long value_x1000)
{
    unsigned long frac;

    board_put_u64(value_x1000 / 1000ULL);
    putchar('.');
    frac = (unsigned long)(value_x1000 % 1000ULL);
    putchar((int)('0' + ((frac / 100UL) % 10UL)));
    putchar((int)('0' + ((frac / 10UL) % 10UL)));
    putchar((int)('0' + (frac % 10UL)));
}

static void uart_put_fixed2(unsigned long value_x100)
{
    unsigned long frac;

    board_put_u64((unsigned long long)(value_x100 / 100UL));
    putchar('.');
    frac = value_x100 % 100UL;
    putchar((int)('0' + ((frac / 10UL) % 10UL)));
    putchar((int)('0' + (frac % 10UL)));
}

int main(void)
{
    volatile int result;
    int correct;
    unsigned long long start_cycle;
    unsigned long long end_cycle;
    unsigned long long start_instret;
    unsigned long long end_instret;
    unsigned long long cycles;
    unsigned long long instret;
    unsigned long long runtime_us;
    unsigned long long score_x1000;
    unsigned long long ipc_x1000;
    unsigned long score_x100;
    unsigned int final_led;
    unsigned long long ipc_numer;
    unsigned long long ipc_rem;

    initialise_board();
    initialise_benchmark();
    warm_caches(WARMUP_HEAT);

    start_cycle = board_cycle_count();
    start_instret = board_instret_count();
    start_trigger();
    result = benchmark();
    stop_trigger();
    end_cycle = board_cycle_count();
    end_instret = board_instret_count();

    correct = verify_benchmark(result);
    cycles = end_cycle - start_cycle;
    instret = end_instret - start_instret;
    runtime_us = (cycles * 1000000ULL + (EMBENCH_CPU_FREQ_HZ / 2ULL)) / EMBENCH_CPU_FREQ_HZ;
    score_x1000 = (cycles != 0ULL) ? ((unsigned long long)EMBENCH_BASELINE_MS * EMBENCH_CPU_FREQ_HZ) / cycles : 0ULL;
    if (cycles != 0ULL) {
        ipc_numer = instret * 1000ULL;
        ipc_x1000 = ipc_numer / cycles;
        ipc_rem = ipc_numer % cycles;
        if (ipc_rem >= (cycles - ipc_rem)) {
            ipc_x1000++;
        }
    } else {
        ipc_x1000 = 0ULL;
    }
    score_x100 = (unsigned long)((score_x1000 + 5ULL) / 10ULL);
    if (!correct) {
        final_led = 0xE101U;
    } else if (score_x100 > 0xFFFFUL) {
        final_led = 0xFFFFU;
    } else {
        final_led = (unsigned int)score_x100;
    }

    uart_puts_raw("WS ");
    uart_puts_raw("V=");
    board_put_u64((unsigned long long)(unsigned int)correct);
    uart_puts_raw(" S=");
    uart_put_fixed2(score_x100);
    uart_put_newline();

    uart_puts_raw("IPC=");
    uart_put_fixed3(ipc_x1000);
    uart_puts_raw("  C=");
    board_put_u64(cycles);
    uart_puts_raw("  I=");
    board_put_u64(instret);
    uart_put_newline();

    board_uart_drain();

    board_finish(final_led);
    return 0;
}
