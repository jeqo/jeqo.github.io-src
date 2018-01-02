---
title: Retroceder Offsets de Consumidores de Kafka
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
Así que a menos que se utilize el mismo `group.id` luego, será como si
creara un nuevo `consumer group` cada vez que se inice un terminal con
`kafka-console-consumer`.

Por defecto, cuando se conecta a un `topic` como un `consumer` se inicia con
el *último* `offset`, así que no se recibirán nuevos `records` a menos que nuevos
mensajes arriben luego de iniciada la conexión.

En este caso, para ir hacia el inicio del topic sería suficiente con agregar
la opción `--from-beginning` a la línea de comandos:

<script type="text/javascript" src="https://asciinema.org/a/101246.js" id="asciicast-101246" async></script>

Pero, qué pasaría si se usa la propiedad `group.id`?, La ópcion `--from-beginning`
solo funcionaría la primera vez, ya que el `offset` sería registrado en el clúster::

<script type="text/javascript" src="https://asciinema.org/a/101248.js" id="asciicast-101248" async></script>

<script type="text/javascript" src="https://asciinema.org/a/101250.js" id="asciicast-101250" async></script>

Así que, cómo se regresaría al inicio del log en este caso?

Podemos usar la opción `--offset` con estas tres alternativas:

```
--offset <String: consume offset>        The offset id to consume from (a non-  
                                           negative number), or 'earliest'      
                                           which means from beginning, or       
                                           'latest' which means from end        
                                           (default: latest)
```

<script type="text/javascript" src="https://asciinema.org/a/101252.js" id="asciicast-101252" async></script>

## Desde Clientes Java

Ahora, luego de ver que desde la línea de comandos en sencillo regresar en el
tiempo sobre el log; pero, cómo hacer éstas operaciones desde una aplicación?

Si estás utilizando Kafka Consumers en tu aplicación, tienes las siguientes
opciones (con Java):

* [Kafka Consumer API](http://kafka.apache.org/documentation/#consumerapi)

* [Kafka Streams API](http://kafka.apache.org/documentation/#streamsapi)   

Haciendo la historia corta: Si necesitas capacidades de procesar mensajes
desde Kafka de forma *stateful* (manteniendo el estado), es recomendable
utilizar `Kafka Streams API`.
Si necesitas una API simple para consumir mensajes uno a uno, utiliza
`Kafka Consumer API`.

Al momento de escribir este post, éstas son las opciones para hacer *rewind*
de `offsets` desde estas APIs:

- `Kafka Consumer API` soporta regresar al *inicio* de topic, ir a un
`offset` específico, o regresar a un punto en el tiempo (timestamp).

- `Kafka Streams API` en este momemnto solo soporta regresar al `offset` inicial
de los `input topics`, y se encuentra bien explicado por [Matthias J. Sax](https://github.com/mjsax)
en su post:
[[1]](https://www.confluent.io/blog/data-reprocessing-with-kafka-streams-resetting-a-streams-application/).

Así que me enfocaré en las opciones disponibles desde el API de `Kafka Consumer`.

Un consumidor simple luciría así:

{{< highlight java >}}
public static void main(String[] args) {
    Properties props = new Properties();
    props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, "test");
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");

    KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
    consumer.subscribe(Arrays.asList("topic-1"));

    while (true) {
        ConsumerRecords<String, String> records = consumer.poll(100);

        for (ConsumerRecord<String, String> record : records)
            System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
    }
}
{{</ highlight >}}

Este consumidor buscará por records por `100ms` y los imprimirá en la consola.

Ahora veamos como regresar `offsets` en distintos escenarios. `Consumer API`
tiene operaciones `#seek` que permiten estas funcionalidades. Mostraré una
forma sencilla de agregar estas operaciones utilizando `flags`:

### Regresar al `offset` inicial

La opción más común es regresar al inicio del `topic`, que no siempre será
`offset=0`. Esto dependerá de la política de `retention` que removerá los
`records` antiguos por tiempo o por tamaño del `topic`; pero este tema
merece su propio post.

Para ir al inicio de `topic` usaremos la operación `#seekToBeginning(topicPartition)`:

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

Una vez realizada la búsqueda del `offset` inicial, para el `topic=topic-1`
en la `partition=0` se reprocesarán los `records` nuevamente.

### Regresar a un `offset` específico

Si podemos reconocer los `records` específicos (por `partition`) a los que
necesitamos regresar para reprocesar el log, podemos utilizar
`#seek(topicPartition, offset)` directamente.

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

En este casoo, retrocederemos en en `topic=topic-1` `partition=0`
hasta el `record` con `offset=90` y reprocesaremos los siguiente `records`
del log.

***
NOTA: Puede resultar engorroso mapear todos los offsets por partición cuando
tienes varias particiones. Por esto es que la adición de `timestamps` ayuda
a resolver este tema.
***

### Regrasar a un `offset` por `timestamp`

Si no conoces exactamente el `offset id` del `record` desde donde necesitar
reprocesar el log, pero sabes si necesitas regresar 1 hora o 10 minutos atrás
el nuevo índice de `timestamp` puede ser útil.

Desde el release `0.10.1.0`, hay un par de mejoras
[[2]](https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message)
[[3]](https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index)
que fueron implementadas, y una nueva operación fue agregada al
`Kafka Consumer API`: `#offsetsForTimes`:

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

En este caso primero estamos consultando cuál es el `offset` al que tengo que
regresar si quiero reprocesar los `records` de hacer 10 minutos,
y luego con el `offset` adecuado, utilizamos la operación `#seek`.

En el código fuente se ha agregado los pasos para buscar las particiones por
`topic`. Esto permitirá reproducir estos pasos en escenarios en los que tengamos
más de una partición por `topic`.

****
**Referencias**

1. https://www.confluent.io/blog/data-reprocessing-with-kafka-streams-resetting-a-streams-application/

2. https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message

3. https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index

4. https://cwiki.apache.org/confluence/display/KAFKA/FAQ#FAQ-HowcanIrewindtheoffsetintheconsumer

****
