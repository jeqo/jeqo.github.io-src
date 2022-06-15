---
title: 
date: 2022-06-17
section: posts
draft: true

tags:
- kafka-streams

categories:
- dev
- poc
---

TODO:

- [ ] Introduce the concept of Stream-time 
- [ ] Clarify the concept with use-cases where Stream-time is used
- [ ] Introduce PoC: Kafka Producer Progress Control

---

Kafka Streams is in many ways governed by the concept of time.
For instance, as soon as stateful operations are used, the event time drives how events are grouped, joined, and emitted.

[Stream-time](https://developer.confluent.io/learn-kafka/kafka-streams/time-concepts/#stream-time) is the concept within Kafka Streams representing the largest timestamp seen by the the stream application (per partition).
In comparison with wall-clock time (i.e. system time) that is the time at the execution of an application, stream-time is driven by the data seen.
This is what ensures that the results produced by a Kafka Streams application are reproducible.

One nuance of stream-time is that it needs incoming events to tick.
This could represent an issue for events that are sparse in time, and we want results (e.g. windows to be closed and emit, punctiation to be calculated) to be produced more often.

This is a known issue, and there are some proposals to overcome it in certain parts of the framework, e.g. [KIP-424](https://cwiki.apache.org/confluence/display/KAFKA/KIP-424%3A+Allow+suppression+of+intermediate+events+based+on+wall+clock+time).
This post is going to cover a proof-of-concept to instrument producers to emit contol messages that can be used to advance stream time.

