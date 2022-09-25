---
title: Changing Kafka Broker's rack
date: 2021-12-10
tags:
- kafka
- deployment
- ops
categories: 
- til
---

Kafka broker configuration includes a `rack` label to define the location of the broker.
This is useful when placing replicas across the cluster to ensure replicas are spread across locations _as evenly as possible_.

<!--more-->
This label may need to change for different reasons.
One I found today is if you want to redefine locations [to support Multi-Region clusters and Observers](https://docs.confluent.io/platform/current/multi-dc-deployments/multi-region.html#replica-placement).

{{<zoom-img src="topologies.png">}}

If there are existing topics, and previous rack labels were already used when creating the topics, then the placement may not match the new topology. 

Looks like `confluent-balancer` covers this as one of the criterias to move partition replicas across the cluster, so after re-labeling the brokers with the new `broker.rack` configurations, applying the change to existing topics is as easy as:

```bash
confluent-rebalancer execute \
    --bootstrap-server localhost:9092 \
    --metrics-bootstrap-server localhost:9092 \
    --throttle 10000000 \
    --verbose
```

Docs: https://docs.confluent.io/platform/current/kafka/rebalancer/index.html#execute-the-rebalancer
