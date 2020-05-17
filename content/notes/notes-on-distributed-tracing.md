---
title: Notes on Distributed Tracing
date: 2020-05-17
tags:
  - zipkin
  - observability
  - distributed-tracing
---

Distributed Tracing is a technique to trace _distributed_ components.

It seems redundant to highlight the 'distributed' part, but I believe this is key to understand in order to use this technique effectively.

<!--more-->

Tracing is about producing evidence. Is about been making explicit some _internal_ phenomena. If it's already explicit, there is no need to trace it.

It produces a _parallel_ record of action. The system _do_ something, but it also _records evidence_ about it.

First example that pops into my mind is logging working hours (one of the most unpleasant activities, though): You end up your day (or week), login to the tracking system, and record the time you spend doing certain activities&mdash;always with extreme precision, right?

The same reason it is _impossible_ to trace **everything** in your distributed system, is the same reason it is _impossible_ for you (or someone else) to track _everything_ you do at work. If you try to track everything you do, you end up doing _nothing_&mdash;or become very ineffective. Therefore, been careful about what you trace, and **why**, becomes extremely important.

Actually, this is not different than using logging or metrics. 

With logging, we somehow become used to the idea that _it is ok_ to pay the price of logging _as much as you need_. Then it becomes normal to log (or not) as we pleased&mdash;poor distributed tracing, arriving late to the party.

With metrics, the dimension is different, as metrics are _cheaper_ to collect and store (`time+value+tags`), and to be any useful at least we are forced to name them&mdash;different than logging, where we usually don't care.

At the end these option end up been _just_ data structures to record behavior. There is nothing really special about distributed tracing compared with metrics and logging&mdash;or any other form of system measurement&mdash;other than it's data structure, and how that data structure is used to converge understanding.

***

Distributed, as in distributed tracing, means _multiple moving parts_; where these could be processes in the same machine, services communicating over the internet, multiple collaborative threads in the same host, or even different modules on the same (monolithic?) application.

These collaborations, and their _scale_, then becomes the main tracing targets.

Scale in this context is represented on how we move between different contexts in the examples provided above: we could trace service to service collaboration, and drill-down into how modules collaborate inside a service, and drill-down on how threads work.  

Not all scales are important at all times, though. Some of them unlock undestanding of the system once in a while; others can help us undestanding how a service collaboration worked at a certain point in time. Some of them represent an "audit log" of a business process and therefore become a business asset&mdash;therefore requiring to persist every trace.

***

Main components to trace distributed collaboration: 

- Client-side:
  - A **Tracer** to trace _local_ tasks.
  - **Context-propagation** mechanism, to let other components know, or tag, where to correlate their local tasks to a bigger one. e.g. "this tasks is part of this _distributed_ transaction".
  - And **Reporter**(s) to send trace segments to the tracing infrastructure.
- Server-side:
  - **Collectors**, to get distributed segments of traces together.
  - And **Storage**(s), to persist _complete_ traces.

***

By being an low-level diagnostic and debugging tool, Distributed Tracing has multiple edges to run into (and probably one of the reasons I'm still excited to keep contributing to Zipkin): 

* programming language support, 
* framework instrumentation, 
* scalability, 
* eventual-consistency, 
* sampling, 
* significance, 
* API design, and much, much more.
