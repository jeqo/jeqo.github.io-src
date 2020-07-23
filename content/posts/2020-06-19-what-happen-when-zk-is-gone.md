---
title: What happen with your Kafka cluster when Zookeeper is gone? (not related with KIP-500)
date: 2020-06-19
tags:
- kafka
- zookeeper
draft: yes
---

This post will try to answer this question:

If you have a running environment with a Kafka cluster and Zookeper ensemble, what would happen if we lose all the Zookeeper nodes and start with a clean ensemble?

> Although this question is not related with [KIP-500](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500%3A+Replace+ZooKeeper+with+a+Self-Managed+Metadata+Quorum), it might become irrelevant once this KIP is adopted. 

## Scenarios

I can imagine 2 scenarios:

1. The Zookeeper ensemble is lost while Kafka cluster running.
2. The Zookeeper ensemble is lost while Kafka cluster is down.

and things to verify:

* What happen with Kafka topics metadata?
* What happen with Cluster metadata?