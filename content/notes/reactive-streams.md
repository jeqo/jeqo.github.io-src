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

## Projects

### Akka Streams

#### Shapes or "boxes"

Every processing stage can be imagined as a "box". `Source` is a "box" with a single output `port`.

Common shapes:

* `Source`: single output `port`
* `Sink`: single input `port`
* `Flow`: single input `port` and single output `port`
* `FanIn`: two input `ports` and one single output `port`
* `FanOut`: single input `port` and two output `ports`
* `BidiFlow`: two input `ports` and two output `ports`

#### GraphStage

> The `GraphStage` abstraction can be used to create arbitrary graph processing stages 
> with *any number of input or output ports*. 

> It is a counterpart of the GraphDSL.create() method which creates new stream processing stages by composing others

A `GraphStage` requires a Shape. 

### Reactive Kafka (Alpakka Kafka Connector) 

https://github.com/akka/reactive-kafka

`scaladsl/Consumer.scala`

Sources are build by utility methods:

* `plainSource()`
* `committableSource()`
* `atMostOnceSource()`
* `plainPartitionedSource()`
* `plainPartitionedManualOffsetSource()`
* `commitablePartitionedSource()`
* `plainExternalSource()`
* `committableExternalSource()`

All of these, used `Source.fromGraph()` where `ConsumerStage` build GraphStages that are passed to `Consumer`.

Every `ConsumerStage` method implements abstract class `KafkaSourceStage`:

```
  abstract class KafkaSourceStage[K, V, Msg]()
    extends GraphStageWithMaterializedValue[SourceShape[Msg], Control] {
```

And the abstract method `KafkaSourceStage#logic(SourceShape[Msg])`.

For instance, for `plainSource()`, logic is implemented by `SingleSourceLogic`. This logic uses `KafaConsumerActor`
to pull, or `pump()` data from Topic Partitions.

`SingleSourceLogic` implements `GraphStageLogic` that contains a method `setHandler(out: Outlet[_], handler: OutHandler): Unit`
that defined a handler, with Shape logic.

In the case of `OutHandler` the following methods need to be implemented:

```
    override def onPull(): Unit = {
      //
    }

    override def onDownstreamFinish(): Unit = {
      //
    } 
```

In `KafkaSourceLogic` `onPull()` call `pump()` to get `ProducerRecord` from Kafka and once it is available, one by one **if output shape is avaiable**:

```
  @tailrec
  private def pump(): Unit = {
    if (isAvailable(shape.out)) { // validates availability of output
      if (buffer.hasNext) { // if record batch has elements avaiable
        val msg = buffer.next()
        push(shape.out, createMessage(msg)) // one message at a time is sent to output shape1
        pump() // recursion
      }
      else if (!requested && tps.nonEmpty) {
        requestMessages()
      }
    }
  }
```

