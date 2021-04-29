---
title: Error Helpers in C
date: 2017-01-09
categories:
  - Development
tags:
  - c
  - debugging
---

I’ve been writing a lot of C lately for a game I am working on. I am not a
perfect programmer and I would like to catch my bugs before they arise. Thus, I
am attempting to learn Rust in my free time.

## Backtrace

Printing a backtrace in C is not incredibly difficult to accomplish. Although
the following is fairly primitive, it will aid in your ability to discern what
is happening in your program

```c
/// @file core/backtrace.c
#include <execinfo.h>
#include "backtrace.h"

/// @brief Prints a backtrace of up to the last 256 calls
///
/// @param [out] fd The file descriptor ID to write to
void print_backtrace(int fd) {
    void* array[256];
    size_t size = backtrace(array, 256);
    backtrace_symbols_fd(array, size, fd);
}
```

The output will look like the following

```txt
bin/example(print_backtrace+0x22)[0x403002]
bin/example(test_block_insertion+0x218)[0x402b68]
bin/example(main+0x2f)[0x402eef]
/usr/lib/libc.so.6(__libc_start_main+0xf1)[0x7f3e3cb5c291]
bin/example(_start+0x2a)[0x4027fa]
```

As you can see, in a method `test_block_insertion` I call `print_backtrace`.
This is incredibly helpful if you need to determine how deep in the program your
issue occurred.

## Panic

I've been tinkering with Rust in my free time to get a better understanding of
it and I have come to enjoy the `panic!` macro it employs. I like the verb and
decided that it would work perfectly in my daily use.

With some alterations, I just wanted panic to do exactly what its name suggests,
I want the program to panic with a message and abort.

```c
/// @file core/panic.h
#pragma once

#include <stdlib.h>
#include <stdio.h>
#include "backtrace.h"

#ifdef NDEBUG
#define panic(message)
#else
/// @brief Causes the program to abort and print a message
///
/// @param [in] message The error message you wish to spit out to stderr.
#define panic(message)                                               \
    do {                                                             \
        fprintf(stderr, "panicked at: %s:%d\n", __FILE__, __LINE__); \
        fprintf(stderr, "--> %s %s\n", message);                     \
        fprintf(stderr, "--> STACKTRACE START\n");                   \
        print_backtrace(2);                                          \
        fprintf(stderr, "--> STACKTRACE END\n");                     \
        fflush(stderr);                                              \
        abort();                                                     \
    } while (0)
#endif
```

Example usage would be like this

```c
int some_function(uint8_t* data, size_t length) {
  if (length == 0) {
    panic("Zero length buffer provided!");
  }

  //
  // consume data
  //

  return 1;
}
```

Output from this macro will look like the following.

```txt
panicked at: /home/warmwaffles/code/example/rbp_test.c:173
--> message: Failed to insert the block correctly
--> START STACKTRACE
bin/rbp_test(print_stacktrace+0x22)[0x403002]
bin/rbp_test(test_block_insertion+0x218)[0x402b68]
bin/rbp_test(main+0x2f)[0x402eef]
/usr/lib/libc.so.6(__libc_start_main+0xf1)[0x7f3e3cb5c291]
bin/rbp_test(_start+0x2a)[0x4027fa]
--> END STACKTRACE
Aborted (core dumped)
```

I wanted the core dump to take place so that I can inspect it if I need to. Luck
favors the prepared, and I always like to be prepared.

## Assert

I use `assert(expr)` liberally through out my code to ensure that my program
operates as I intend it to. Sometimes I make a mistake and would like to be
notified where it happened and how deep in the call stack it did.

Unfortunately vanilla `assert(expr)` does not do this. But it is a simple enough
macro to override and provide a little more meta information about where it
failed and why.

```c
/// @file core/assert.h
#pragma once

#include <stdlib.h>
#include <stdio.h>
#include "backtrace.h"

#ifdef NDEBUG
#define assert(expr)
#else
#define assert(expr)                                                                     \
    if(!(expr)) {                                                                        \
        fprintf(stderr, "assertion (%s) failed at: %s:%d\n", #expr, __FILE__, __LINE__); \
        fprintf(stderr, "--> STACKTRACE START\n");                                       \
        print_backtrace(2);                                                              \
        fprintf(stderr, "--> STACKTRACE END\n");                                         \
        fflush(stderr);                                                                  \
        abort();                                                                         \
    }
#endif

```

As you can see it looks almost exactly the same as `panic(message)` does.
However, I want the expression to be spit out into `stderr` so that I can see
what expression failed.

```txt
assertion (1 == 0) failed at: /home/warmwaffles/code/example.c:170
--> STACKTRACE START
bin/example(print_backtrace+0x22)[0x4015a2]
bin/example(test_block_insertion+0x1cc)[0x40134c]
bin/example(main+0x2f)[0x40148f]
/usr/lib/libc.so.6(__libc_start_main+0xf1)[0x7f989aaec291]
bin/example(_start+0x2a)[0x40102a]
--> STACKTRACE END
Aborted (core dumped)
```

Found these little bits of code to be useful, and figured others would probably
find it useful as well.
