---
title: Apache Kafka
date: 2018-01-06
section: notes
tags:
- kafka
categories:
- notes
---

<!--more-->

## Contributions

* KIP-122: Add Reset Consumer Group Offsets tooling https://cwiki.apache.org/confluence/display/KAFKA/KIP-122%3A+Add+Reset+Consumer+Group+Offsets+tooling

* KIP-171 - Extend Consumer Group Reset Offset for Stream Application https://cwiki.apache.org/confluence/display/KAFKA/KIP-171+-+Extend+Consumer+Group+Reset+Offset+for+Stream+Application

* KIP-222 - Add Consumer Group operations to Admin API https://cwiki.apache.org/confluence/display/KAFKA/KIP-222+-+Add+Consumer+Group+operations+to+Admin+API

* KIP-244: Add Record Header support to Kafka Streams https://cwiki.apache.org/confluence/display/KAFKA/KIP-244%3A+Add+Record+Header+support+to+Kafka+Streams

## References

### Architecture

* **Turning the database inside-out with Apache Samza** - Martin Kleppmann https://martin.kleppmann.com/2015/03/04/turning-the-database-inside-out.html

### Schemas

* **Streaming Microservices: Contracts & Compatibility** https://www.infoq.com/presentations/contracts-streaming-microservices#

* **RESTful service for holding schemas** https://issues.apache.org/jira/browse/AVRO-1124

### Change Data Capture - CDC

* **Bottled Water: Real-Time integration of PostgreSQL and Kafka** - Martin Kleppmann: https://martin.kleppmann.com/2015/04/23/bottled-water-real-time-postgresql-kafka.html

### Microservices and Kafka

* **The Data Dichotomy: Rethinking the Way We Treat Data and Services** https://www.confluent.io/blog/data-dichotomy-rethinking-the-way-we-treat-data-and-services/

  > **Streams: A Decentralized Approach to Data and Services**
  > 
  > This particular compromise involves a degree of centralization. We can use a Distributed Log for this as it provides retentive, scalable 
  > streams. Now we need our services to be able to join and operate on these shared streams, but we want to avoid complicated, centralized 
  > ‘God Services’ that do this type of processing.  So a better approach is to embed stream processing into each consuming service. That 
  > means services can join together various shared datasets and iterate on them at their own pace.

* **Experimental CQRS and Event Sourcing service** https://github.com/capitalone/cqrs-manager-for-distributed-reactive-services 

* **Architecting a Modern Financial Institution** https://www.infoq.com/presentations/nubank-architecture

* **Should you put several event types in the same Kafka topic?** - Martin Kleppmann: 
https://martin.kleppmann.com/2018/01/18/event-types-in-kafka-topic.html

* **Event-First Development: Moving Towards Kafka Pipeline Applications** - Zalando:
https://jobs.zalando.com/tech/blog/event-first-development---moving-towards-kafka-pipeline-applications/

### Performance Tuning

* **Improving Kafka At-Least-Once Performance** -- Ying Zheng, Uber (Dec. 4, 2017) https://www.youtube.com/watch?v=zrU7r95chHU

* **Tuning Kafka for low latency guaranteed messaging** -- Jiangjie (Becket) Qin (LinkedIn), 6/15/16 https://www.youtube.com/watch?v=oQe7PpDDdzA