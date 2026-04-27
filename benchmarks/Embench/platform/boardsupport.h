#ifndef EMBENCH_BOARDSUPPORT_H
#define EMBENCH_BOARDSUPPORT_H

void initialise_board(void);
void start_trigger(void);
void stop_trigger(void);
unsigned long board_cycle_lo(void);
unsigned long long board_cycle_count(void);
unsigned long long board_instret_count(void);
void board_put_u64(unsigned long long value);
void board_uart_drain(void);
void board_finish(unsigned int led_value);

#endif
