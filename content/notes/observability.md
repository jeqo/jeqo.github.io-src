---
title: Observability
date: 2018-01-04
section: notes
tags:
- observability
- tracing
- metrics
categories: 
- devops
- operations
draft: false
---

<!--more-->

## References

### Projects

#### OpenCensus

* Specifications https://github.com/census-instrumentation/opencensus-specs

> Context API, Tags API, Stats API, Trace API -> Exporters

#### OpenZipkin

* B3 Propagation https://github.com/openzipkin/b3-propagation

> Trace Context consists on: Trace Id, Parent Span Id, Span Id and Flags, that includes Parent Sampling Decition and Debugging option.


### Papers

* Benjamin Sigelman et al. 
["Dapper, a Large-Scale Distributed Systems Tracing Infrastructure"](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/36356.pdf)

* Jonathan Kaldor, Jonathan Mace, et at. 
["Canopy: An End-to-End Performance Tracing And Analysis System"](http://cs.brown.edu/~jcmace/papers/kaldor2017canopy.pdf)

* Raja R. Sambasivan et al. 
["So, you want to trace your distributed system? Key design insights from years of practical experience"](http://www.pdl.cmu.edu/PDL-FTP/SelfStar/CMU-PDL-14-102.pdf)

### Blog Posts

#### Observability

* Peter Bourgon ["Metrics, Tracing and Logging"](https://peter.bourgon.org/blog/2017/02/21/metrics-tracing-and-logging.html) 

* Cindy Sridharan ["Monitoring in the Time of Cloud Native"](https://medium.com/@copyconstruct/monitoring-in-the-time-of-cloud-native-c87c7a5bfa3e)

* Cindy Sridharan ["Tracing and Observability"](https://medium.com/@copyconstruct/monitoring-and-observability-8417d1952e1c)

#### Tracing 

* Uber ["Take OpenTracing for a HotROD"](https://medium.com/opentracing/take-opentracing-for-a-hotrod-ride-f6e3141f7941)

* Uber ["Distributed Tracing"](https://eng.uber.com/distributed-tracing/)

* JaegerTracing ["Jaeger and Multitenancy"](https://medium.com/jaegertracing/jaeger-and-multitenancy-99dfa1d49dc0)

#### Logging

* Peter Bourgon ["Logging v. Instrumentation"](https://peter.bourgon.org/blog/2016/02/07/logging-v-instrumentation.html )

* Peter Bourgon ["OK Log"](https://peter.bourgon.org/ok-log/)

* 12 Factor App ["Logs"](https://12factor.net/logs)

#### Metrics


* https://codeascraft.com/2011/02/15/measure-anything-measure-everything/

* Cindy Sridharan ["Logs and Metrics"](https://medium.com/@copyconstruct/logs-and-metrics-6d34d3026e38)

