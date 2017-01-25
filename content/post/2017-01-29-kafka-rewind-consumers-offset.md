---
title: Rewind Kafka Consumer Offsets
date: 2017-01-29
section: post
tags:
- kafka
categories:
- integration
---

One of the most important features from *Apache Kafka* is how it manages
Multiple Consumers. Each *Consumer Group* has a current *OffSet*, that
determine at what point in a *Topic*, this *Consumer Group* has consume
messages. So, each *Consumer Group* can manage its *OffSet* independently.

This offers the possibility to rollback in time and reprocess messages from
the beginning of a *topic* and regenerate the current status of the system.    

But how to do this?

<!--more-->

## Basic Concepts

### Topics and Offsets

First thing to understand to achieve Consumer Rewind, is rewind over what?
Because `topics` are divided into `partitions`. This partitions allows
*parallelism*, because each partitions accepts `writes` from `producers`. So,
each partition has its own `offset`.

Each `record` has its own `offset` that will be used by `consumers` to define
which messages has been consumed.

### Consumers and Consumer Groups

Once we understand that `topics` have `partitions` and `offsets` by `partition`
we can now understand how `consumers` and `consumer groups` work.

`Consumers` are grouped by `group.id`. This property identify you as a
`consumer`, so the `broker` knows which was the last `record` you have
consumed by `offset`, by `partition`.

## From Command-Line

In this first scenario, we will see how to manage offsets from *command-line*
so it will be easy to implement in your application.

### Case 1: Back to the Beginning



### Case 2: Back to a specific OffSet


### Case 3: Back to a specific Timestamp


## From Java Clients

### Case 1: Back to the Beginning


### Case 2: Back to a specific OffSet


### Case 3: Back to a specific Timestamp



****
**References**

* https://cwiki.apache.org/confluence/display/KAFKA/KIP-32+-+Add+timestamps+to+Kafka+message

* https://cwiki.apache.org/confluence/display/KAFKA/KIP-33+-+Add+a+time+based+log+index

* https://cwiki.apache.org/confluence/display/KAFKA/FAQ#FAQ-HowcanIrewindtheoffsetintheconsumer?

* http://stackoverflow.com/questions/22558933/in-kafka-how-to-get-the-exact-offset-according-producing-time

****
