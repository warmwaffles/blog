---
title: Elixir Distributed SQLite Databases
draft: true
categories:
  - elixir
---

# Elixir Distributed SQLite Databases

Title is a work in progress.

During the rolling power outages faced in Texas in 2021 during the winter storm,
I spent some time building an SQLite3 and Elixir driver. My primary driver for
doing so is that I wanted to run a distributed Elixir cluster on a bunch of
Raspberry Pi's and wanted a database that was excellent for embedded devices and
resliant to power outages.

I also have a huge love for SQLite3 that I can't quite put my finger on. It can
accomplish so much without having a large complex infrastructure in place.
Although what I am about to propose, is going to stretch that claim _very_ far.

The hardware I want to use would ideally have the following.

* Raspberry Pi 4 with 4GB of RAM.
* At least 500GB of usable diskspace.

I'm not constrained to just Raspberry Pi's, but I believe if I can design for
this use case, I can scale up into larger hardware if desired. It's also cheaper
to run a cluster of Pi's for development, than a cluster of servers at home.

## Requirements

* Nodes can be added at any time.
* Nodes can be removed at any time.
* Nodes load balance data.
* Writes are routed to the correct node.
* Reads are routed to the correct node.

## The Problem

I want to store documents and timeseries data on each of the nodes in the
cluster. The data will be partitioned by a specific identifier that is unique to
each piece of data. This would be the account id or user id that the piece of
data belongs to.

The reason for this, is that backups become simplified and easy to restore
versus distributing the data across all nodes in a round robin fashion.

## The Solution High Level
