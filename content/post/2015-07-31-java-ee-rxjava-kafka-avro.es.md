---
title: Integrar Java EE 7 y Kafka usando Avro y RxJava
date: 2015-07-31
section: post
tags:
- java ee
- kafka
- avro
- rx
categories: 
- development
- integration
- back-end
---

Hace poco decidi probar una rápida implementación entre aplicaciones
Java EE y RxJava/Kafka/Avro, para publicar/subscribirse a "topic messages".

Puedes ir directamente al [código](https://github.com/jeqo/java-ee-rxjava-kafka-avro),
o revisar el enfoque que apliqué:

## TL;DR ##

He estado realizando alguna pruebas de concepto con [Kafka](http://kafka.apache.org/)
seducido por los beneficios que propone (rapidez, escalabilidad, y funcionar como
una fuente de eventos durable) para implementar una propagación de eventos
usando el patrón "Publish/Subscribe".

En estos momentos que estoy escribiendo esta entrada del blog, me he dado cuenta
que las APIs para acceder a Kafka están en constante evolución y volviéndose
más simples de utilizar, y no ha sido fácil encontrar un ejemplo con la versión
actual. Estoy utilizando el **release 0.8.2.1**.

Logré encontrar este tutorial sobre como utilizar las APIs para *publicar*
y *suscribirse* a mensajes: [https://github.com/mdkhanga/my-blog-code](https://github.com/mdkhanga/my-blog-code)

Kafka soporta 2 tipos de mensajes : *Strings* and *byte[]*. Luego de hacer
algunas pruebas con String, requería enviar POJOs como mensajes. Y encontré
otro proyecto de Apache: [Avro](https://avro.apache.org).

Utilizando los tutoriales de Avro ([https://avro.apache.org/docs/current/gettingstartedjava.html](https://avro.apache.org/docs/current/gettingstartedjava.html))
y otras fuentes: ([https://github.com/wpm/AvroExample](https://github.com/wpm/AvroExample))
Encontre como Serializar/Deserializar POJO de una forma eficiente, sin necesidad
de persistir archivos en disco, solo manteniendolos como ByteStreams.

En este punto tengo Eventos, definidos por [esquemas de Avro](https://avro.apache.org/docs/current/spec.html#schema_record),
y APIs de Kafka listo para publicar y suscribirse a "topics".

Finalmente, quiero agregar esta características a mi aplicación Java EE 7.

Primero, usando CDI, fue sencillo inyectar un "Producer" y publicar mensajes,
pero cuando se necesita consumir mensajes, el enfoque cambia. Ya no se trata
de enviar mensajes, pero consumir un "stream" de eventos. Así llegue a encontrarme
con [RxJava](https://github.com/ReactiveX/RxJava) que aplica conceptos como
[**Observables**](http://reactivex.io/documentation/observable.html) y **Subscribers**
que cubre mis requerimientos: cada Kafka topic será un stream "observable" y
cada Consumer se suscribirá a este "observable". Revisemos el código:

## Sample Java EE App ##

[Tag: v0.0.1](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.1)

El primer paso fue tener un par de operaciones REST, implementados con JAX-RS:

* Clients Resource: List (GET) and Add (POST) Clients
* Events Resource: List (GET) Client Added Events

```java
@Path("clients")
public class ClientsResource {

    static List<String> clients = new ArrayList<>();

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<String> getClients() {
        return clients;
    }

    @POST
    public void addClient(String client) {
        clients.add(client);
    }
}
```

Luego de tener mi recurso "Clients" implementado, mi requerimiento es
propagar el evento "ClientAddedEvent" y listarlo en el recurso Events.

## Serialización y Deserialización de Eventos ##

[Tag: v0.0.2](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.2)

```java
public void test() {
    ClientAddedEvent event = ClientAddedEvent.newBuilder()
            .setName("jeqo")
            .setCreated(new Date().getTime())
            .build();
    byte[] eventSerialized = serializer.serialize(event);
    ClientAddedEvent eventDeserialized = deserializer.deserialize(eventSerialized);
    assertEquals(event, eventDeserialized);
}
```

El event ClientAddedEvent es definido usando el formato Avro JSON:

```json
{
    "namespace": "com.jeqo.samples.eventsource.event",
    "type": "record",
    "name": "ClientAddedEvent",
    "fields": [
        {"name": "name", "type": "string"},
        {"name": "created", "type": "long"}
    ]
}
```

Agregando el siguiente plugin de Maven, la clase  *ClientAddedEvent* se
creará cada vez que el proyecto sea construido:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.avro</groupId>
            <artifactId>avro-maven-plugin</artifactId>
            <version>1.7.7</version>
            <executions>
                <execution>
                    <phase>generate-sources</phase>
                    <goals>
                        <goal>schema</goal>
                    </goals>
                    <configuration>
                        <sourceDirectory>${project.basedir}/src/main/avro/</sourceDirectory>
                        <outputDirectory>${project.basedir}/src/main/java/</outputDirectory>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

Para serializar Avro records, de POJO a Byte Array:

```java
public class EventSerializer<T extends SpecificRecordBase> {

    public byte[] serialize(T record) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Encoder encoder = EncoderFactory.get().binaryEncoder(out, null);
            new SpecificDatumWriter<>(record.getSchema()).write(record, encoder);
            encoder.flush();
            return out.toByteArray();
        } catch (IOException ex) {
            throw new RuntimeException("Error serializing event", ex);
        }
    }
}
```

y viceversa:

```java
public class EventDeserializer<T extends SpecificRecordBase> {

    private final Class<T> type;

    public EventDeserializer(Class<T> type) {
        this.type = type;
    }

    public T deserialize(byte[] recordSerialized) {
        try {
            return new SpecificDatumReader<>(type).read(
                    null,
                    DecoderFactory.get()
                    .binaryDecoder(recordSerialized, null)
            );
        } catch (IOException ex) {
            throw new RuntimeException("Error deserializing event", ex);
        }
    }
}
```

## Publicando y consumiendo eventos desde Kafka/RxJava ##

[Tag: v0.0.3](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.3)

Primero, definamos un par de interfaces, EventServer:

```java
public interface EventServer<T> {

    public Observable<T> consume();
}
```

y EventProducer:

```java
public interface EventProducer<T> {

    public void publish(T message);
}
```

Luego, implementemos estas interfaces con Kafka APIs.

Para publicar mensajes:

```java
@Override
public void publish(T message) {
    // Produce a new Kafka record
    ProducerRecord<String, byte[]> data = new ProducerRecord<>(
            message.getClass().getSimpleName(),
            serializer.serialize(message)
    );

    // Publish this new record, waiting for acknowledge from Kafka
    Future<RecordMetadata> rs = producerProvider.producer()
            .send(data, (RecordMetadata recordMetadata, Exception e) -> {
                LOGGER.log(Level.INFO, "Received ack for partition={0} offset = {1}", new Object[]{recordMetadata.partition(), recordMetadata.offset()});
            });

    try {
        RecordMetadata rm = rs.get();

        LOGGER.log(Level.INFO, "Kafka Record Metadata: partition = {0} offset ={1}", new Object[]{rm.partition(), rm.offset()});

    } catch (InterruptedException | ExecutionException e) {
        System.out.println(e);
    }
}
```

y en KafkaEventServer, para instanciar un RxJava observable:

```java
@Override
public Observable<T> consume() {
    return Observable.create(subscriber -> {
        try {
            LOGGER.log(Level.INFO, "Preparing Server for Event {0}", type.getName());
            // It will observe one Topic
            Map<String, Integer> topicCountMap = new HashMap<>();
            topicCountMap.put(type.getSimpleName(), 1);

            // consumerProvider will instantiate a consumer that will create a KafkaStream
            Map<String, List<KafkaStream<byte[], byte[]>>> consumerMap
                    = consumerProvider.consumer()
                    .createMessageStreams(topicCountMap);

            // then I will ask for the Stream from my topic, defined by Avro Record Class name
            List<KafkaStream<byte[], byte[]>> streams = consumerMap
                    .get(type.getSimpleName());

            KafkaStream<byte[], byte[]> stream = streams.get(0);

            ConsumerIterator<byte[], byte[]> it = stream.iterator();

            // on each message published on topic, I will let the subscriber receive the new message
            while (it.hasNext()) {
                subscriber.onNext(
                        deserializer.deserialize(it.next().message())
                );
            }
        } catch (Exception ex) {
            subscriber.onError(ex);
        }
    });
}
```

Se puede validar la clase \*Provider para observar como se genera la conexión
con Kafka, tanto para el Publisher como para el Subscriber.

En el tag v0.0.3 se puede ejecutar cada clase (KafkaEventServer and KafkaEventProducer)
para validar que el servidor Kafka esta trabajando correctamente.

## Uniendo todo ##

[Tag: v0.1.0](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.1.0)

Finalmente, vamos a integrar la aplicación Java EE interacción con la nuestra
fuente de eventos (Kafka):

```java
@ApplicationScoped
public class ClientAddedEventProducer extends KafkaEventProducer<ClientAddedEvent> {

}
```

La anotación @ApplicationScoped de CDI indica que esta clase se instanciará como
*"singleton"* y podrá ser inyectada:

```java
public class ClientsResource {

    @Inject
    ClientAddedEventProducer eventProducer;

    //code

    @POST
    public void addClient(String client) {
        clients.add(client);
        //Publishing events
        eventProducer.publish(
                ClientAddedEvent.newBuilder()
                .setName(client)
                .setCreated(new Date().getTime())
                .build()
        );
    }
}
```

Luego para instanciar el *Subscriber* (Creo que es la parte más importante:
como **reaccionar** a eventos? ):

```java
// Extending Subscriber RxJava class to listen Observables
@ApplicationScoped
public class ClientAddedEventSubscriber extends Subscriber<ClientAddedEvent> {

    static final Logger LOGGER = Logger.getLogger(ClientAddedEventSubscriber.class.getName());

    // This will add a new thread to our pool, to subscribe to our Observable
    @Resource(name = "DefaultManagedExecutorService")
    private ManagedExecutorService executor;

    @Inject
    private KafkaConsumerProvider consumerProvider;

    private Subscription subscription;

    // Run this on server startup, using CDI annotations
    public void init(@Observes @Initialized(ApplicationScoped.class) Object init) {
        LOGGER.log(Level.INFO, "Starting subscription");
        subscription = new KafkaEventServer<>(
                ClientAddedEvent.class,
                consumerProvider,
                executor
        ).consume().subscribe(this);
    }

    public void destroy(@Observes @Destroyed(ApplicationScoped.class) Object init) {
        subscription.unsubscribe();
    }

    @Override
    public void onCompleted() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void onError(Throwable e) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public void onNext(ClientAddedEvent t) {
        LOGGER.log(Level.INFO, "Event received {0}", t);
        // How we will react to events:
        EventsResource.events.add(
                "Client Added: " + t.getName() + " at " + new Date(t.getCreated())
        );
    }

}
```
