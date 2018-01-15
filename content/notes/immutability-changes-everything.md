---
title: Immutability Changes Evrything
date: 2018-01-16
---

Immutability is one of those concepts that could appear simple 
and even dumb at first ("yeah, a thing that never changes")
but it is incredible useful and fundamental for distributed systems: 

> We **need immutability** to coordinate at a distance 

This is pretty much related with Pat's previous paper: 
[Data on the Outside vs Data on the Inside](../data-on-the-outside-vs-data-on-the-inside/)

> [...] and we **can afford immutability**, as storage gets cheaper.

<!--more-->

In this paper the author gives a list of patterns and technologies 
that leverage immutability:

{{< zoom-img src="/images/notes/immutability-changes-everything/immutability-stack.png" >}}

## Accountants Don't Use Eraser

*"Append-Only" Computing" part does not have much to add:

> Observations are recorded forever (or for a long time). Derived result are calculated on demand (or periodically precalculated)

*(Related with patterns like `Event Sourcing` and `CQRS`)*

> **Transaction logs records all the changes made to the database.**
> High-speed appends are the only way to change the log.
> From this perspective, the contents of the database hold at a caching of the latest record values
> in the logs. **The truth is the log**. **The database is a cache of a subset of log.**
> That cached subset happens to be the latest value of each record and index value 
> from the log. 

*(Related with log-based data stores like Apache Kafka)*

A current example to this concept is Blockchain technology, that keeps a ledger of 
transactions between untrusted parties. 

*I wish to have this concept better explained and practices when I was in University instead of relying only on CRUD as a way 
to model and modify data.*

### Append-Only Distributed Single Master

Here is described how a Single Master approach for a distributed data store can be used to 
serialize values and then propagate to followers, similar to what you have in Apache Kafka
with a `leader partition replica`. 

## Data on the Outsive vs. Data on the Inside

## Referencing Immutable Data

## Immutability Is in the Eye of the Beholder

## Hey! Versions Are Immutable, Too!

## Keeping the Stone Tablets Safe

## Hardware Changes towards Unchanging

## References

* Link: [cidrdb.org/cidr2015/Papers/CIDR15_Paper16.pdf](http://cidrdb.org/cidr2015/Papers/CIDR15_Paper16.pdf)
* Author: **Pat Helland**
* Year: 2015