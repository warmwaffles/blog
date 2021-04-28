---
title: High Level Low Level Compilation
date: 2012-08-08
categories:
  - programming
  - compilers
  - ruby
---

I have been staring at Ruby for so long that I have become disgusted with low
level languages like C or C++. Mid level languages like Java still make me
cringe when I look at them. As I sit and write code in Ruby that runs on a
terribly slow VM I begin to think.

Why don't high level languages like Ruby or Python compile into assembly level
code like C does when it is compiled?

I know compilers and interpreters are difficult to design and program. Someone,
somewhere, has to feel the pain that I do when looking at C, Java, C#, etc...
and not wonder why a high level syntax wont compile into low level assembly
code.

I wrote a Scheme interpreter in Java for my Programming Languages class. That
was probably the most eye opening experience that I have really had in
development. Not simply because Lisp like languages are terribly simple, but
that an interpreter can run the code at a decent speed (minus garbage
collection).

Now I am not saying, take Ruby and make it into assembly level code. No, that is
not my point. Ruby is a *VERY* dynamic language that can hinder speed. Nay, what
I am saying is that we can have a static typed language that has a very verbose
and simple syntax that can be fun and beneficial to all.
