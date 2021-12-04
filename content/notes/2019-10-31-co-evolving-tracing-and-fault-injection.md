---
title: Notes on Co-evolving Tracing and Fault Injection with Box of Pain
date: 2019-10-31
tags:
- distributed systems
- tracing
- fault injection
- peter alvaro
- daniel bittman
- ethan l miller
categories:
- papers
---

This paper explores how related tracing and fault injection systems are, and if they should be part of the same _thing_.

> The space of possible executions of a distributed system is exponential in the number of communicating precesses and the number of messages, [...]

> [...] some of the most pernicious bugs in distributed programs involve mistakes on how programs **handle partial failure** of remote components.

In order to expose this failures, fault injection mechanisms are used to cause network partitions, or machine crashes.

> Our philosophy on tracing and fault-injection is three-fold. First, faults such as machine crashes and network partitions will always manifest themselves at _remote_ nodes as the _absense_ of a message.
>
> Second, we believe that although the space of possible executions of a distributed system is exponentially large in the number of events, in practice some executions are significantly more likely than others; thus, even if an understanding of a system is based on witnessing shedules of executions, we can bound the number of shcedules we are likely to see.
>
> Third, tracing and fault-injection should co-evolve--tracing is necessary to inform and perform targeted fault-injection, which can only perturb events in a language that is defined _by_ the tracing infrastructure itself; this, **economy of mechanisms overweights separation of concerns**

Box of pain is a tool composed of both mechanisms, based on 3 components: a _tracer_, a _tracker_, and an _injector_. It is designed to be used in test environments.

The paper includes a discussion on why it chooses **ptrace** (kernel-level, system call tracing) instead of application level traces:

> Tracing infrastructure often involves a trade-off between the complexity of kernel-level tracing and the overhead of application-level instrumentation.

> It remains to be shown that it is possible to extrapolate from our low-level traces to something akin to the application-level signal provided by call graph tracing.

Box of pain `tracker` aims to aggregate and traces produced and identify most probable patterns of communication, and produce input for fault-injector to act.

> Bug-finding software can then consider faults in terms of "after thread _T_ does _x_ but before _y_", improving how _targeted_ faults can be.

> We have initial evidence that not only is it possible to trace a distributed system at the system-call level and recover _happens-before_ such that we can decide and target faults to inject, **but we can do this without non-determinism becoming intractable**

> Box of Pain promises to open up the LDFI approach to arbitratry, uninstrumented systems, including distributed data management systems, configuration services, and message queues.