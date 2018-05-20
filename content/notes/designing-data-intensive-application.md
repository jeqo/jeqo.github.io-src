---
title: Designing Data-Intensive Applications
date: 2018-05-20
section: notes
tags:
- distributed systems
categories:
- notes
---

<!--more-->

# Chapter 1: Reliable, Scalable, and Maintainable Applications

Data Intensive: "bigger problems are the **amount** of data, the **complexity** of data, and the **speed** at 
which it is changing."

**Data Systems** umbrella: databases, caches, search indexes, batch processing, stream processing.

> You are now not only an application developer, but also a data system designer.

Main concerns: **Reliablity**, **Scalability**, and **Mantainability**.

## Reliability

> A _fault_ is usually defined as one component of the system deviating from its spec, whereas _failure_ is 
when the system as a whole stops providing the required service to the user ... it is usually best to design
fault-tolerance mechanisms that prevent faults from causing failures.a

### Hardware Faults

> Hard disks are reported as having Mean Time To Failure (**MTTF**) of about 10 to 50 years.
> Thus, on a storage cluster with 10,000 disks, _we should expect on average one disk to die per day_.

### Software Faults

### Human Faults


