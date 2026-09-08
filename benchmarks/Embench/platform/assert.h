#ifndef EMBENCH_PLATFORM_ASSERT_H
#define EMBENCH_PLATFORM_ASSERT_H

#include <stdlib.h>

#ifdef NDEBUG
#define assert(expr) ((void)0)
#else
#define assert(expr) ((expr) ? (void)0 : abort())
#endif

#endif
