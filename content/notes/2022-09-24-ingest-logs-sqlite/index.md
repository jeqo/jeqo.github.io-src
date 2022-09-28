---
title: Ingesting log files to sqlite
date: 2022-09-24

tags:
- sqlite
- datasette
- ops
- troubleshooting

categories:
- til
---

I recently was looking into how to analyze multiple related log files (e.g. application log from multiple instances), and found that sqlite may be enough :)

<!-- more -->

The first step is ingesting content from log files into sqlite tables.
[sqlite-utils](https://sqlite-utils.datasette.io/en/stable/) to the rescue!
I was initially happy with having each line as a row 
and adding [full-text support to the log column](https://sqlite-utils.datasette.io/en/stable/cli.html#configuring-full-text-search) to query events.
However, a Java log may span across multiple lines and the outputs may not be ideal — timestamps could be in 1 line, and the stack trace root cause in another one.

[I found](https://github.com/simonw/sqlite-utils/issues/490) (thanks @simonw!) that `sqlite-utils` supports adding "convert" functions when inserting data from a file into sqlite, allowing to apply custom parsing to either lines or the whole text file: <https://sqlite-utils.datasette.io/en/stable/cli.html#applying-conversions-while-inserting-data>

The next challenge was: how to parse log files content with regular expressions?
After some try and error, I got into the problem of how to apply certain expression only _if_ the next line starts with some character, but without "consuming" the next character/line.
I got to learn about regex _negative (and positive) lookahead (or behind!)_ expressions that do just that!

From [regex101.com](https://regex101.com):
> `(?!...)`: Starting at the current position in the expression, ensures that the given pattern will not match. Does not consume characters.

So, in ended up with the following expression:

```
(?m)^\[(?P<datetime>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\] (?P<level>\w+) (?P<log>(.+$(\n(?!\[).+|)+))
```
Explanation: <https://regex101.com/r/2AxwfE/1>

And the final script to ingest log files into sqlite database looks like this:

```bash
sqlite-utils insert /tmp/kafka-logs.db logs server.log.2022-09-24-21 --text --convert "
import re
r = re.compile(r'^\[(?P<datetime>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\] (?P<level>\w+) (?P<log>(.+(\n(?\!\[).+|)+))', re.MULTILINE)
def convert(text):
    rows = [m.groupdict() for m in r.finditer(text)]
    for row in rows:
        row.update({'server': 'localhost'})
        row.update({'component': 'broker'})
    return rows
"
```

The `row.update` allows to label rows as I'm planning to ingest logs from different hosts and potentially different components.

