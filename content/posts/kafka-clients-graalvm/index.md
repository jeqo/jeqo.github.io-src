---
title: Kafka client applications with GraalVM
date: 2022-03-08
section: posts
draft: true

tags:
- kafka
- cli
- graalvm

categories:
- development
---

Shipping Kafka applications/CLIs with Java hasn't been the most user-friendly experience.
Java is required on the client-side, starting Java applications (e.g. executable JAR) tend to be slower than to binary applications.
GraalVM, and specifically [native-image](TODO add link) tooling, are aimed to solve most of these issues with Java, and enable building native binaries from Java applications.

Even though this has been supported for a while now, reflection and other practices required additional features and configuration that make this unsupported or very cumbersome to implement.

With the arrival of new frameworks that were targeting the benefits of GraalVM, like [Micronaut](TODO add link) and [Quarkus](TODO add link), it started to be possible and simpler to implement applications that included Kafka clients, and could be packaged as native binaries.

This post is going to explore how to be able to package _vanilla_ Kafka client applications —i.e. no framework— as native binaries.

<!--more-->


