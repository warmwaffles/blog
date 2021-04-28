---
title: Exqlite
date: 2021-04-28
---

An elixir library to interface with SQLite3.

[source code](https://github.com/elixir-sqlite/exqlite)


```elixir
# We'll just keep it in memory right now
{:ok, conn} = Exqlite.Sqlite3.open(":memory:")

# Create the table
:ok =
  Exqlite.Sqlite3.execute(
    conn,
    "create table test (id integer primary key, stuff text)"
  );

# Prepare a statement
{:ok, statement} =
  Exqlite.Sqlite3.prepare(conn, "insert into test (stuff) values (?1)")
:ok = Exqlite.Sqlite3.bind(conn, statement, ["Hello world"])

# Step is used to run statements
:done = Exqlite.Sqlite3.step(conn, statement)

# Prepare a select statement
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select id, stuff from test");

# Get the results
{:row, [1, "Hello world"]} = Exqlite.Sqlite3.step(conn, statement)

# No more results
:done = Exqlite.Sqlite3.step(conn, statement)
```
