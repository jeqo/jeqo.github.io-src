---
title: Kafka client applications with GraalVM
date: 2022-03-18
section: posts

tags:
- kafka
- cli
- graalvm

categories:
- development
---

Shipping CLI binaries with Java hasn't been the most user-friendly experience.
Java is required to be installed on the client-side, starting Java applications (e.g. executable JAR) tend to be slower than to binary applications.

GraalVM, and specifically [native-image](https://www.graalvm.org/22.0/reference-manual/native-image/) tooling, is aimed to tackle most of these issues with Java by enable building native binaries from Java applications.

Even though this has been supported for a while now, reflection and other practices require additional configurations that make this process either unsupported or very cumbersome to implement.

With the arrival of new frameworks that target the benefits of GraalVM, like [Micronaut](https://micronaut.io/) and [Quarkus](https://quarkus.io/), it started to be possible and simpler to implement applications that included Kafka clients, and package them as native binaries.

This post is going to explore the steps to package _vanilla_ Kafka client applications —i.e. no framework— as native binaries.

<!--more-->

NOTE: I still don't fully understand how some details on how GraalVM work.
Still, I will try to make explicit along the post, so I will focus on how to build Kafka client applications binaries with GraalVM.

The CLIs built with these configurations have been tested against plaintext clusters and Confluent Cloud (TLS, SASL Plain authentication), and _haven't_ been tested with Kerberos, SCRAM, or other authentication mechanisms.

## Common configurations

I will be using GraalVM native-image Maven plugin to create a Java binary.
Most of the configurations are supposed to go as part of the plugin definition:

```xml
<plugin>
  <groupId>org.graalvm.buildtools</groupId>
  <artifactId>native-maven-plugin</artifactId>
  <version>0.9.7.1</version>
  <extensions>true</extensions>
  <executions>
    <execution>
      <id>build-native</id>
      <goals>
        <goal>build</goal>
      </goals>
      <phase>package</phase>
    </execution>
  </executions>
  <configuration>
    <buildDirectory>bin/</buildDirectory>
    <imageName>kproducerdatagen-${project.version}</imageName>
    <mainClass>kafka.cli.producer.datagen.ProducerDatagenCli</mainClass>
    <buildArgs>
      <!-- HERE -->  
    </buildArgs>
  </configuration>
</plugin>
```

The first build arguments to consider are:

```xml
<buildArg>--no-fallback</buildArg>
<buildArg>--allow-incomplete-classpath</buildArg>
```

To avoid getting a half-built image that still depends on the JDK, and to allow incomplete class paths.

## GraalVM Substitutions

Apache Kafka, and the client libraries in particular, follows a very pluggable architecture, that depending on the configuration loads certain components.
For instance, if authentication is required, then SASL is loaded as part of the execution.
Something similar might happen with compression algorithms.

This kind of behaviors are against how GraalVM native-images are loaded, and require additional guidance to get the right classes in place.

Here is where it helped me to look into how other libraries are doing this.
I have collected some substitutions from Micronaut and Oracle Helidon here: <https://github.com/jeqo/poc-apache-kafka/tree/main/clients/kafka-clients-graalvm/src/main/java/kafka/clients/graalvm>

Sources:

- `KafkaSubstitutions` from: <https://github.com/micronaut-projects/micronaut-kafka/blob/master/kafka/src/main/java/io/micronaut/configuration/kafka/graal/KafkaSubstitutions.java>
- `ByteBufferUnmapperSubstitute` from: <https://github.com/micronaut-projects/micronaut-kafka/blob/0166116452a5e094a8db7877a52490ad23f2f5cf/kafka/src/main/java/io/micronaut/configuration/kafka/graal/ByteBufferUnmapperSubstitute.java>
- `SaslClientCallbackHandlerSubstitute` from: <https://github.com/oracle/helidon/blob/785ce38ca06b268d16e387fb6498aaaa890695cc/messaging/kafka/src/main/java/io/helidon/messaging/connectors/kafka/SaslClientCallbackHandlerSubstitution.java>

## SASL authentication

For SASL authentication the following configurations are required:

```xml
<buildArg>-H:AdditionalSecurityProviders=com.sun.security.sasl.Provider</buildArg>
<buildArg>--initialize-at-run-time=org.apache.kafka.common.security.authenticator.SaslClientAuthenticator</buildArg>
```

Adding the SASL security provider, and flagging the `SaslClientAuthenticator` to be initialized at run-time, with the Substitution class.

## Initializations

The next configuration is to force initialization of certain class paths at build time to get them in the binary:

Kafka clients:
```xml
<buildArg>--initialize-at-build-time=[...]org.apache.kafka,kafka[...]</buildArg>
```

Log4j logging:
```xml
<buildArg>--initialize-at-build-time=org.slf4j.LoggerFactory,org.slf4j.impl.StaticLoggerBinder,org.slf4j.impl.SimpleLogger,[...]</buildArg>
```
This will change depending on the SLF4J implementation used.

If Jackson is used, then the following set of classes were required on my implementation:
```xml
<buildArg>--initialize-at-build-time=[...],com.fasterxml.jackson,jdk.xml,javax.xml,com.sun.org.apache.xerces,org.yaml.snakeyaml</buildArg>
```

Identifying these clases is an iterative process.
Exceptions like the following will appear if the right classes are not defined to initialize at build time:

```
Error: Classes that should be initialized at run time got initialized during image building:
 org.yaml.snakeyaml.external.com.google.gdata.util.common.base.PercentEscaper was unintentionally initialized at build time. To see why org.yaml.snakeyaml.external.com.google.gdata.util.common.base.PercentEscaper got initialized use --trace-class-initialization=org.yaml.snakeyaml.external.com.google.gdata.util.common.base.PercentEscaper
org.yaml.snakeyaml.nodes.Tag was unintentionally initialized at build time. To see why org.yaml.snakeyaml.nodes.Tag got initialized use --trace-class-initialization=org.yaml.snakeyaml.nodes.Tag
org.yaml.snakeyaml.util.UriEncoder was unintentionally initialized at build time. To see why org.yaml.snakeyaml.util.UriEncoder got initialized use --trace-class-initialization=org.yaml.snakeyaml.util.UriEncoder
org.yaml.snakeyaml.external.com.google.gdata.util.common.base.UnicodeEscaper was unintentionally initialized at build time. To see why org.yaml.snakeyaml.external.com.google.gdata.util.common.base.UnicodeEscaper got initialized use --trace-class-initialization=org.yaml.snakeyaml.external.com.google.gdata.util.common.base.UnicodeEscaper
```

## Kafka client reflection configurations

Apart from the initialization, a set of reflection configurations are required:

{{< gist jeqo 44db9e27048ae3c4bcc9bb49ead7df22 "kafka-client-reflection.json" >}}

Then, adding this configuration file to the build arguments:

```xml
<buildArg>-H:ReflectionConfigurationFiles=../src/main/resources/META-INF/native-image/io.github.jeqo.kafka/kafka-clis/reflect-kafka-client.json,[...]</buildArg>
```

## (Optional) Enabling HTTP/HTTPS protocols

If your application requires access to HTTP/HTTPS as client or server, then these protocols should be enabled:

```xml
<buildArg>--enable-url-protocols=http</buildArg>
<buildArg>--enable-url-protocols=https</buildArg>
```

## (Optional) Include resources

As part of the image, there might be some additional resources required like logging configurations, schemas, etc.

Files to be added can be defined as arguments, or registered on a resource-configuration JSON file:

{{< gist jeqo 44db9e27048ae3c4bcc9bb49ead7df22 "resources-config.json" >}}

In this case, Avro schemas are loaded.

Adding the following arguments should help to add these files as part of the building process, and log them for debugging:

```xml
<buildArg>-H:Log=registerResource:3</buildArg>
<buildArg>-H:ResourceConfigurationFiles=../src/main/resources/META-INF/native-image/io.github.jeqo.kafka/kafka-clis/resource-config.json</buildArg>
```

```
[1/7] Initializing...                                                                                   (11.9s @ 0.20GB)
 Version info: 'GraalVM 22.0.0.2 Java 17 CE'
[Use -Dgraal.LogFile=<path> to redirect Graal log output to a file.]
[thread:1] scope: main
  # ...
  ResourcesFeature: registerResource: credit_cards.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: orders_schema.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: users_array_map_schema.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: pageviews_schema.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: users_schema.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: ratings_schema.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: stores.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: transactions.avro
  [thread:1] scope: main.registerResource
  ResourcesFeature: registerResource: cli.properties
  [thread:1] scope: main.registerResource
  # ...
```

## (Optional) Confluent Schema Registry reflection configuration

As for Kafka clients, Schema Registry client also require additional reflection configuration to get to request/response beans built:

{{< gist jeqo 44db9e27048ae3c4bcc9bb49ead7df22 "schema-registry-client-reflection.json" >}}

And concat the reflection configuration as an argument:

```xml
<buildArg>-H:ReflectionConfigurationFiles=[...],../src/main/resources/META-INF/native-image/io.github.jeqo.kafka/kafka-clis/reflect-schema-registry.json</buildArg>
```

Additional resources: <https://quarkus.io/guides/kafka-schema-registry-avro>

## Additional: open issues with Jackson

At the moment, I haven't been able to write string out of a POJO, and have been using the workaround to build a `JsonNode` before writing JSON string.

## Summary

Even though there is still a bunch of configuration and large reflection files to deal with, I'm happy to reach a baseline configuration to build Java binary images for Kafka client applications.
I have started with a couple CLI implementations:

- A CLI to list Kafka topics, but getting more metadata about partitions, replica placement, configurations, and offsets: <https://github.com/jeqo/poc-apache-kafka/tree/main/cli/topic-list>
- A CLI to mix kafka-producer-perf-test with Confluent Datagen library to generate more real-life data and use it for performance tests: <https://github.com/jeqo/poc-apache-kafka/tree/main/cli/producer-datagen>

Still a lot of unknowns for me when using GraalVM, but this seems like a good starting point.
