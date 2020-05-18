# KIP: Allow Kafka Streams State Stores to iterate backwards

## Motivation

Fetching a range of results from Kafka Streams state stores comes with a default iterator to go through elements from oldest to newest direction.

e.g `ReadOnlyWindowStore#fetch(K key, long fromTime, long toTime)` mentions: "For each key, the iterator guarantees ordering of windows, starting from the oldest/earliest"

Similar guarantees are provided on other fetch operations.

While abstracting the exposure of how `iterator` is built, this constraints the usage of local state store for some use cases:

When windowing records, and an operation wants to return the last `N` values inserted withing a time range with `M` records, then currently there is no option other than iterating from oldest to newest---iterating `M` records, where `M` >> `N`.  

If a _backward read direction_ becomes available, then we started from the head of the range and return the first `N` value.

At [Zipkin Kafka-based storage](github.com/openzipkin-contrib/zipkin-storage-kafka), we are planning to use this feature to replace KeyValueStores (one for traces indexed by id, and another with trace_ids indexed by timestamp) for one WindowStore. A backward read direction will allow queries to support: "within this time range, find the last traces that match this criteria", and return latest values quickly.

### Reference issues

- https://issues.apache.org/jira/browse/KAFKA-9929
- https://issues.apache.org/jira/browse/KAFKA-4212

## Proposed Changes

Introduce a enum type `ReadDirection.BACKWARD|FORWARD` to `ReadOnlyKeyValueStore#range|all` and `ReadOnlyWindowStore#fetch|fetchAll|all`:

```java
public enum ReadDirection {
    FORWARD, BACKWARD
}
```

```java
public interface ReadOnlyKeyValueStore<K, V> {
    default KeyValueIterator<K, V> range(K from, K to) {
        return range(from, to, ReadDirection.FORWARD);
    }

    KeyValueIterator<K, V> range(K from, K to, ReadDirection direction);

    default KeyValueIterator<K, V> all() {
        return all(ReadDirection.FORWARD);
    }

    KeyValueIterator<K, V> all(ReadDirection direction);
}
```

```java
public interface ReadOnlyWindowStore<K, V> {
    WindowStoreIterator<V> fetch(K key, Instant from, Instant to, ReadDirection direction) throws IllegalArgumentException;

    default WindowStoreIterator<V> fetch(K key, Instant from, Instant to) throws IllegalArgumentException {
        return fetch(key, from, to, ReadDirection.FORWARD);
    }

    KeyValueIterator<Windowed<K>, V> fetch(K from, K to, Instant fromTime, Instant toTime, ReadDirection direction)
        throws IllegalArgumentException;
        throws IllegalArgumentException;


    default KeyValueIterator<Windowed<K>, V> fetch(K from, K to, Instant fromTime, Instant toTime)
        throws IllegalArgumentException {
        return fetch(from, to, fromTime, toTime, ReadDirection.FORWARD);
    }

    KeyValueIterator<Windowed<K>, V> all(ReadDirection direction);


    default KeyValueIterator<Windowed<K>, V> all() {
        return all(ReadDirection.FORWARD);
    }

    KeyValueIterator<Windowed<K>, V> fetchAll(Instant from, Instant to, ReadDirection direction) throws IllegalArgumentException;

    default KeyValueIterator<Windowed<K>, V> fetchAll(Instant from, Instant to) throws IllegalArgumentException {
        return fetchAll(from, to, ReadDirection.FORWARD);
    }
}
```

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

## Compatibilily, Deprecation, and Migration Plan

Default methods would be in-place to not affect previous versions.