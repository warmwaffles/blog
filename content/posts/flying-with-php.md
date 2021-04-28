---
title: Flying with php
date: 2012-11-30T12:00:00
comments: false
sharing: false
categories:
  - programming
  - php
---

I discovered the [Flight][flight] micro-php framework this week. I found it
because I was looking for a simple PHP 5.3+ framework that didn't have a large
amount of extra cruft. I had a project to do for my Database class at UTSA where
we had to utilize an Oracle database. Not exactly my choice for databases, but
we had to make do with what we were given.

It is a very sparse framework that looks very similar to [Sinatra][sinatra]
except it is even lighter. [Flight][flight] provided me ways to easily extend
and customize.

I used a fairly straight forward file structure:

```
|-assets
|-config
|-controllers
|-db
|-lib
|-models
|-views
```

Flight doesn't come with a `Database` class. So you will have to roll your own
or use an ORM or use Mike Cao's [Sparrow][sparrow] library. I haven't had a
chance to play with it yet, but it looks very promising. Unfortunately, it does
not support Oracle, so I had to roll my own implementation, and it's not pretty
by any means.

I look forward to playing with this library some more, and hopefully building
something with it soon.

[flight]: https://github.com/mikecao/flight
[sinatra]: https://github.com/sinatra/sinatra/
[sparrow]: https://github.com/mikecao/sparrow
