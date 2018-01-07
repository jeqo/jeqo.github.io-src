---
title: Book Review - Applied SOA Patterns on the Oracle Platform
date: 2014-11-28
section: posts
tags:
- oracle
- soa
- book
- review
categories: 
- integration
---

I've had the opportunity to present a review of this book [Applied SOA Patterns on the Oracle Platform](https://www.packtpub.com/application-development/applied-soa-patterns-oracle-platform).

<!--more-->

Once I started to read the chapters, I found it quite interesting because of these:

* Great introduction to SOA  principles, and Oracle SOA Suite evolution
* Align AIA Concepts with SOA patterns
* A key topic for SOA success: Service Repository
* An extensive and complete description of Security and Error Handling

It looks like a really long book (572 pages), and it is. But this is justified because it takes a great approach from concepts to examples combined with experiences and source code. This could help you to feel more confident about your SOA design decisions.

## "Must Read" parts


* **Chapter 1 - SOA Frameworks**: I think these frameworks are quite important to apply on SOA design, for example: *Object and XML Modeling*, if they are not designed well, could generate an implementation hell: huge and heavy data types, rare and indescribable names. Also gives an introduction to AIA that can give you a easy-to-learn guide about SOA layers, components, and common terms (Application Business Connector Services, Enterprise Business Flows and Services, and so on).

* **Chapter 2 - Oracle SOA Roadmap**: Owesome timeline about SOA Suite and related technologies. First time I found this information really well summarized. In general, this chapter makes a great technical specification about Oracle SOA Foundation: artifacts, technologies, code examples, specifications.

* **Chapter 3 - Oracle Enterprise Business Flow SOA Patterns**: Great distinction between BPEL and Mediator use cases, and I share the idea that telecommunications is a great industry to take examples about service orchestration.

* **Chapter 4**: This chapter contains really well explained tutorial: Implementing a basic Proxy on OSB is one of them, a Oracle E-Business Suite case turning a Message Broker into a Service Broker applying "Receive-Transform-Deliver" implementation pattern, and great examples about "VETRO" (or "VETO") pattern on OSB: *Validate, Enrich, Transform and Operate*.

* **Chapter 5**: A great "Getting-started" with SOA Governance using Oracle Enterprise Repository. *"Open standards for the SOA Taxonomy", "Entity Types"*, and *"Creating a lightweight taxonomy for dynamic service invocations"* are definitely *must read* parts: they include Service Discovery taxonomy, Entity relationships and how they impact in your architecture.

* **Chapter 6**: There is a note, on "Optimizing the Adapter Framework", about SOAP and REST that you could find very interested, and I'm agree with it: "SOAP versus REST is a pointless discussion". This is followed by a technical description of how to use different technologies like REST, JSON, EJB, DB Adapter, PL-SQL and Oracle XDK. *"After all, it doesn't matter if it is modern or not, all that matters is if it works according to our principles or not. The color of the cat does not matter, as long as it catches the mice."*

* **Chapter 7**:  *"Initial Analysis"* including common SOA vulnerabilities and risks, and *"Risk mitigation design rules"*, are all recommendations well explained and quite important in SOA projects.

* **Chapter 8** - Error-handling design rules is also a "must-read": 15 rules related with OSB, BPEL, Enterprise Manager,  to follow and apply a right exception handling on your project. Follower by a technical approach first with JMX and SOA Composites.

* **Chapter 9**: This chapter includes an nice summary about Event Processing followed by a practitioner approach to implement CEP with Oracle Event Processing. Also includes 3 more important topics: High Availability with Coherence (How to integrated with OSB and CEP),  Monitoring Business Services with Oracle BAM ( How to use it from BPEL, JMS and Web Service API), and finally SOA as a Cloud Foundation (that's where 12"c" comes from).

In conclusion you will find in this book a bunch of real experience aligned with SOA patterns and a mix of principles, frameworks, technical issues and product mapping. I believe you will find it very useful. You can find it [here](http://bit.ly/1uqK9dq)!

For me, this book will be my new handbook for comming SOA projects (with [IT Strategies from Oracle](http://www.oracle.com/technetwork/topics/entarch/itso-165161.html)).

If you have comments about this book, please share! :)
