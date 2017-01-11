---
title: Scaling Kafka with Docker Containers
date: 2017-01-10
section: post
tags:
- kafka
- docker
categories:
- devops
- integration
draft: true
---

In this post I will try to show some of the considerations and challenges to
deploy Kafka clusters with Docker Containers.

<!--more-->

***
Repository: https://github.com/jeqo/post-kafka-containers-scaling
***

# Single-Node Cluster

First of all, let's start with the most simple way to run Docker, that
could be useful for some development scenarios: **Single-Node Cluster**

Apache Kafka architecture is based in 2 main components: The *Apache
Kafka server* itself, and the *Apache Zookeeper server* used for internal
coordination.

That's why a Kafka single-node cluster requires at least a
couple of processes.

If we talk in Container terms and practices, these processes should be
run in 2 different containers.

The easiest way to do this is defining these processes as
Docker Compose services is a `docker-compose.yml` file:

***
I will use a couple of images that I build. These are fairly simple
and you can find their source code here:
[Apache Kafka](https://github.com/jeqo/docker-image-apache-kafka)
 and [Apache Zookeeper](https://github.com/jeqo/docker-image-apache-zookeeper)
***

{{< highlight yaml >}}
version: "2.1"
services:
  kafka:
    image: jeqo/apache-kafka:0.10.1.0-2.11
    environment:
      ZOOKEEPER_CONNECT: zookeeper:2181
    links:
      - zookeeper
  zookeeper:
    image: jeqo/apache-zookeeper:3.4.8
    volumes:
      - ./zoo.cfg:/opt/apache-zookeeper/conf/zoo.cfg
{{< /highlight >}}

This configuration defines 2 services: `kafka` and `zookeeper`. The `kafka`
service link and environment variable `ZOOKEEPER_CONNECT` configure the access
from `kafka` to `zookeeper` service.

If we try to start these configuration with `docker-compose up -d`,
Docker Compose will create a `network` where these service can communicate.

{{< highlight yaml >}}
jeqo@jeqo-Oryx-Pro:.../single-node-kafka-cluster$ docker-compose up -d
Creating network "kafkacluster_default" with the default driver
Creating kafkacluster_zookeeper_1
Creating kafkacluster_kafka_1
{{< /highlight >}}

If you want to communicate with the cluster from your application's
docker-compose configuration, you can do it as follows:

{{< highlight yaml >}}
version: "2.1"
services:
  kafka:
    image: jeqo/apache-kafka:0.10.1.0-2.11
    command: sleep infinity
    networks:
      - default
      - kafkacluster_default #(2)
networks: #(1)
  kafkacluster_default:
    external: true
{{< /highlight >}}

Here we define first an `external network` called `singlenodekafkacluster_default`
that will give us access to the kafka cluster network. Then we add this network
to the service network.

To test our client, start it up running `docker-compose up -d` and then connect
to the cluster with the following command:

{{< highlight bash >}}
$ docker-compose exec kafka bash
# bin/kafka-console-producer.sh --broker-list kafka:9092 --topic topic1
test
# bin/kafka-topics.sh --zookeeper zookeeper:2181 --list      
topic1
{{< /highlight >}}

# Multi-Node Cluster

To scale a container using Docker Compose is as simple as using the `scale` command:

{{< highlight bash >}}
docker-compose scale kafka=3
{{< /highlight >}}

This will create 2 more containers:

{{< highlight bash >}}
$ docker-compose scale kafka=3
Creating and starting kafkacluster_kafka_2 ... done
Creating and starting kafkacluster_kafka_3 ... done
{{< /highlight >}}

You, as an application developer, only need to know one of the `broker` IPs, or use the service
name to connect to the cluster. As the documentation specifies, the client (eg. producer or consumer)
will use it only once to get the Kafka `broker` IPs from the same cluster. This means that 
Kafka scaling will be transparent to your application.

To validate that all brokers are part of the cluster let's use Zookeeper client to check. From
client container:

{{< highlight bash >}}
$ docker-compose exec kafka bash
# bin/zookeeper-shell.sh zookeeper:2181
ls /brokers/ids
[1003, 1002, 1001]
{{< /highlight >}}

# Considerations to scale Topics

