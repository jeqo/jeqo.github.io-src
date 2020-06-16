---
title: Notas sobre Kafka Streams Stores
date: 2020-06-15
tags:
  - apache-kafka
  - stream-processing
---

Kafka Streams Stores son los componentes que definen unidades de almacenamiento en una aplicación de Kafka Streams.

Estos Stores son creados explícita o implícitamente, dependiendo de si la ()[topología] es creada con ()[Kafka Streams DSL], o con ()[Kafka Streams Processor API].

La siguiente topología 

```java
    Topology topology() {
        final StreamsBuilder builder = new StreamsBuilder();
        builder.stream("input", Consumed.with(Serdes.String(), Serdes.Integer()))
                .groupByKey()
                .count();
        return builder.build();
    }
```

crea un `Store` implícito para almacenar los resultados del contador `KSTREAM-AGGREGATE-STATE-STORE-0000000001`:

```
Topologies:
   Sub-topology: 0
    Source: KSTREAM-SOURCE-0000000000 (topics: [input])
      --> KSTREAM-AGGREGATE-0000000002
    Processor: KSTREAM-AGGREGATE-0000000002 (stores: [KSTREAM-AGGREGATE-STATE-STORE-0000000001])
      --> none
      <-- KSTREAM-SOURCE-0000000000
```

Por defecto este `Store` persiste valores en disco, usando RocksDB.

## Fábrica de `Stores`

Kafka Streams tiene una fábrica de `Stores` que permite:

* Crear `StoreSupplier`s para inyectarlos a una Topología creada por `DSL`.
* Crear `StoreBuilder`s para usarlo desde el `Processor` API.

Esta fábrica permite definir el `Store` se persiste en disco (i.e. usando `RocksDB`) o se maneja en memoria.

```java
    Topology topology() {
        KeyValueBytesStoreSupplier storeSupplier =
                Stores.inMemoryKeyValueStore("input-counter");

        final StreamsBuilder builder = new StreamsBuilder();
        builder.stream("input", Consumed.with(Serdes.String(), Serdes.Integer()))
                .groupByKey()
                .count(Materialized.as(storeSupplier));
        return builder.build();
    }
```

y la interfaz [`Materialized`](https://kafka.apache.org/25/javadoc/org/apache/kafka/streams/kstream/Materialized.html) permite parametrizar el Store.

o, cuando se utiliza el `Processor` API:

```java
    Topology topology() {
        StoreBuilder<KeyValueStore<String, Long>> storeBuilder =
                Stores.keyValueStoreBuilder(
                        Stores.inMemoryKeyValueStore("input-counter"),
                        Serdes.String(),
                        Serdes.Long());
        final StreamsBuilder builder = new StreamsBuilder();
        builder.addStateStore(storeBuilder);
        builder.stream("input", Consumed.with(Serdes.String(), Serdes.Integer()))
                .process(() -> new Processor<>() {
                    KeyValueStore<String, Long> store;

                    @Override
                    public void init(ProcessorContext context) {
                        store = (KeyValueStore<String, Long>) context.getStateStore("input-counter");
                    }

                    @Override
                    public void process(String key, Integer value) {
                        Long counter = store.get(key);
                        if (counter == null) store.put(key, 1L);
                        else store.put(key, counter + 1L);
                    }

                    @Override
                    public void close() {
                    }
                }, "input-counter");
        return builder.build();
    }
```

## Tipos de `Stores`

Kafka Streams ofrece 3 tipos de `Stores`:

- `KeyValueStore`
- `WindowStore`
- `SessionStore`

Vamos a detallar como cada uno de estos `Store` funciona actualmente.

### `KeyValueStore`

El `Store` más común es el `KeyValueStore`, ya que es similar a mantener un `Map` de Java.

En el ejemplo anterior sobre el uso de `StoreBuilder` se observa como el `KeyValueStore` permite manejar el contador como un mapa, reemplazando el mismo comportamiento ofrecido por la función `count()`.

#### Consideraciones

Si bien el `KeyValueStore` es familiar para los desarrolladores, hay ciertas consideraciones a tener en cuenta:

##### `KeyValueStore`s no tienen funcionalidad de retención

A comparación de los otros dos tipos de `Store`s, `KeyValueStore` no tiene suporte para eliminar valores por antigüedad.

Los desarrolladores tendrán que considerar si esto es ideal como parte del diseño de la aplicación considerando lo siguiente:

**La cardinalidad de `Key`s es manejable como parte de la memoría?**

Si no hay un límite en la cantidad de valores posibles para `Key`, considera utilizar un `Store` persistente para no utilizar todos los recursos de memoria. 

**Es necesario agregar los valores a través de toda la historía?**

Si los valores esperados tienen más valor si son agrupados temporalmente, considera `WindowStore`.

Si es interés esta en el conjunto de valores con una misma `Key`, considera `SessionStore`.

<!--TODO: agregar stores para Session y Window-->

## Detalles de Implementación

### Caching Stores

### ChangeLogging Stores

### Composite Stores

### In-Memory Stores

Mantienen el mapa de `KeyValue` en memoria, soportado por `TreeMap<Bytes, byte[]>`.

Acceso a operaciones del `Store` están sincronizadas para manejar la concurrencia:

```java
    private volatile boolean open = false;
//...e.g.
    public synchronized byte[] get(final Bytes key) {
        return map.get(key);
    }
```

### Metered Stores

### RocksDB Stores