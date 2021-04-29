---
title: C Project Structure
date: 2016-05-30
draft: true
categories:
  - C
---

I've been working with C a little more in my free time. Tinkering with OpenGL
and other little side projects in the process. I am gearing up to start to learn
Vulkan for fun and education. While doing this, I realized a couple things about
C.

There is no solid structure on how projects should be organized, or what build
tools should be used. On one side, you have those who are all for Make. On
another you have those in favor of SCons, or CMake, or Ninja, or yet another
build tool that iterrates on top of what is available.

I settled on CMake for now due to relative ease with out of source building.
Which is something you _should_ be doing.

No set standard on how you should cross compile or the best solution for cross
compiling to different architectures or operating systems on said architectures.

After reading the book _C Interfaces and Implementations_ by David R. Hanson, I
am a firm believer in that Header files is your modules interface and should
really only contain prototypes and type definitions. `#ifdef` should be avoided
in there as much as possible. Although not always possible, it is still
something to strive towards.

## Structure

One of my project modules looks like the following.

```txt
.
├── CMakeLists.txt
├── include
│   └── fs.h
└── src
    ├── all
    │   ├── close.c
    │   ├── common.h
    │   └── .......
    ├── posix
    │   ├── chown.c
    │   ├── common.h
    │   └── .......
    └── win
        ├── chown.c
        ├── common.h
        └── .......
```

This project is a wrapper for file system interactions between operating
systems. In particular this is meant to wrap `POSIX` functions with some
debugging for both operating systems.

Depending on the project as well, there may be a `scripts` directory.

```
scripts/
├── init
│   ├── linux.sh
│   ├── osx.sh
│   └── win.sh
└── nuke.sh
```

This sets up the build directories for those specific operating systems. They
usually will define CMake flags like `-DCMAKE_BUILD_TYPE=Debug` and other
various ENV variables.

## Organization

I try to keep all function definitions in separate files. Yes, this is a bit
pedantic and at times kind of frustrating for myself but the alternative is to
have 1000+ lines of code for an implementation that is hard to figure out where
functions live.

I don't mind if compiling on a single thread is slow. From my personal
experience using `make -j8` on one of my projects that utilizes this strategy is
extremely fast.

## Tools

The tools I use to work on these projects are

  * Sublime Text 3
  * Clang and GCC
  * LLDB and GDB
  * CMake
  * Make
  * Docker

I use Docker in this flow to compile with mingw for windows compilation so I do
not muddy up my current system.
