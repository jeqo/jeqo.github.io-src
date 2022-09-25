---
title: "Kafka Emulator CLI: Record and Reply Records considering time-distance"
date: 2022-08-24
section: posts

tags:
- kafka
- cli
- tools
categories:
- poc
---

Looking for alternative ways to reproduce time-based conditions in Kafka Streams applications
—e.g. if you're doing some sort of join or windowing based on time—
I ended up creating a [CLI tool](https://github.com/jeqo/kafka-cli/tree/main/emulator) to support a couple of features:

- Record events from topics, including their timestamps and gap
- Replay events, including waiting periods between them

SQLite is used a storage for recorded events, so events can be generated, updated, tweaked using SQL.

For more information: <https://github.com/jeqo/kafka-cli/tree/main/emulator>

