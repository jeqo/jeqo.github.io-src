---
slug: kip-617
title: "KIP: Allow Kafka Streams State Stores to be iterated backwards"
date: 2020-05-18
---

## Motivation

Fetching range of records from Kafka Streams state stores comes with an iterator to traverse elements *from oldest to newest*, e.g `ReadOnlyWindowStore#fetch(K key, long fromTime, long toTime)` mentions: 

> For each key, the iterator guarantees ordering of windows, **starting from the oldest/earliest**"

Similar guarantees are provided on other fetch and range operations. But in the case of `key` ranges, there are some nuances regarding order:

> The returned iterator must be safe from {@link java.util.ConcurrentModificationException}s and must not return null values. **No ordering guarantees are provided**.

Ordering is not guaranteed as backing structure is based on maps keyed by `o.a.k.common.utils.Bytes`. 
Though, `Bytes` support `Lexicographic` byte array comparison, which defines ordering in-memory and `RocksDB` stores.

These APIs constraint the usage of local state store for some use-cases:

When storing records on time windows, or records by key; and an operation wants to return the _last_ `N` values inserted withing a time range containing `M` records: Currently there is no alternative other than iterating records from oldest to newest--traversing `M` records, where `M` >> `N`.  

If a _backward read direction_ option becomes available, then we could start from the latest record within a time range and go _backwards_, returning the first `N` value more efficiently.

At [Zipkin Kafka-based storage](github.com/openzipkin-contrib/zipkin-storage-kafka), we are planning to use this feature to replace two KeyValueStores (one for traces indexed by id, and another with trace_ids indexed by timestamp) for one WindowStore. A backward read direction will allow to support queries like: "within this time range, find the last traces that match this criteria", and return latest values quickly.

Internally, both implementations: persistent (RocksDB), and in-memory (TreeMap) support reverse/descending iteration:

```java
 final RocksIterator iter = db.newIterator();
 iter.seekToFirst();
 iter.next();

 final RocksIterator reverse = db.newIterator();
 reverse.seekToLast();
 reverse.prev();
```

```java
final TreeMap<String, String> map = new TreeMap<>();
final NavigableSet<String> nav = map.navigableKeySet();
final NavigableSet<String> rev = map.descendingKeySet();
```

### Reference issues

- https://issues.apache.org/jira/browse/KAFKA-9929
- https://issues.apache.org/jira/browse/KAFKA-4212

## Proposed Changes

There are 2 important ranges in Kafka Streams Stores:

* Key Range
* Time Range

### Reverse Key Ranges

Add a new interface for reverse `KeyValueStore`

```java
public interface ReadOnlyReverseKeyValueStore<K, V> {
    KeyValueIterator<K, V> reverseRange(K from, K to);
    KeyValueIterator<K, V> reverseAll();
}
```

And create a new interface on top of `KeyValueStore`:

```java
public interface KeyValueStoreWithReverseIteration<K, V> extends KeyValueStore<K, V>, ReadOnlyReverseKeyValueStore<K, V> {
//...
}
```

### Backward Time Ranges

Window and Session stores are based on a set of KeyValue Stores (Segments) organized by a time-based index.
Therefore, for these stores time-range is more important than key-range to lookup for values.

A new interfaces will be added for each Store type, including backward methods:

```java
public interface ReadOnlyBackwardWindowStore<K, V> {
    @Deprecated
    WindowStoreIterator<V> backwardFetch(K key, long timeFrom, long timeTo);
    WindowStoreIterator<V> backwardFetch(K key, Instant from, Instant to) throws IllegalArgumentException;
    @Deprecated
    KeyValueIterator<Windowed<K>, V> backwardFetch(K from, K to, long timeFrom, long timeTo);
    KeyValueIterator<Windowed<K>, V> backwardFetch(K from, K to, Instant fromTime, Instant toTime)
            throws IllegalArgumentException;
    KeyValueIterator<Windowed<K>, V> backwardAll();
    @Deprecated
    KeyValueIterator<Windowed<K>, V> backwardFetchAll(long timeFrom, long timeTo);
    KeyValueIterator<Windowed<K>, V> backwardFetchAll(Instant from, Instant to) throws IllegalArgumentException;
}
```

```java
public interface ReadOnlyBackwardSessionStore<K, AGG> {
    KeyValueIterator<Windowed<K>, AGG> backwardFetch(final K from, final K to);
    KeyValueIterator<Windowed<K>, AGG> backwardFindSessions(final K key, final long earliestSessionEndTime, final long latestSessionStartTime);
    KeyValueIterator<Windowed<K>, AGG> backwardFindSessions(final K keyFrom, final K keyTo, final long earliestSessionEndTime, final long latestSessionStartTime);
}
```

And both `SessionStore` and `WindowStore` will extend these new APIs:

```java
public interface WindowStoreWithBackwardInteration<K, V> extends WindowStore<K, V>, ReadOnlyBackwardWindowStore<K, V> {
// ...
}
```

```java
public interface SessionStoreWithBackwardIteration<K, AGG> extends SessionStore<K, AGG>, ReadOnlyBackwardSessionStore<K, AGG> {
//...
}
```

Class hierarchy will change from:

{{< zoom-img src="/images/drafts/kip-allow-state-stores-to-iterate-backwards/as-is.png" >}}

To: 

{{< zoom-img src="/images/drafts/kip-allow-state-stores-to-iterate-backwards/to-be.png" >}}

## Compatibilily, Deprecation, and Migration Plan

As new top interfaces will be implemented by internal components (e.g. RocksDB, InMemory, etc). supporting old one already, current users won't be affected.

New users will be able to choose between current APIs (forward-only) or proposed ones (forward+backward).

## Rejected Alternatives

* ~~Initially it was considered to have additional parameter on all readOnlyStore methods e.g. Store#fetch(keyFrom, keyTo, timeFrom, timeTo, ReadDirection.FORWARD|BACKWARD), but has been declines as passing arguments in inverse is more intuitive. As this could cause unexpected effects in future versions, a flag has been added to overcome this.~~
* Implicit ordering by flipping `from` and `to` variables has been discouraged in favor of a more explicit approach based on new interfaces that make explicit the availability of reverse and backward fetch operations.