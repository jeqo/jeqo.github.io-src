---
title: Reducing `acks` doesn't help to reduce end-to-end latency
date: 2021-12-09
section: til
tags:
- kafka
- latency
categories: 
- ops
---

Kafka Producers enforce durability across replicas by setting `acks=all` ([default since v3.0](/til/kafka-v3-idea))