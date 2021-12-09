---
title: Kafka data loss scenarios
date: 2021-12-09
section: notes
tags:
- kafka
- durability
categories: 
- ops
---

Kafka topic partitions are replicated across brokers.
Data loss happens when the brokers where replicas are located are unavailable or have fully failed.
The worst scenario — and where is no much to do — is when all the brokers fail; then no remediation is possible.
Replication allows to increase redundancy so this scenarios is less likely to happen.

The following scenarios show different trade-offs that could increase the risk of lossing data:

## Choose reusing infrastructure (cost) at the risk of impacting multiple components

For brokers to be less likely to fail together are usually placed in different locations, e.g. physical servers, racks, data-centers, availability zones, regions.

If, for cost effectiveness, brokers end up in shared locations, then the chances to fail together may increase.

For instance all brokers could end up in the same backing physical server.
If the physical server fails, then all brokers will fail.

Same happen with any other location (e.g. Availability zones), and this is what leads to [topologies across regions](https://docs.confluent.io/platform/current/multi-dc-deployments/multi-region.html).

Be careful about shared resources.

## Choose throughput at the risk of lossing data

Replicas follow a 1-leader/many-followers model, where writes only happen at the leader, and the leader waits for the followers to be up-to-date before ack back to the producer — only when the producer is configured with `ack=all`.
If the producer has a lower durability guaranty than `acks=all` — 1 or 0 —, then produce request's lifecycle will be much faster — no waiting for replicas. 
Latency and throughput — from producer's perspective — are heavely impacted when `acks` is reduced from `all` to `1` or `0`.

If data is acknowledged only when written to 1 replica, then we risk lossing data as it is only confirmed to be in 1 node.

One can even end up ack'ng on 1 replica without `acks != all`:

- (Obviously) if partition only have 1 replica.
- If [`min.insync.replicas`](/til/2021-12-02-kafka-min-isr/) is equal to 1 and followers are unavailable — i.e. out of the ISR.

Remember: [reducing `acks` doesn't really reduce the overall latency](/til/2021-12-09-kafka-reducing-acks/), and `acks=all` [is now the default](/til/2021-12-09-kafka-v3-idempotent-acks-all/).

## Choose availability in the face of potential data loss

