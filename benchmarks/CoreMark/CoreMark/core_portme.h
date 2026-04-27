/*===========================================================================
 * core_portme.h — CoreMark 1.0 移植头文件 (v5 最终版)
 *===========================================================================*/

#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#include <stddef.h>

/* -----------------------------------------------------------------------
 * 1. 基本整数类型
 * --------------------------------------------------------------------- */
typedef signed   char       ee_s8;
typedef unsigned char       ee_u8;
typedef signed   short      ee_s16;
typedef unsigned short      ee_u16;
typedef signed   int        ee_s32;
typedef unsigned int        ee_u32;
typedef unsigned long long  ee_u64;
typedef ee_u32              ee_ptr_int;
typedef size_t              ee_size_t;

/* -----------------------------------------------------------------------
 * 2. core_portable 结构体
 * --------------------------------------------------------------------- */
typedef struct core_portable_s {
    ee_u8 portable_id;
    ee_u32 report_iterations;
} core_portable;

/* -----------------------------------------------------------------------
 * 3. 计时类型
 * --------------------------------------------------------------------- */
typedef ee_u32 CORETIMETYPE;
typedef ee_u32 CORE_TICKS;

#ifndef HAS_FLOAT
#define HAS_FLOAT 0
#endif

#if HAS_FLOAT
typedef double secs_ret;
#else
typedef ee_u32 secs_ret;
#endif
#define CORE_PORTME_SECSRET_DEFINED

/* -----------------------------------------------------------------------
 * 4. MMIO
 * --------------------------------------------------------------------- */
#define MMIO_BASE      0xF0000000UL
#define MMIO_CYCLE_LO  (*(volatile ee_u32 *)(MMIO_BASE + 0x00U))
#define MMIO_CYCLE_HI  (*(volatile ee_u32 *)(MMIO_BASE + 0x04U))
#define MMIO_TOHOST    (*(volatile ee_u32 *)(MMIO_BASE + 0x08U))
#define MMIO_LED       (*(volatile ee_u32 *)(MMIO_BASE + 0x0CU))
#define MMIO_UART_TX   (*(volatile ee_u32 *)(MMIO_BASE + 0x10U))
#define MMIO_UART_STAT (*(volatile ee_u32 *)(MMIO_BASE + 0x14U))
#define MMIO_INSTRET_LO (*(volatile ee_u32 *)(MMIO_BASE + 0x18U))
#define MMIO_INSTRET_HI (*(volatile ee_u32 *)(MMIO_BASE + 0x1CU))

#define UART_STATUS_TX_READY    (1u << 0)
#define UART_STATUS_TX_BUSY     (1u << 1)
#define UART_STATUS_TX_OVERFLOW (1u << 2)

/* -----------------------------------------------------------------------
 * 5. 计时宏
 * --------------------------------------------------------------------- */
#define GETMYTIME(_t)        ((*(_t)) = MMIO_CYCLE_LO)
#define MYTIMEDIFF(fin, ini) ((fin) - (ini))
#define EE_TICKS_PER_SEC     100000000UL
#define TIMER_RES_DIVIDER    1
#define NSECS_PER_TICK       10

/* -----------------------------------------------------------------------
 * 6. 平台能力开关
 * --------------------------------------------------------------------- */
#ifndef HAS_FLOAT
#define HAS_FLOAT    0
#endif
#define HAS_TIME_H   0
#define USE_CLOCK    0
#define HAS_STDIO    0
#define HAS_PRINTF   0
#define HAS_MEMCPY   1

/* -----------------------------------------------------------------------
 * 7. CoreMark 配置（Makefile -D 注入，#ifndef 仅作 fallback）
 * --------------------------------------------------------------------- */
#ifndef ITERATIONS
#  define ITERATIONS 100
#endif
#define SEED_METHOD     SEED_VOLATILE
#define MEM_METHOD      MEM_STATIC
#define MULTITHREAD     1
#define USE_FORK        0
#define USE_PTHREAD     0
#define PARALLEL_METHOD "None"
#ifndef COMPILER_VERSION
#  define COMPILER_VERSION "riscv64-unknown-elf-gcc"
#endif
#ifndef COMPILER_FLAGS
#  define COMPILER_FLAGS   "-march=rv32im -mabi=ilp32 -mstrict-align -O2"
#endif
#ifndef MEM_LOCATION
#  define MEM_LOCATION     "STATIC"
#endif

/* -----------------------------------------------------------------------
 * 8. LED BCD 编码
 *    bits[15:12]=百位  bits[11:8]=十位  bits[7:4]=个位  bits[3:0]=小数1位
 * --------------------------------------------------------------------- */
#define LED_RUNNING  0xAAAAU

/* -----------------------------------------------------------------------
 * 9. 外部符号声明
 * --------------------------------------------------------------------- */
extern ee_u32 default_num_contexts;

/* SEED_VOLATILE 种子：seed1~seed5 + memblock（core_util.c 全部需要）*/
extern volatile ee_s32 seed1_volatile;
extern volatile ee_s32 seed2_volatile;
extern volatile ee_s32 seed3_volatile;
extern volatile ee_s32 seed4_volatile;
extern volatile ee_s32 seed5_volatile;
extern volatile ee_s32 memblock_volatile;

/* 计时接口 */
extern void       start_time(void);
extern void       stop_time(void);
extern CORE_TICKS get_time(void);
#if HAS_FLOAT
extern double     time_in_secs(CORE_TICKS ticks);
#else
extern ee_u32     time_in_secs(CORE_TICKS ticks);
#endif

/* 堆接口（MEM_STATIC 下不调用，但链接时必须存在） */
extern void *portable_malloc(ee_size_t size);
extern void  portable_free(void *p);

/* printf 替代 */
extern int ee_printf(const char *fmt, ...);

/*
 * 以下三个函数由 core_portme.c 实现，在此声明后 core_main.c/core_matrix.c
 * 通过 #include "coremark.h" → #include "core_portme.h" 的路径可见，
 * 不会触发 implicit declaration warning。
 *
 * 签名依据（来自真实 coremark.h / core_main.c 调用处）：
 *   core_main.c:127  portable_init(&(results[0].port), &argc, argv)
 *   core_main.c:439  portable_fini(&(results[0].port))
 *   core_matrix.c:197 align_mem(memblk)
 * 第一参数是 core_portable*（results[0].port 的地址），此处 core_portable 已定义。
 */
extern void portable_init(core_portable *p, int *argc, char *argv[]);
extern void portable_fini(core_portable *p);
extern void *align_mem(void *ptr);
extern void coremark_set_report_iterations(core_portable *p, ee_u32 iterations);
extern void coremark_print_fixed6_line(const char *label, ee_u32 int_part, ee_u32 frac_part);
extern void coremark_print_score_line(ee_u32 ips_int, ee_u32 ips_frac);

#endif /* CORE_PORTME_H */
