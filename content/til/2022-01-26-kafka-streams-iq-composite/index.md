---
title: Kafka Streams abstracts access to multiple tasks state stores when reading
date: 2022-01-26
section: til
tags:
- kafka-streams
- api
categories:
- dev
---

Kafka Streams applications could scale either horizontally (add more instances) or vertically (add more threads).
When scaled vertically, multiple tasks store multiple partitions locally.
An interesting question is whether Kafka Streams gives access when reading (i.e. [Interactive Queries](https://docs.confluent.io/platform/current/streams/developer-guide/interactive-queries.html)) to these stores, and how does it manage to abstract the access to different stores managed by multiple tasks.

<!--more-->
The answer is yes, Kafka Streams abstracts away tasks and multiple stores.
Internally it's implemented by using `CompositeReadOnly*Stores`:

- https://github.com/apache/kafka/blob/trunk/streams/src/main/java/org/apache/kafka/streams/state/internals/CompositeReadOnlyKeyValueStore.java
- https://github.com/apache/kafka/blob/trunk/streams/src/main/java/org/apache/kafka/streams/state/internals/CompositeReadOnlyWindowStore.java
- https://github.com/apache/kafka/blob/trunk/streams/src/main/java/org/apache/kafka/streams/state/internals/CompositeReadOnlySessionStore.java

Where `StoreProvider` gives access to the internal stores managed by the Kafka Streams instance tasks:

```java
final List<ReadOnlySessionStore<K, V>> stores = storeProvider.stores(storeName, queryableStoreType);
for (final ReadOnlySessionStore<K, V> store : stores) {
    try {
        final KeyValueIterator<Windowed<K>, V> result =
            store.findSessions(key, earliestSessionEndTime, latestSessionStartTime);

        if (!result.hasNext()) {
            result.close();
        } else {
            return result;
        }
    } catch (final InvalidStateStoreException ise) {
        throw new InvalidStateStoreException(
            "State store  [" + storeName + "] is not available anymore" +
                " and may have been migrated to another instance; " +
                "please re-discover its location from the state metadata.",
            ise
        );
    }
}
return KeyValueIterators.emptyIterator();
```

I know about the abstraction, but was interesting to find out how it's actually implemented.