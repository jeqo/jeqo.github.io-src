---
title: Notes on Kafka, Samza and the Unix Philosophy of Distributed Data
date: 2018-07-27
tags:
- kafka
- samza
categories:
- notes
---

<!--more-->

## From Batch to Streaming workflows

Key properties for large-scale systems:

> [Large-Scale Personalized Services] should have the following properties: 
>
> * System scalability
> * Organizational scalability
> * Operational robustness

Where Batch jobs have been successfully used, and represent a reference model to improve from:

> [Batch, Map-Reduce jobs] has been remarkably successful tool for implementing recommendation systems.
> 
> [Batch important benefits:]
>
> * Multi-consumer: several jobs reading input directories without affecting each others.
> * Visibility: job's input and output can be inspected for tracking down the cause of an error.
> * Team Interface: Directory names, output from one team's job, can be used as input for other team, acting as a interface.
> * Loose coupling: Jobs can be implemented in different languages, using different libraries, relying on the same format.
> * Data provenance: With explicit inputs and outputs for each job, the flow of data can be tracked through the system.
> * Failure recovery: If job 46th out of 50 fail, we can restart from job 46th instead of re-run the entire workflow.
> * Friendly to experimentation: Most jobs modify only their designated output directories, and have no other side effect.
>
>
> When moving from a high-latency batch system to a low-latency streaming system, we wish to preserve the attractive properties listed above.
>
> By analogy, consider how Unix tools are composed into complex programs using shell scripts. A workflow of batch jobs is comparable to a shell 
script which there is no pipe operator, so each program should write and read from temporal files on disk. In this scenario, one program must
finish writing its output file before another program can start reading it.
>
> To move from batch to a steraming data pipeline, the temporary files would need to be replaced with something more like Unix pipes.
> [...] However, Unix pipes do not have all the properties we want: they connect one output to exactly one input (not multi-consumer), and
> then cannot be repaired if one of the processes crashes and restarts (no fault recovery)

Then Kafka and Samza are explained as components to support Streaming data piples for large-scale services.

## Discussion

Kafka, on one side, is focused on making replicated logs as efficient and performant as possible.

> Kafka's focus on the log abstraction is reminiscent of the Unix philosophy: **"Make each program do one thing well. To do a new job, build
afresh rather than complicated old programs by adding 'new features'"**

Samza on the other side, is focus on Stream processing: 

> Each Samza Job is structurally simple: it is jost one step in a data processing pipeline, with Kafka topics as inputs and outputs. If Kafka is 
like a streaming version of HDFS, then Samza is like a streaming version of MapReduce.

> This principle again evokes a Unix maxim: **"Expect the output of every program to become the unput to another, as yet unknown, program."**

> Kafka topics deliberately do not provide backpressure: the on-disk log acts as an almost-unbounded buffer for messages.

### Unix as a Role Model

> ... the log-oriented model of Kafka and Samza is fundamentally built on the idea of composing heterogeneous system through the uniform interface
of a replicated, partitioned log.
> Individual systems for data storage and processing are encouraged to do one thing well, and to use logs as input and output. 
> Even though Kafka's logs are not the same as Unix pipes, they encourage composability, and thus Unix-style thinking.


