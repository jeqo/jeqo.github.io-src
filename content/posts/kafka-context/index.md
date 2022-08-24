---
title: "Kafka Context: Connection and Authentication properties as Named Contexts"
date: 2022-07-28
section: posts
draft: true

tags:
- kafka
- security

categories:
- dev
- poc
---

Once you have to work with more than one Kafka cluster (e.g. multiple environments or clusters per domain),
and/or multiple credentials (e.g. API keys, user principal per component),
there is a routine task to set/update the right client connection properties
to point to the right bootstrap-servers,
use the right authentication credetials and encryption,
and do it in all the places you're supposed to.

Hopefully there's some automation helping to define these properties
— e.g. Confluent for Kubernetes or cp-ansible do this on the Confluent Platform deployment —
though on the client side this can become tedious and error-prone to set this connection properties.

This post proposes a new abstraction to deal with connection to Kafka clusters.

<!--more-->

Connection to Kafka clusters require basically 2 property groups:

- Bootstrap server list
- Security properties (default: `PLAINTEXT`)
  - Encryption: TLS, keystores
  - Authentication: Username/password, certificates.

All other properties are related to performance (batching, buffers), metadata (client ID, group ID), or feature-specific (topology optimizations, state directory).

Groping connection properties is a common practice in other platforms 
(e.g. [Kubernetes contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)) 
and cloud providers (e.g. [AWS credentials](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html)).
This enables accessing multiple clusters/services in a simple way, by providing a context name to a client to know what credentials to use to connect to a specific cluster.

[Kafka Context](https://github.com/jeqo/kafka-libs/tree/main/kafka-context)
is a library that includes an abstraction to manage connection and credentials to multiple Kafka —and Schema Registry— clusters.


