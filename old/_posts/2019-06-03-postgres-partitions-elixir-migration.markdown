---
layout: post
title: Postgres Partitions in Elixir Migration
date: 2019-06-03 12:00:00
categories:
  - postgres
  - elixir
  - ecto
---

Postgres 11 has a nifty feature around partitions. When a partition exists for a
range of values, when you insert into the parent table it'll get routed to the
correct partition. When you update that record's partition key it will get moved
to the correct partition. A default partition feature exists as well so that if
you do try to insert something that doesn't belong in any available partitions,
it will be put there instead.

I wanted to use this feature to track transactions in a game economy. Where all
transactions were stored with their transacted date as the partition key.

Here is the `Wallet` model.

```elixir
defmodule Game.Wallets.Wallet do
  alias Game.Wallets.Transaction
  alias Game.Wallets.Wallet

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          balance: Decimal.t(),
          locked_at: DateTime.t(),
          deleted_at: DateTime.t(),
          updated_at: DateTime.t(),
          inserted_at: DateTime.t()
        }
  @primary_key {:id, :binary_id, autogenerate: false, read_after_writes: true}
  @foreign_key_type :binary_id
  schema("wallets") do
    field(:name, :string)

    field(:balance, :decimal, default: 0.0)

    field(:locked_at, :utc_datetime)
    field(:deleted_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:inserted_at, :utc_datetime)

    has_many(:transactions, Transaction)
  end
end
```

Here is the `Transaction` model.


```elixir
defmodule Game.Wallets.Transaction do
  alias Game.Wallets.Wallet

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          occurred_at: DateTime.t(),
          credit: Decimal.t(),
          debit: Decimal.t(),
          description: String.t(),
          wallet_id: Ecto.UUID.t()
        }
  @primary_key {:id, :binary_id, autogenerate: false, read_after_writes: true}
  @foreign_key_type :binary_id
  schema("transactions") do
    field(:occurred_at, :utc_datetime)

    field(:credit, :decimal, default: 0.0)
    field(:debit, :decimal, default: 0.0)

    field(:description, :string)

    belongs_to(:wallet, Wallet, type: :binary_id)
  end
end
```

A fairly simple model, where I expect there to be millions of transactions.
Something that can not live well on a single partition and be performant. So we
need to make a migration that can handle this.

```ex
defmodule Game.Repo.Migrations.CreateWalletsAndTransactions do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE wallets (
      id          UUID NOT NULL DEFAULT uuid_generate_v4(),
      name        TEXT NOT NULL,
      balance     DECIMAL(20, 2) NOT NULL DEFAULT 0.0,
      inserted_at TIMESTAMP NOT NULL DEFAULT now(),
      updated_at  TIMESTAMP NOT NULL DEFAULT now(),
      locked_at   TIMESTAMP,
      deleted_at  TIMESTAMP,
      PRIMARY KEY(id),
      CONSTRAINT wallets_balance_ck CHECK(balance >= 0)
    )
    """
  end

  def down do
    execute "DROP TABLE wallets CASCADE"
  end
end
```

We need to create the base paritition and default partition.


```elixir
execute """
CREATE TABLE transactions (
  id          UUID           NOT NULL DEFAULT uuid_generate_v4(),
  wallet_id   UUID           NOT NULL REFERENCES wallets(id),
  occurred_at TIMESTAMP      NOT NULL DEFAULT now(),
  credit      DECIMAL(20, 2) NOT NULL DEFAULT 0.0,
  debit       DECIMAL(20, 2) NOT NULL DEFAULT 0.0,
  description TEXT
) PARTITION BY RANGE (occurred_at)
"""
```

Then we need to create the default partition.

```elixir
execute "CREATE TABLE transactions_default PARTITION OF transactions DEFAULT"
```

Now the fun part is I needed a bunch of partitions created but didn't want to
type them all out by hand / copy paste.

```elixir
start_date = beginning_of_month(~D[2019-04-01])

for months <- 0..47 do
  create_partition("transactions", calculate_next_month(start_date, months))
end
```

The `#create_partition/2`, `#beginning_of_month/1`, and `#calculate_next_month/2`
are defined as follows.

```elixir
defp create_partition(table, date) do
  start_date = date

  stop_date =
    date
    |> Date.add(Date.days_in_month(date))

  month =
    start_date.month
    |> Integer.to_string()
    |> String.pad_leading(2, "0")

  execute """
  CREATE TABLE #{table}_p#{start_date.year}_#{month}
  PARTITION OF #{table} FOR VALUES
  FROM ('#{start_date}')
  TO ('#{stop_date}')
  """
end
```

```elixir
defp beginning_of_month(date) do
  if date.day == 1 do
    date
  else
    Date.add(date, -(date.day - 1))
  end
end
```

```elixir
defp calculate_next_month(date, 0), do: date

defp calculate_next_month(date, months) do
  next = Date.add(date, Date.days_in_month(date))
  calculate_next_month(next, months - 1)
end
```

I defined these methods in the `Game.Repo.Migrations.CreateWalletsAndTransactions`
but definitely will extract these into a utility function to be used later.

Feel free to use it or manipulate it how ever. If you come up with a better
solution I'd really like to see it.
