---
title: Kafka, Samza and the Unix Philosophy of Distributed Data
date: 2018-07-27
section: notes
tags:
- kafka
- samza
categories:
- notes
---

<!--more-->

## From Batch to Streaming workflows

> [Large-Scale Personalized Services] should have the following properties: 
> * System scalability
> * Organizational scalability
> * Operational robustness

> [Batch, Map-Reduce jobs] has been remarkably successful tool for implementing recommendation systems.

> [Batch important benefits:]
> * Multi-consumer: several jobs reading input directories without affecting each others.
> * Visibility: job's input and output can be inspected for tracking down the cause of an error.
> * Team Interface: Directory names, output from one team's job, can be used as input for other team, acting as a interface.
> * Loose coupling: Jobs can be implemented in different languages, using different libraries, relying on the same format.
> * Data provenance: With explicit inputs and outputs for each job, the flow of data can be tracked through the system.
> * Failure recovery: If job 46th out of 50 fail, we can restart from job 46th instead of re-run the entire workflow.
> * Friendly to experimentation: Most jobs modify only their designated output directories, and have no other side effect.

> When moving from a high-latency batch system to a low-latency streaming system, we wish to preserve the attractive properties listed above.

> By analogy, consider how Unix tools are composed into complex programs using shell scripts. A workflow of batch jobs is comparable to a shell 
script which there is no pipe operator, so each program should write and read from temporal files on disk. In this scenario, one program must
finish writing its output file before another program can start reading it.

> To move from batch to a steraming data pipeline, the temporary files would need to be replaced with something more like Unix pipes.
> [...] However, Unix pipes do not have all the properties we want: they connect one output to exactly one input (not multi-consumer), and
> then cannot be repaired if one of the processes crashes and restarts (no fault recovery)

Then Kafka and Samza are explained as components to support Streaming data piples for large-scale services.

## Discussion


