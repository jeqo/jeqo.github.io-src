---
title: Aggregate logs with sqlite
date: 2022-09-24
draft: true
tags:
- sqlite
- datasette
- ops
- troubleshooting

categories:
- til
---

While debugging distributed applications (e.g. Kafka Streams)
there is a need to aggregate log files and correlate events to understand certain behaviours.
For instance, when Kafka Streams instances rebalance,
all members exchange messages with the group coordinator on the broker side
until tasks are distributed and each member starts running its assigned tasks.
However, when errors happen, its not always easy to spot the reason,
and events from multiple instances are required to spot the root causes.
If no log aggregation platform (e.g. Splunk, Elasticsearch) is around, sqlite can 
