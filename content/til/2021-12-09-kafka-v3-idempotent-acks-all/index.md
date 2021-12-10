---
title: Kafka Producer idempotency is enabled by default since 3.0
date: 2021-12-09
section: til
tags:
- kafka
- latency
categories: 
- tuning
---

Since [Apache Kafka 3.0](https://blogs.apache.org/kafka/entry/what-s-new-in-apache6), Producers come with [`enable.idempotency=true`](https://kafka.apache.org/30/documentation.html#producerconfigs_enable.idempotence) which leads to `acks=all`, along with other changes enforced by idempotency.

This means by default Producers will be balanced between latency (no batching) and durability — different from previous versions where the main goal was to reduce latency even by risking durability with `acks=1`.
