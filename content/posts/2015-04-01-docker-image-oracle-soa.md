---
title: Docker image for Oracle SOA Suite 12c
date: 2015-04-01
section: posts
tags:
- oracle
- soa
- docker
categories: 
- devops
---

Cool news came from Oracle a couple of weeks ago: [Oracle WebLogic Server is now supported on Docker!](https://blogs.oracle.com/WebLogicServer/entry/oracle_weblogic_server_now_running).

<!--more-->

<blockquote class="twitter-tweet" lang="es"><p>I&#39;m glad we announced support for <a href="https://twitter.com/OracleWebLogic">@OracleWebLogic</a> on <a href="https://twitter.com/docker">@Docker</a> last week, not today :-) <a href="https://t.co/6E9UxrgY3n">https://t.co/6E9UxrgY3n</a></p>&mdash; Bruno Borges  (@brunoborges) <a href="https://twitter.com/brunoborges/status/583252433343758336">abril 1, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This is very cool. **Docker** is a disruptive platform that ship everything inside a container (OS, Configurations, Platform, Application) and let you run it (almost) everywhere! To [learn more about Docker](https://www.docker.com/whatisdocker/)

So, WebLogic on Docker is great, but I'd like to go further and *Dockerize* **SOA** and **BPM** products (as [Guido Schmitz made with Oracle Stream Explorer](https://guidoschmutz.wordpress.com/2015/03/29/installing-oracle-stream-explorer-in-a-docker-image/))

<blockquote class="twitter-tweet" lang="es"><p>Just published my latest blog “Providing Oracle Stream Explorer environment using Docker”. <a href="https://twitter.com/hashtag/oracle?src=hash">#oracle</a> <a href="https://twitter.com/hashtag/StreamExplorer?src=hash">#StreamExplorer</a> <a href="http://t.co/WNFGCmFVca">http://t.co/WNFGCmFVca</a></p>&mdash; gschmutz (@gschmutz) <a href="https://twitter.com/gschmutz/status/582232826772357120">marzo 29, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

I used [Oracle's Docker repository](http://github.com/oracle/docker) as a base to create a Oracle SOA Suite 12c image (with the product installed - no domain included), and a sample Docker configuration to create a Docker image with a domain with SOA and OSB.

## Get the repository

To try this post you should have [a machine with Docker installed](https://docs.docker.com/).

To get started you can download the repository: [http://github.com/jeqo/oracle-docker](http://github.com/jeqo/oracle-docker)

The repository includes images for MySQL, WebLogic and Coherence. These images comes from Oracle repository.

My contribution is into the ['OracleSOA' directory](https://github.com/jeqo/oracle-docker/tree/master/OracleSOA).

Feel free to fork and create "pull-requests"!

## Creating the SOA Suite 12c image

Now you should [download Oracle SOA Suite 12c Quick Start installer](http://www.oracle.com/technetwork/middleware/soasuite/downloads/index.html), and put it into OracleSOA/dockerfiles/12.1.3. Also, you should [download Java Development Kit 7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html), and put it in the same folder.

Open a terminal into *OracleSOA* directory, go to dockerfiles, run the script *buildDockerImage.sh* with the *-d* argument because we are installing the Quick Start version of SOA Suite 12c:

{{< highlight shell >}}
sh buildDockerImage.sh -d
{{< /highlight >}}

This creates a Docker image called: **oracle/soa:12.1.3-dev**

## Dockerize a SOA Suite Domain

So, now we have a Docker image with Oracle SOA Suite 12c installed. What we can do now is create a domain with WLST.

That's what I did, and I add it to the *OracleSOA/samples* directory.

To run it, go to the *OracleSOA/samples/12c-domain* and run the following commands:

{{< highlight shell >}}
docker build -t mysoa .
{{< /highlight >}}

And this should create an image called *mysoa* that contains a Compact Domain into this directory: */u01/oracle/work/domains/soa-domain*


That's it! When you want to run a SOA Suite 12c Domain, just run:

{{< highlight shell >}}
docker run -i -t mysoa
{{< /highlight >}}

### Next steps

* BPM on Docker
* Publish images on Docker Hub Registry
* Extended Domain on Docker: Use an external Oracle Database for Oracle SOA/BPM Schemas
* SOA/BPM Cluster on Docker containers
