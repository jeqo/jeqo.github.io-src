---
title: "Kafka Streams: Tick stream-time with control messages"
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
For instance, as soon as stateful operations are used, the event-time drives how events are grouped, joined, and emitted.

[Stream-time](https://developer.confluent.io/learn-kafka/kafka-streams/time-concepts/#stream-time) 
is the concept within Kafka Streams representing the largest timestamp seen by the the stream application (per-partition).
In comparison with wall-clock time (i.e. system time) — at the execution of an application — stream-time is driven by the data seen by the application.
This ensures that the results produced by a Kafka Streams application are reproducible.

One nuance of stream-time is that it _needs_ incoming events to "tick".
This could represent an issue for events that are sparse in time, and we expect results to be produced more often (e.g. windows to be closed and emit, punctiation to be calculated).

This is a known issue, and there are some proposals to overcome it in certain parts of the framework, 
e.g. [KIP-424](https://cwiki.apache.org/confluence/display/KAFKA/KIP-424%3A+Allow+suppression+of+intermediate+events+based+on+wall+clock+time).

This post covers a proof-of-concept instrumenting producers to emit contol messages to advance stream time.

<!--more-->

Let's first review a scenario where results are not emitted because stream-time is not ticking: emitting results when windows are closed.

For instance,
[session windows](https://developer.confluent.io/learn-kafka/kafka-streams/windowing/#session) aggregations with suppress
allow the application to hold results (count) until the window is closed:

```java
KStream<String, String> myStream = builder.stream("topic-A");
Duration inactivityGap = Duration.ofMinutes(3);

myStream.groupByKey()
    .windowedBy(SessionWindows.ofInactivityGapWithNoGrace(inactivityGap))
    .count()
    .suppress(Supressed.untilWindowCloses(BufferConfig.unbounded()))
    .toStream();
```

This works as expected, _as long as your stream ("topic-A") keeps getting events_.

Let's review this in more detail:

Let's say we have received 3 events, and system time has progress.
(Remember, wall-clock time is not used to trigger behaviour on windowing)


```
Session window
- inactivity-gap = 3
- stream-time=3
- wall-clock=5



      xx        xx   xx         │
      xx        xx   xx         │
────────────────────────────────┼─────────────────────────────────►
 0     1      2      3     4    │ 5     6     7     8    9     10
                                │
                            wall-clock
```

We are still within the `inactivity-gap`, therefore no result should be emitted.

As time progress, the gap between wall-clock and stream-time increases, no results are emitted because stream-time is not moving forward.

```
Session window
- inactivity-gap = 3
- stream-time=3
- wall-clock=7



      xx        xx   xx                      │
      xx        xx   xx                      │
─────────────────────────────────────────────┼────────────────────►
 0     1      2      3     4      5     6    │7     8    9     10
                                             │
                                        wall-clock
```

Only when a new event arrives, stream-time moves, suppress condition is passed, and results are produced


```
Session window
- inactivity-gap = 3
- stream-time=8
- wall-clock=7



      xx        xx   xx                           yy      │
      xx        xx   xx                           yy      │
──────────────────────────────────────────────────────────┼───────►
 0     1      2      3     4      5     6     7     8    9│    10
                                                          │
                                                      wall-clock

Results:

- session-x (window=1-3) : count=3

```

