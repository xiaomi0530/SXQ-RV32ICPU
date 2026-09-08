#ifndef EMBENCH_PLATFORM_STDLIB_H
#define EMBENCH_PLATFORM_STDLIB_H

#ifndef NULL
#define NULL ((void *)0)
#endif

void abort(void);
void exit(int code);

static inline int abs(int value)
{
    return (value < 0) ? -value : value;
}

static inline long labs(long value)
{
    return (value < 0) ? -value : value;
}

#endif
