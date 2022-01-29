---
title: reload4j as drop-in replacement for log4j 1.x
date: 2022-01-25
section: til
tags:
- java
- logging
categories:
- ops
---

TIL there is a drop-in replacement for log4j 1.x: [Reload4j](https://reload4j.qos.ch/).

<!--more-->
It continues fixing security issues, and doesn't require changing application logic. 
Dropping JAR to the classpath, removing previous log4j-1.* JARs should be enough to get the latest patches.
