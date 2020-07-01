---
slug: kip-634
title: "KIP-634: Complementary support for headers in Kafka Streams"
date: 2020-05-31
---

## Motivation

Headers are transiently passed over a Kafka Streams topology. To act on them, Processor API has to be used since ([KIP-244](https://cwiki.apache.org/confluence/display/KAFKA/KIP-244%3A+Add+Record+Header+support+to+Kafka+Streams+Processor+API)).

Although current support is useful for instrumentations that need to access headers, it becomes cumbersome for users to access headers on common Kafka Streams DSL operations (e.g filtering based on header value) as requires using a `Transformer`/`Processor` implementation.

### Related JIRA issues

* <https://issues.apache.org/jira/browse/KAFKA-7718>

## Proposed Changes

1. Include a new type, to map value and headers.
1. Include `ValueAndHeaders` serde to serialize values if needed.
1. Include KStreams operator to map headers into the value pair: `ValueAndHeaders`.
1. Include KStreams operator to set and remove headers.

In accordance with KStreams DSL Grammar, we introduce the following elements:

* **KStream** DSLObject with new operations:
  * **setHeader** DSLOperation
  * **setHeaders** DSLOperation
  * **removeHeader** DSLOperation
  * **removeHeaders** DSLOperation
  * **removeAllHeaders** DSLOperation
  * **removeAllHeaders** DSLOperation
  * **withHeaders** DSLOperation

## New or Changed Public Interfaces

```java
// New type
public class ValueAndHeaders <V> {
    private final V value;
    private final Headers headers;

    //...
}
// With Serde to persist/join if needed
public class ValueAndHeadersSerde<V> {
}
```

```java
public class KStream {
    //Functions to act on headers
    KStream<K, V> setHeaders(final SetHeadersAction<? super K, ? super V> action, final Named named);

    KStream<K, V> setHeaders(final SetHeadersAction<? super K, ? super V> action);

    KStream<K, V> setHeader(final SetHeaderAction<? super K, ? super V> action, final Named named);

    KStream<K, V> setHeader(final SetHeaderAction<? super K, ? super V> action);

    KStream<K, V> removeHeaders(final Iterable<String> headerKeys, final Named named);

    KStream<K, V> removeHeaders(final Iterable<String> headerKeys);

    KStream<K, V> removeHeader(final String headerKey, final Named named);

    KStream<K, V> removeHeader(final String headerKey);

    KStream<K, V> removeAllHeaders(final Named named);

    KStream<K, V> removeAllHeaders();

    KStream<K, ValueAndHeaders<V>> withHeaders(final Named named);

    KStream<K, ValueAndHeaders<V>> withHeaders();
    //...
}

public interface SetHeadersAction<K, V> {
    Iterable<Header> apply(final K key, final V value);
}

public interface SetHeaderAction<K, V> {
    Header apply(final K key, final V value);
}
```

This new APIs will allow usages similar to:

```java
kstream.withHeaders() // headers mapped to value
       .filter((k, v) -> v.headers().headers("k").iterator().hasNext())
       .filter((k, v) -> Arrays.equals(v.headers().lastHeader("k").value(), "v".getBytes())) // filtering based on header value
       .groupByKey(Grouped.with(Serdes.String(), new ValueAndHeadersSerde<>(Serdes.String()))) // val/headers serialization
       .reduce((oldValue, newValue) -> {
         newValue.headers().add("reduced", "yes".getBytes()); // user deciding how to merge headers
         return new ValueAndHeaders<>(oldValue.value().concat(newValue.value()), newValue.headers());
       })
       .mapValues((k, v) -> {v.headers().add("foo", "bar".getBytes()); return v;}) // mutate headers
       .setHeader((k, v) -> new RecordHeader("newHeader", "val".getBytes())) // add more headers
       .mapValues((k, v) -> v.value()) // return to value
       .to("output")
```

## Compatibilily, Deprecation, and Migration Plan

* New functions will be supported since 2.0+, as KIP-244 adopted.
* No existing stores or functions are affected.

### Potential next steps

* Use a similar approach for other record metadata (e.g. offset, topic, partition), though in this case only read-only operations are required. 
Related KIP: <https://cwiki.apache.org/confluence/display/KAFKA/KIP-159%3A+Introducing+Rich+functions+to+Streams>

## Rejected alternatives

1. Expand `KeyValue` to support headers. This will affect all current APIs, from KStream/KTable to Stores.
1. Adding `mergeHeaders` functions to join/aggregation. Although this will extend support for headers, will add complexity to existing functions.
