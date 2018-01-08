---
title: Data on the Outside vs Data on the Inside
date: 2018-01-06
section: notes
tags:
- distributed systems
- microservices
- pat helland
categories:
- papers
---

I found this paper as relevant and accurate today as it was in 2005, when it was published. 
It is fascinating how even 12 years later and with new technologies in vogue, 
same concepts keep applying.

Overall, I found esential to evaluate concepts proposed here by **Pat Helland** in relation
with Microservices: This paper is describing challenges that we, as developers, will have to deal when 
they are moving from a *monolithic* architecture (when we can trust that all components are located 
in the same context - i.e. same server), and you have to go out and face a reality where parts of your
system a not any more tied to the same space and time; and methods like atomic transactions implemented
by protocols like 2PC (Two-Phase Commit) are not recommended as they go against one of the goals of 
distribute your system that is increase your availability.

The author start explaining Service-Oriented Architecture (SOA) characteristics, currently related with Microservices:

> Each service comprises a chunk of code and data that is private to that service. Services are different than the classic application
> living in a silo and interacting only with humans in that they are interconnected with messages to other services.

More importantly, defines implications of transaction in SOA:

> To participate in an ACID transaction requires a willingness **to hold database locks** until the transaction
> coordinator decides to commit or abort the transaction. For the non-coordinator, this is a serious ceding of
> independence and requires a lot of trust that the coordinating system will make a decision in a timely
> fashion. **Being constrained to hold active locks on records in the database can be devastating for the availability of a system.**

Hence we can only consider atomic transactions when there is a high level of trust between components. 
For instance, *brokers* in Apache Kafka trust internally in Zookeeper service to assign a leader replica 
for each partition to a broker. 

//TODO describe operators operands and reference data.

--------


* Link: [cidrdb.org/cidr2005/papers/P12.pdf](http://cidrdb.org/cidr2005/papers/P12.pdf)
* Author: **Pat Helland**
* Year: 2005
