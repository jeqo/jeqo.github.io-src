---
title: Piggyback on Kafka Connect Schemas to process Kafka records in a generic way
date: 2022-08-24

tags:
- kafka
- connect
- dev

categories:
- til
---

When reading from/writing to Kafka topics, a serializer/deserializer (a.k.a `SerDe`s) is needed to process record key and value bytes.
Specific `SerDe`s that turn bytes into specific objects (e.g. POJO) are used, unless a generic JSON object or Avro structure is used.

[Kafka Connect](https://kafka.apache.org/documentation/#connect)
has to deal with generic structures to apply message transformations and convert messages from external sources into Kafka records and vice-versa.
It has a `SchemaAndValue` composed type that includes a Connect Schema type derived from Schema Registry or JSON Schema included in the payload,
and a value object.
The value object can be a `Map<String, Object>` when no schema is available (e.g. plain JSON) 
or a `Struct` that represents a value with an Schema attached (e.g. Avro record).

I found useful to be able to implement Kafka applications that are detatched from the record structure,
and that can apply generic transformations to the `Map` or `Struct`.

<!-- more -->

It turns out that it's quite quick to piggyback on the Connect Schema structure as most of the work is done by the Connect Converter class.

Serializer and Deserializer are quite simple:

```java
package kafka.serde.connect;

import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.connect.data.SchemaAndValue;
import org.apache.kafka.connect.storage.Converter;

public class SchemaAndValueSerializer implements Serializer<SchemaAndValue> {

  final Converter converter;

  public SchemaAndValueSerializer(Converter converter) {
    this.converter = converter;
  }

  @Override
  public byte[] serialize(String s, SchemaAndValue schemaAndValue) {
    return converter.fromConnectData(s, schemaAndValue.schema(), schemaAndValue.value());
  }
}
```

```java
package kafka.serde.connect;

import org.apache.kafka.common.serialization.Serializer;
import org.apache.kafka.connect.data.SchemaAndValue;
import org.apache.kafka.connect.storage.Converter;

public class SchemaAndValueSerializer implements Serializer<SchemaAndValue> {

  final Converter converter;

  public SchemaAndValueSerializer(Converter converter) {
    this.converter = converter;
  }

  @Override
  public byte[] serialize(String s, SchemaAndValue schemaAndValue) {
    return converter.fromConnectData(s, schemaAndValue.schema(), schemaAndValue.value());
  }
}
```

Then, it's about instantiating the Converters to make the application work against topics expecting JSON or Schema Registry-based records:

```java
public class AvroConverterExample {

  public static void main(String[] args) {
    var data = ksql.StockTrade
      .newBuilder()
      .setAccount("123")
      .setPrice(100)
      .setQuantity(1)
      .setSymbol("USD")
      .setSide("A")
      .setUserid("U001")
      .build();
    var avro = new AvroData(10);
    var schemaAndValue = avro.toConnectData(data.getSchema(), data);
    var converter = new AvroConverter();
    converter.configure(Map.of("schema.registry.url", "http://localhost:8081"), false);
    try (var serde = new SchemaAndValueSerde(converter)) {
      var bytes = serde.serializer().serialize("test", schemaAndValue);
      var value = serde.deserializer().deserialize("test", bytes);
      System.out.println(Requirements.requireStruct(value.value(), "test").get("account"));
    }
  }
}
```

```java
public class JsonConverterExample {

  public static void main(String[] args) {
    var mapper = new ObjectMapper();
    var jsonNode = mapper.createObjectNode().put("test", "t1").put("value", "v1");
    var map = mapper.convertValue(jsonNode, new TypeReference<Map<String, Object>>() {});

    var converter = new JsonConverter();
    converter.configure(Map.of("schemas.enabled", "false", "converter.type", "value"));
    var serde = new SchemaAndValueSerde(converter);
    var bytes = serde.serializer().serialize("test", new SchemaAndValue(null, map));
    System.out.println(new String(bytes));
  }
}
```

A more complex example with Kafka Streams:

```java
    // build serde
    var converter = new JsonConverter();
    converter.configure(Map.of("schemas.enable", "false", "converter.type", "value"));
    var valueSerde = new SchemaAndValueSerde(converter);

    // build topology
    final var builder = new StreamsBuilder();
    builder
      .stream("test-input", Consumed.with(Serdes.String(), valueSerde))
      // cast to map
      .mapValues((s, schemaAndValue) -> Requirements.requireMapOrNull(schemaAndValue.value(), "testing")) 
      // use map as value
      .filter((s, map) -> !map.isEmpty())
      .filter((s, map) -> map.get("countryCode").toString().equals("PE")) 
      // back to wrapper
      .mapValues((s, map) -> new SchemaAndValue(null, map))
      .to("test-output", Produced.with(Serdes.String(), valueSerde));
```

References:

- SerDe implementation library: <https://github.com/jeqo/kafka-libs/tree/main/connect-schema-serde>
