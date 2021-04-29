---
title: CMake, Or Not To CMake
draft: true
categories:
  - CMake
  - Build Tools
---

I've been using CMake for quite some time now and feel that it's a very
difficult topic to discuss and compare with other tools. This is because CMake
is not a build tool itself, rather it is a tool that builds the tools to build
your stuff.

Confusing isn't it?

At first I could not grasp this concept because I was accustomed to
[Makefiles][make] and [Rakefiles][rake]. For small projects that had a few C
files and some header files this was sustainable and practical. This has its
limitations.

When you start to build a game using OpenGL and [GLFW][glfw] and need a bunch of
libraries to compile your application with, is when you will start reaching the
limitations and exensibility problems that [make][make] and [rake][rake] have.

Simply doing `-I` will solve issues with linking dynamically however, if I want
to statically link my binaries with the libraries they use. Then it becomes more
complicated to deal with in primitive build libraries.

CMake really shines in this department with helping you modularize your code and
keep concerns separate from other libraries. But, where it lacks flexibility is
the relative ease in which you can write functions to do custom build stuff. For
example, in Vulkan, you are required to compile your GLSL or HLSL shader code
into bytecode before you can give it to the driver. Another examples is if you
want to use doxygen to compile your documentation or any other sort of
documentation generator it is not straight forward to do this.

If the aim is to be cross platform and be able to compile on a Windows machine,
linux machine, or apple machine you have to write portable code. Your build
tools must also be portable as well.

Make is notorious for not being able to run on Windows well. GNU Make can run on
Windows, but that requires you to have Cygwin installed in order to invoke it.

[Ninja][ninja] is very similar to Make. However it was designed to be cross
platform from the very beginning. I have not used it much, although I have used
it to compile stuff in Windows.

Next up on the ladder is [Scons][scons] and [Rake][rake]. I have had a lot more
experience with Rake than I have Scons because I primarily script in ruby. Both
of these libraries are fully scriptable and offer the highest flexibility in
terms of accomplishing build tasks. However, if you want your library to be used
by others, then it probably is not the best choice to use.


[rake]: https://en.wikipedia.org/wiki/Rake_(software)
[make]: https://en.wikipedia.org/wiki/Makefile
[glfw]: http://www.glfw.org/
[scons]: http://scons.org/doc/HTML/scons-user.html
[ninja]: https://ninja-build.org/
