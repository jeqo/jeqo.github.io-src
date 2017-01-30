---
title: Kafka - Retroceder Offsets de Consumidores
date: 2017-01-31
section: post
tags:
- kafka
categories:
- integration
---

Una de las características más importantes de *Apache Kafka* es el manejo
de múltiples consumidores. Cada `consumer group` tiene un `offset`, que
determina hasta que punto del `topic` se encuentra consumido por `consumer group`.
Así, cada `consumer group` puede manejar los `offset` independientemente, por
partición.

Esto ofrece la posibilidad de retroceder en el tiempo y reprocesar mensaje desde
el inicio de un `topic` y regenerar el estado actual del sistema.

Pero, cómo realizar esto de forma programática?

<!--more-->

****
Código fuente: [https://github.com/jeqo/post-kafka-rewind-consumer-offset](https://github.com/jeqo/post-kafka-rewind-consumer-offset)
****

## Conceptos Básicos

### Topics y Offsets

Lo primero por entender para lograr retroceder los consumidores en Kafka es:
retroceder sobre qué? Cada `topic` esta dividido en `partitions`. Los
registros enviados por los `Producers` son balanceados entre las `partitions`,
así cada partición tiene su propio índice de `offsets`.

Cada `record` tiene un `offset` asignado que será usado por los `consumers`
para definir qué mensajes han sido consumidos del **log**.

### Consumers y Consumer Groups

Una vez entendido que los `topics` tienen `partitions` y `offsets` por `partition`
podemos pasar a definir como trabajan los `consumers` y `consumer groups`.

`Consumers` están agrupados por `group.id`. Ésta propiedad identifica a cada  
`consumer group`, así el `broker` conoce cúal fue el último `record` consumido
por `offset`, por `partition`.


Antes de continuar, revisemos la clase que funcionará como un `Kafka Consumer`
simple implementado en Java:

`KafkaSimpleProducer.java`:


{{< highlight java >}}
public static void main(String[] args) {
    ...
    Properties properties = new Properties();
    properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

    Producer<String, String> producer = new KafkaProducer<>(properties);

    IntStream.rangeClosed(1, 100)
            .boxed()
            .map(number -> new ProducerRecord<>(
                    "topic-1",
                    number.toString(),
                    number.toString()))
            .map(record -> producer.send(record))
            .forEach(result -> printMetadata(result));
    producer.close();
}
{{</ highlight >}}

Este `producer` creará 100 `records` en el topic `topic-1`, con `offsets`
de `0` a `99`.

## Desde Línea de Comandos

En este primer escenario revisaremos como manejar los offsets de `consumers`
desde *línea de comandos*, para tener una idea de como implementarlo en
nuestra aplicación.

Cuando trabajas desde un terminal, si se puede utilizar `kafka-console-consumer`
sin `group.id` definido, un nuevo `group.id` es generado internamente:
`console-consumer-${new Random().nextInt(100000)}`.

//TODO

so unless you use the same `group.id` afterwards it would be as you create a new consumer group each time.

By default, when you connect to a `topic` as a `consumer` with `console` you
go to the `latest` offset, so you won't see any new message until new records
arrive after you connect.

In this case, going back to the beginning of the topic will as easy as add
`--from-beginning` option to the command line:

<script type="text/javascript" src="https://asciinema.org/a/101246.js" id="asciicast-101246" async></script>

But, what happen if you use `group.id` property, it will only work the first time,
but `offset` gets commited to cluster:

<script type="text/javascript" src="https://asciinema.org/a/101248.js" id="asciicast-101248" async></script>

<script type="text/javascript" src="https://asciinema.org/a/101250.js" id="asciicast-101250" async></script>

So, how to go back to the beginning?

We can use `--offset` option to with three alternatives:

```
--offset <String: consume offset>        The offset id to consume from (a non-  
                                           negative number), or 'earliest'      
                                           which means from beginning, or       
                                           'latest' which means from end        
                                           (default: latest)
```

<script type="text/javascript" src="https://asciinema.org/a/101252.js" id="asciicast-101252" async></script>

## From Java Clients

So, from `command-line` is pretty easy to go back in time in the log. But
how to do it from your application?

If you're using Kafka Consumers in your applications, you have to options
(with Java):

* [Kafka Consumer API](http://kafka.apache.org/documentation/#consumerapi)

* [Kafka Streams API](http://kafka.apache.org/documentation/#streamsapi)   

Long story short: If you need stateful and stream processing capabilities,
go with Kafka Streams.
If you need simple one-by-one consumption of messages by topics, go with
Kafka Consumer.

At this moment this are the options to rewind offsets with these APIs:

- Kafka Consumer API support go back to the beginning of the topic, go back
to a specific offset, and go back to a specific offset by timestamps.

- Kafka Streams API only support to go back to the earliest offset of the
`input topics`, and is well explained by [Matthias J. Sax](https://github.com/mjsax)
in his post
[[1]](https://www.confluent.io/blog/data-reprocessing-with-kafka-streams-resetting-a-streams-application/).

So I will focus in programmatically options available in `Kafka Consumer`.

A simple Consumer will look something like this:

{{< highlight java >}}
public static void main(String[] args) {
    Properties props = new Properties();
    props.put("bootstrap.servers", "localhost:9092");
    props.put("group.id", "test");
    props.put("enable.auto.commit", "true");
    props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
    props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

    KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
    consumer.subscribe(Arrays.asList("topic-1"));

    while (true) {
        ConsumerRecords<String, String> records = consumer.poll(100);

        for (ConsumerRecord<String, String> record : records)
            System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
    }
}
{{</ highlight >}}

This will poll each `100ms` for records and print them out.

Now let's check how to rewind offsets in different scenarios. Consumer API has
add `#seek` operations to achieve this behavior. I will show a naive way to use
these operations using flags but it shows the point:

### Rewind to earliest offset

The easiest options is to go back to the beginning of the topic, that not
always will be `offset=0`. This will depends on the `retention` policy
option sthat will be cleaning old records based on time or size, but
this also deserves its own post.

To go to the beginning we can use `#seekToBeginning(topicPartition)`
operation to go back to earliest offset:

{{< highlight java >}}
boolean flag = true;

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(100);

    if (flag) {
        consumer.seekToBeginning(
            Stream.of(new TopicPartition("topic-1", 0)).collect(toList()));
        flag = false;
    }

    for (ConsumerRecord<String, String> record : records)
        //Consume record
}
{{</ highlight >}}

Once the seek is done, we can continue our processing as before.

### Rewind to specific offset

If we can recognized the specific record from where we need to reprocess,
we can use `#seek(topicPartition, offset)`

{{< highlight java >}}
boolean flag = true;

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(100);

    if(flag) {
        consumer.seek(new TopicPartition("topic-1", 0), 90);
        flag = false;
    }

    for (ConsumerRecord<String, String> record : records)
        System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
}
{{</ highlight >}}

In this case, we will consume from `record` with `offset=90`

### Rewind to offset by timestamps

What if you don't know exactly the `offset id` to go back to, but you know
you want to go back 1 hour or 10 min.

For these, since release `10.1.0.1` (TODO validate), there are a couple of
improvements [[2]](https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message)
[[3]](https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index)
were added and a new `seek` operation was added: `#offsetsForTimes`.

Here is how to use it:

{{< highlight java >}}
boolean flag = true;

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(100);

    if(flag) {
        Map<TopicPartition, Long> query = new HashMap<>();
        query.put(
                new TopicPartition("simple-topic-1", 0),
                Instant.now().minus(10, MINUTES).toEpochMilli());

        Map<TopicPartition, OffsetAndTimestamp> result = consumer.offsetsForTimes(query);

        result.entrySet()
                .stream()
                .forEach(entry -> consumer.seek(entry.getKey(), entry.getValue().offset()));

        flag = false;
    }

    for (ConsumerRecord<String, String> record : records)
        System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
}
{{</ highlight >}}

In this case, we are using a query first to get the offset inside a timestamp (10 minutes ago)
and then using that offset to go back with `#seek` operation.

As you can see, for each operation I have to define the specific `topic partition`
to go back to, so this can get tricky if you have more than one partition, so I
would recommend to use `#offsetsForTimes` in those cases to get an aligned result
and avoid inconsistencies in your consumers.

****
**References**

1. https://www.confluent.io/blog/data-reprocessing-with-kafka-streams-resetting-a-streams-application/

2. https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message

3. https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index

4. https://cwiki.apache.org/confluence/display/KAFKA/FAQ#FAQ-HowcanIrewindtheoffsetintheconsumer

****
