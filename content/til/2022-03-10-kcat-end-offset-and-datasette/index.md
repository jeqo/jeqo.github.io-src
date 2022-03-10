---
title: Explore Kafka data with kcat, sqlite, and Datasette
date: 2022-03-10
section: til

tags:
- datasette
- sqlite
- kcat
- kafka

categories:
- dev
- data
---

I have been playing with Datasette and sqlite for a bit, trying to collect and expose data efficiently for others to analyze.
Recently started finding use-cases to get data from Apache Kafka, and expose it quickly to analyze it.
Why not using Datasette?

<!--more-->

[Today I learned](https://stackoverflow.com/questions/60882882/how-to-consume-messages-between-two-timestamps-using-kafka-console-consumer) that `kcat` is able to consume a set of messages based on timestamp. This means, we can ask "get me all the data produced til now":

```shell
kafkacat -b ${CCLOUD_BOOTSTRAP_SERVER} \
  -C -t confluent-audit-log-events \
  -o e@$(date +%s000)
...
% Reached stop timestamp for topic confluent-audit-log-events [0] at offset 80957
% Reached stop timestamp for topic confluent-audit-log-events [1] at offset 80407
% Reached stop timestamp for topic confluent-audit-log-events [2] at offset 80810: exiting
```

[Datasette](TODO add link) has an awesome tool to turn JSON into sqlite table: https://sqlite-utils.datasette.io/en/stable/cli.html#inserting-newline-delimited-json.
Then JSON outputs from `kcat` can be piped into `sqlite-utils` to produce a `sqlite` database, and complete when end timestamp is reached:

```shell
kafkacat -b ${CCLOUD_BOOTSTRAP_SERVER} \
  -C -t confluent-audit-log-events \
  -o e@$(date +%s000) | \
  sqlite-utils insert auditlog-v1.db audit-log - --nl
% Reached stop timestamp for topic confluent-audit-log-events [0] at offset 80957
% Reached stop timestamp for topic confluent-audit-log-events [1] at offset 80407
% Reached stop timestamp for topic confluent-audit-log-events [2] at offset 80810: exiting
```

Once data is available on your sqlite database file, use datasette to explore the data with SQL:

```shell
datasette auditlog-v1.db
```

[`sqlite-utils`](https://sqlite-utils.datasette.io) has a bunch of commands to optimize and tweak the data structure to simplify querying.

And remember sqlite already supports JSON expressions to query nested fields: https://www.sqlite.org/json1.html#jptr
