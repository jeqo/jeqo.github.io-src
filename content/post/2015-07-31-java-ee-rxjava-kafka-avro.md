---
title: Integrate Java EE 7 and Kafka using Avro and RxJava
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

I decided to implement a naive integration between Java EE applications and
RxJava/Kafka/Avro, to publish and subscribe to events.

You can go directly to that [code](https://github.com/jeqo/java-ee-rxjava-kafka-avro), or check my approach:

<!--more-->

## TL;DR ##

I have been playing with [Kafka](http://kafka.apache.org/) recently, seduced by its benefits (fast, scalable,
and durable event source) to spread event using Publish/Subscribe pattern.

I realized that Kafka APIs are still evolving and getting better, and it was not
easy to find an easy introduction related with the current released version.
I am using **0.8.2.1 release**.

I tested its APIs to *produce* and *subscribe* to messages using this [tutorial](https://github.com/mdkhanga/my-blog-code)

Kafka support 2 types of messages: *Strings* and *byte[]*. So, after testing sample
String messages, I required to send POJO as messages. I came out with
another interesting Apache project: [Avro](https://avro.apache.org).

Using Avro tutorials ([https://avro.apache.org/docs/current/gettingstartedjava.html](https://avro.apache.org/docs/current/gettingstartedjava.html)) and
another sources ([https://github.com/wpm/AvroExample](https://github.com/wpm/AvroExample)) I found how to Serialize/Deserialize POJO, but without
persisting files on disk, just keeping them as ByteStreams. So, now I have
Events, defined by [Avro schemas](https://avro.apache.org/docs/current/spec.html#schema_record), and Kafka APIs ready to publish and subscribe
to these events.

Finally, I wanted to add these cool features to my Java EE 7 apps. First,
using CDI was simple to inject Producer and publish messages when your application
produces events, but when it comes to consume events the approach is different.
You are no longer producing events, but working with "streams" of data. So, I
decided to use [RxJava](https://github.com/ReactiveX/RxJava) that applies concepts as
[**Observables**](http://reactivex.io/documentation/observable.html) and **Subscribers** that
fits smoothly with my requirements: each Kafka topic will be "observable" stream and each
Consumer will subscribe to that "observable". Let's check the code:

## Sample Java EE App

[Tag: v0.0.1](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.1)

First step is just having a couple of RESTful services, implemented with JAX-RS:

* Clients Resource: List (GET) and Add (POST) Clients
* Events Resource: List (GET) Client Added Events

{{< highlight java >}}
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
{{< /highlight >}}

At this point, Clients Resource is implemented. So, how can I do to propagate
ClientAddedEvent and list them on Events resource?

## Serializing and Deserializing Events

[Tag: v0.0.2](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.2)

When I decided to use Kafka, I realized that I can only send String and Byte
Array messages, so Avro is able to serialize POJO into byte[] and vice versa:

{{< highlight java >}}
public void test() {
    ClientAddedEvent event = ClientAddedEvent.newBuilder()
            .setName("jeqo")
            .setCreated(new Date().getTime())
            .build();
    byte[] eventSerialized = serializer.serialize(event);
    ClientAddedEvent eventDeserialized = deserializer.deserialize(eventSerialized);
    assertEquals(event, eventDeserialized);
}
{{< /highlight >}}

ClientAddedEvent event is defined using Avro JSON format:

{{< highlight json >}}
{
    "namespace": "com.jeqo.samples.eventsource.event",
    "type": "record",
    "name": "ClientAddedEvent",
    "fields": [
        {"name": "name", "type": "string"},
        {"name": "created", "type": "long"}
    ]
}
{{< /highlight >}}

Adding a Maven Plugin, you will generate *ClientAddedEvent* each time you build
your project:

{{< highlight xml >}}
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
{{< /highlight >}}

To serialize Avro records, from POJO to Byte Array:


{{< highlight java >}}
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
{{< /highlight >}}

And to deserialize:

{{< highlight java >}}
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
{{< /highlight >}}

## Publishing and Consuming Events from Kafka/RxJava

[Tag: v0.0.3](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.0.3)

Now that Event serialization is done with Avro, let's publish and subscribe
those events on Kafka:

First, let's define a couple of interfaces, EventServer:

{{< highlight java >}}
public interface EventServer<T> {

    public Observable<T> consume();
}
{{< /highlight >}}

and EventProducer:

{{< highlight java >}}
public interface EventProducer<T> {

    public void publish(T message);
}
{{< /highlight >}}

Then, let's implement them with Kafka. I will focus on main functionality first:

To publish messages:

{{< highlight java >}}
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
{{< /highlight >}}

And on KafkaEventServer, to instantiate an RxJava observable:

{{< highlight java >}}
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
{{< /highlight >}}

You could check \*Provider class to validate how to generate a connection to Kafka
for both Publisher and Subscriber.

On tag v0.0.3, you could run each class (KafkaEventServer and KafkaEventProducer)
to check that it's working Ok with your Kafka server.

## Putting all together

[Tag: v0.1.0](https://github.com/jeqo/java-ee-rxjava-kafka-avro/releases/tag/v0.1.0)

Finally, let's integrate this Event Sourcing engine with our Java EE app:

First, create instantiate a publisher and a subscriber:


{{< highlight java >}}
@ApplicationScoped
public class ClientAddedEventProducer extends KafkaEventProducer<ClientAddedEvent> {

}
{{< /highlight >}}

This means that ClientAddedEventProducer will be a *"singleton"* and I could inject it
on my service that generates events:

{{< highlight java >}}
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
{{< /highlight >}}

Then, instantiate a Subscriber (I think this is the most interesting part:
  how we will **react** to events? ):

{{< highlight java >}}
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
{{< /highlight >}}
