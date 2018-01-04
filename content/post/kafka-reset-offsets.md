---
title: Reset Kafka Consumer Offsets and my first contribution to Apache Kafka
date: 2018-01-03
section: post
tags:
- kafka
categories:
- integration
draft: True
---

After writing a previous post about [rewind offsets in Apache Kafka consumers](https://jeqo.github.io/post/2017-01-31-kafka-rewind-consumers-offset/),
I started one of the most valuable experience in 2017 for me: participate and make my first contribution to the Apache Kafka project.

In my post, I explain how we can use `Kafka Consumer API` to move Consumer instances along log offsets, but I realize it was a bit too much work
to code this utilities to reset offsets to an specific point in time. That's how I found an opportunity to contribute.

<!--more-->

[The idea](https://cwiki.apache.org/confluence/display/KAFKA/KIP-122%3A+Add+Reset+Consumer+Group+Offsets+tooling) was to add a command-line utility to reset offsets by consumer group.
But as this is a public-facing interface, it is required to create
a [KIP (Kafka Improvement Proposal)](https://cwiki.apache.org/confluence/display/KAFKA/Kafka+Improvement+Proposals) that is a process defined
by the community to discuss and vote a change that impact users directly (i.e. important changes like [Headers](https://cwiki.apache.org/confluence/display/KAFKA/KIP-82+-+Add+Record+Headers)
or [Exactly-once semantics](https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging) has been
discussed and voted this way).

Once I started this process, community engaged and start providing feedback about this feature, how it will impact and what benefits were useful or not.
This discussion process took about 1 or 2 months, that were incredibly valuable for me. I met people I only follow by Twitter
(thanks a lot to [@mjsax](https://twitter.com/mjsax) and [@gwenshap](https://twitter.com/gwenshap)) and contributors that
were always helpful to move this proposal forward.

Voting and then implementing changes was also very enriching as it was my first real-life experience with Scala :)

{{< tweet 865200633518968834 >}}

Some time after merging this change, there was a new opportunity to add similar capabilities to Kafka Streams applications.
Hence this become my next KIP: [KIP-171](https://cwiki.apache.org/confluence/display/KAFKA/KIP-171+-+Extend+Consumer+Group+Reset+Offset+for+Stream+Application)

I will explain in this post, how these tools can be used.

//TODO