---
title: Changing void returning type in Java methods breaks binary compatibility
date: 2022-02-16
section: til
tags:
- java
- compatibility

categories:
- dev
---

While [proposing changes to Kafka Streams DSL](https://cwiki.apache.org/confluence/display/KAFKA/KIP-820%3A+Extend+KStream+process+with+new+Processor+API), I propose changing the return type of one method from `void` to `KStream<KOut, VOut`.
I was under the (wrong) impression that this change wouldn't affect users.
I was also not considering that applications might just drop a new library without recompiling their application.

<!--more-->

This change is what is known as _source compatible_ but not _binary compatible_ — meaning the user will need to recompile their application.

If you drop a newer version into your application expecting a void method would case this:

```shell
java -jar kafka-streams-poc-new-transformer-1.0-SNAPSHOT.jar
Exception in thread "main" java.lang.NoSuchMethodError: 'void org.apache.kafka.streams.kstream.KStream.process(org.apache.kafka.streams.processor.api.ProcessorSupplier, java.lang.String[])'
        at poc.App.topology(App.java:41)
        at poc.App.main(App.java:22)
```
