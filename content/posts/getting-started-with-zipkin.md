---
title: Getting started with Zipkin
date: 2019-10-20
section: post
tags:
- tracing
- zipkin
categories:
- observability
---

As interest grows on how to _enable_ telemetry (ie. logging, metrics, traces) on
applications and to actually _make usage_ of this data; understanding how the
infrastructure supporting this works, becomes more important.

In this post, we will go review how Zipkin can be used on the application side to
produce tracing data, and how it works as infrastructure.
 
# Getting started with Zipkin

## What's distributed tracing?

If you have more than one component as part of your system collaborating to deliver some 
value, you are on distributed computing land.

On this context, we require data that help us to understand how this system behaves.

Different types of telemetry data offer different views and dimensions of behavior: 
metrics help to count things--how many times something happen, how long did it took--, 
logs record application-scoped events--a component changing from a healthy status into a 
non-healthy. Traces focus on **transaction-scoped** events--how long a task takes to run,
which task triggers another one (_happens-before_ relation). 

Be aware that collecting **any** of this data sources will require _some_ additional 
work on your application side, so make sure you _know_ why are you collecting this data 
for.

In the case of tracing there are different kind of potential use-cases: debugging 
transations, latency analysis, service dependency, path aggregation, etc. In general, 
it represents data about how components collaborate and latency patterns.

Distributed tracing is about reproducing traces from a distributed environment.
We can summize how it works on the following steps: (1) first would be to
record traces on individual components. Then, (2) to capture _happens-before_ relation
between components, some metadata needs to be passed between them. Finally, (3) to 
recreate complete traces, correlated parts need to be aggregated in some storage.

## What is Zipkin?

Zipkin is a distributed tracing system, composed by a set of libraries to record, 
correlate, and report tracing data from clients, and a tracing platform to collect, 
aggregate and store traces. 

## Application side

## Infrastructure side

## Tracing data
