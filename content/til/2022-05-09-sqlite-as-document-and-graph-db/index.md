---
title: sqlite can be used document and graph database
date: 2022-05-09
section: til

tags:
- sqlite
- database

categories:
- data
---

I found that the use-cases for sqlite keep increasing now the JSON is supported.

This week I found the following presentation: https://www.hytradboi.com/2022/simple-graph-sqlite-as-probably-the-only-graph-database-youll-ever-need
Which makes the case for a simple graph [schema](https://github.com/dpapathanasiou/simple-graph/blob/main/sql/schema.sql), and using SQL out-of-the-box functionality to store graphs and execute traversal queries.

This repository is actually based on this one focused on JSON support and document databases: https://dgl.cx/2020/06/sqlite-json-support
