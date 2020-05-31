---
title: "KIP: Additional headers support on Kafka Streams"
date: 2020-05-31
---

## Motivation

Headers are transiently passed over a Kafka Streams topology. To act on them, Topology API has to be used.

Headers usually hold operational information that is important on the business logic of a Kafka Streams application.


## Proposed Changes

1. Include KStreams operator to map headers to KeyValue.
1. Include ValueAndHeaders operator serde to serialize value with Headers.
1. Include KStreams operator to set headers.
1. Include KStreams join and operator functions to merge Headers.

```java

public class ValueAndHeaders <V> {
    private final V value;
    private final Headers headers;

    //...
}

public class ValueAndHeadersSerde<V> {
    //TODO
}

public class KStream {
    public KeyValue<K, ValueAndHeaders<V>> withHeaders();
    public KeyValue<K, V> applyHeaders(KeyValue<K, ValueAndHeaders<V>> map);
}
```

```java

kstream.withHeaders()
       .filter((k, v) -> v.headers.lastValue())

```

```java
kstream.withHeaders()
       .map((k, v) -> v.headers.add("foo", "bar".getBytes()))
       .applyHeaders()
       .to("output")
```

## Compatibilily, Deprecation, and Migration Plan

## Rejected alternatives

### Add Headers to KeyValue or KStreams operators

### Include Headers on Kafka Streams stores
