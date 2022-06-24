---
title: "Kafka Streams: Tick stream-time with control messages"
date: 2022-06-17
section: posts

tags:
- kafka-streams

categories:
- dev
- poc
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

## Scenario: Emit window closed events

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

Only when a new event arrives, stream-time moves, then suppress condition passes, and results are produced


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

There are some alternatives to deal with this scenario.
The first is to ignore it: if events arrive often enough and there is no penalty if there is longer waiting time to emit results (i.e. until new events arrive to _that partition_) then it should be fine to leave the default behaviour.
A second, naive, option is to produce "control" events with certain frequency to _all_ partitions, so there's a stronger guarantee that stream-time ticks at most every minute.

> This concept of control messages is not new.
> In fact, [it's used by transactions in Kafka](https://cwiki.apache.org/confluence/display/KAFKA/Transactional+Messaging+in+Kafka)
> to mark transactions events (begin, commit, abort).
>
> At the moment, [control events are not supported natively](https://issues.apache.org/jira/browse/KAFKA-1639);
>but for this proof-of-concept, sending empty messages with empty keys could get us a similar behavior.

One drawback of using periodic messages is that the topic could end up being mostly by control messages than by actual events.
This could not just affect the consumer experience by having to filter them out,
but it could increase the cost of storage, 
as the messages still includes the [Kafka record envelope](https://kafka.apache.org/documentation/#messageformat).

## Proof-of-concept

Instrumenting the Producers to send control messages is a good idea, 
but the frequency can be improved by implementing a more sophisticated way to emit control messages only when needed.

```
┌─────────────────┐     events         ┌─────────────────┐
│  Main           ├──────────────────► │                 │
│  Producer       │                    │   Kafka         │
│  ┌──────────────┤ack + metadata(tp)  │   cluster       │
│  │ Progress     │◄────────────────── │                 │
│  │ Controller   │                    │                 │
└──┴────────────┬─┘                    └──────▲──────────┘
        <tp:ts> │                             │
        t1-p0:10└─────────────────────────────┘
        t1-p1:20         control messages
          ...
```

The design of this instrumentation includes a thread to be added to the Producer (e.g. via interceptors).
This single-thread per Producer keeps track of "stream-event" per topic partition in a concurrent map.
The concurrent map is updated when acknowledge messages are returned to the producer including the latest topic partition.

Within the thread, the map is constantly evaluated against a set of configuration to check the difference between stream-time (at the producer) and wall-clock time.
By configuration, when this gap is large enough, we can schedule to send control messages and remove the topic-partition from the map.

An implementation of this proof-of-concept is here: <https://github.com/jeqo/poc-apache-kafka/tree/main/clients/producer-progress-control>

The configuration includes how long to wait without messages in order to produce control messages.

Sometimes one additional message is not enough, as this message might fall before the inactivity gap, therefore not producing an event for closed windows. This is why the configuration includes options to schedule sending more than one messages with backoff strategy.

The implementation has an Interceptor and a Producer wrapper instrumentation. 

For instance, in [this topology](https://github.com/jeqo/poc-apache-kafka/blob/a67dbc5205d5ee9a9e5e996778784c7cf13ba74a/streams/examples/src/main/java/poc/stateless/StatefulSessionWindowWithSuppress.java) transactions are received, gruoped by user ID, and repartitioned:

```java
  public Topology topology() {
    final var b = new StreamsBuilder();

    b.stream(inputTopic, Consumed.with(keySerde, valueSerde))
        .selectKey((s, transaction) -> transaction.userId())
        .repartition(Repartitioned.with(keySerde, valueSerde))
        .groupByKey()
        .windowedBy(SessionWindows.ofInactivityGapWithNoGrace(Duration.ofSeconds(30)))
        .count()
        .suppress(Suppressed.untilWindowCloses(BufferConfig.unbounded()))
        .toStream()
        .selectKey((w, aLong) -> "%s@<%s,%s>".formatted(w.key(), w.window().start(), w.window().endTime()))
        .to(outputTopic, Produced.with(keySerde, outputValueSerde));

    return b.build();
  }

```

The transactions are aggregated in sessions windows that have 30 seconds of inactivity gap (i.e. timeout) after the stream has been repartitioned.

In this case, control messages can be used on the repartition topic to tick stream-time.

The interceptor can be added via configuration:

```java
    props.put(StreamsConfig.producerPrefix(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG), ProgressControlInterceptor.class.getName());
    props.put("progress.control.start.ms", 60000);
    props.put("progress.control.topics.include", "ks1-KSTREAM-REPARTITION-0000000002-repartition");
```

To produce one message after 60 seconds from the last message.
The instrumentation includes a value to filter the topics to include.

This conclues the proof-of-concept on how to understand the impact of stream-time on Kafka Streams aggregations and how to tweak the behavior with control messages.

