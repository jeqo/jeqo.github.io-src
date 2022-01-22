---
title: Kafka partitioning
date: 2022-01-13
section: posts
draft: true
tags:
- kafka
categories:
- ops
---

## Capacity planning

- eventsizer.io
- main factor: consumer throughput assuming traditional consumption pattern
  - workarounds: parallel consumer
- other factors:
  - key cardinality


## Changing number of partitions

Considerations:
- Reprocessing: could the producer reproduce events (e.g. CDC)?
- Consumer starting offsets
- Consumer state management
- Retention and Consumer reprocessing

### YOLO: Increasing number of partitions

Btw, not possible to decrease number of partitions, maybe because it could lead to data loss (?)

### Versioned topics

## Ideas

If versioned topics end up being the right answer from a producer point-of-view, wouldn't be nice to have a consumer capability to continue the processing from `v2` without requiring changes?
