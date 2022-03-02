---
title: Releasing OS-specific GraalVM native image binaries easier with JReleaser
date: 2022-03-01
section: til

tags:
- java
- graalvm

categories:
- dev
---

Packaging and releasing Java applications (e.g. CLI) tend to be cumbersome, and the user-experience tended not to be the best as users have to download a valid version of JRE, etc.

<!--more-->

[JReleaser](https://jreleaser.org/guide/latest/index.html) is an awesome tool that takes most of the heavy-lifting — including, but not limited, to packaging, distribution, notifications, etc. — and let you focus on your application details.

Today, I found a great example of how to use JReleaser and mixing it with [GraalVM](https://www.graalvm.org/) to package native-image applications and releasing them on GitHub: https://github.com/kcctl/kcctl — which I haven't used in anger just yet.


Some considerations when using Maven — but probably usable generally:

- Choose a way to package and distribute your application. JReleaser supports from executable JAR releases to `jlink`, GraalVM `native-image`, etc.: https://jreleaser.org/guide/latest/distributions/index.html
- For GraalVM `native-image` use a framework that plays well with it (Micronaut, Quarkus), or use the Maven plugin yourself: https://graalvm.github.io/native-build-tools/latest/index.html
- Once your application is packaged, use `assembler` plugin to get the binary zipped:
  - Assembler configuration: https://github.com/kcctl/kcctl/blob/main/src/main/assembly/assembly.xml
  - Maven plugin configuration: https://github.com/kcctl/kcctl/blob/00453ef43ac3feb94afd13a2eb82547a22e06d30/pom.xml#L353-L373
  - Maven profile for distribution: https://github.com/kcctl/kcctl/blob/00453ef43ac3feb94afd13a2eb82547a22e06d30/pom.xml#L412-L433
- GitHub Actions plays very well with JReleaser and building GraalVM binaries for different OS distributions:
  - OS matrix: https://github.com/kcctl/kcctl/blob/00453ef43ac3feb94afd13a2eb82547a22e06d30/.github/workflows/release.yml#L78-L85
  
I managed to take this inputs and apply it for a simple CLI to list Kafka topics with additional metadata: 

- Maven project: https://github.com/jeqo/poc-apache-kafka/tree/main/cli/topic-list
- GitHub Actions to release: https://github.com/jeqo/poc-apache-kafka/blob/main/.github/workflows/cli-ktopiclist-release.yml
- First release: https://github.com/jeqo/poc-apache-kafka/releases/tag/cli-topic-list-v0.1.0

Hope to share more details about building GraalVM images in another post.

At the moment `JReleaser` seems to be focused on applications (e.g. CLI, executable JARs, etc.).
If you are looking to publish a Java library, probably is enough using `mvn deploy` command.
