---
title: Ecto SQLite3
date: 2021-04-28
---

An elixir library that provides SQLite3 support for Ecto 3.0

[source code](https://github.com/elixir-sqlite/ecto_sqlite3)

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.SQLite3
end
```
