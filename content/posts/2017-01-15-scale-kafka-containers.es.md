---
title: Escalando Kafka con Docker Containers
date: 2017-01-15
section: posts
tags:
- kafka
- docker
categories:
- devops
- integration
---

En este post mostraré como utilizar contenedores Docker para crear y escalar
un clúster de Kafka, y también como crear, escalar y mover `topics` dentro del
clúster.

<!--more-->

***
Repositorio: https://github.com/jeqo/post-scale-kafka-containers
***

# Clúster de un nodo

Primero, comenzaremos con la forma más sencilla de utilizar Docker, que puede
ser útil y suficiente para algunos escenarios de desarrollo: un **clúster con
un nodo**

La arquitectura de *Apache Kafka* esta basada en 2 components principales:
El propio *servidor de Apache Kakfa*, y el *servidor de Apache Zookeeper*,
utilizado por Kafka para su coordinación interna.

Es por eso que un clúster de nodo simple require por lo menos de un par de
procesos.

Si hablamos en terminos y prácticas de `contenedores`, estos processos deberían
ejecutarse en dos contenedores diferentes.

La forma más sencilla de definir estos procesos en Docker, es con
servicios de `Docker Compose`, como están definidos en el archivo
`kafka-cluster/docker-compose.yml`

***
Usaré un par de imagenes. Son bastante simples, y el código fuente se encuentra
aquí:
[Apache Kafka](https://github.com/jeqo/docker-image-apache-kafka),
[Apache Zookeeper](https://github.com/jeqo/docker-image-apache-zookeeper), and
[Confluent Platform](https://github.com/jeqo/docker-image-confluent-platform)
***

{{< highlight yaml >}}
version: "2.1"
services:
  kafka:
    image: jeqo/apache-kafka:0.10.1.0-2.11
    links:
      - zookeeper
  zookeeper:
    image: jeqo/apache-zookeeper:3.4.8
{{< /highlight >}}

Esta configuración define 2 servicios: `kafka` y `zookeeper`. El `link` del  
servicio `kafka` y su variable de entorno `ZOOKEEPER_CONNECT`
configuran el acceso desde `kafka` hacia el servicio `zookeeper`.

Si probamos iniciar los servicios con el comando `docker-compose up -d`,
Docker Compose creará una red donde estos servicios se podrán comunicar.

{{< highlight bash >}}
jeqo@jeqo-Oryx-Pro:.../single-node-kafka-cluster$ docker-compose up -d
Creating network "kafkacluster_default" with the default driver
Creating kafkacluster_zookeeper_1
Creating kafkacluster_kafka_1
{{< /highlight >}}

Si queremos acceder a estos servicios desde nuestra aplicación (también
  definida en Docker Compose) lo podemos hacer de la siguiente manera:

{{< highlight yaml >}}
version: "2.1"
services:
  kafka:
    image: jeqo/apache-kafka-client:0.10.1.0-2.11
    command: sleep infinity
    networks:
      - default
      - kafkacluster_default #(2)
networks: #(1)
  kafkacluster_default:
    external: true
{{< /highlight >}}

Aquí definimos primero una red externa `external network` llamada `singlenodekafkacluster_default`
que nos permite acceder a la red del clúster de kafka.
Luego agregamos esta red a los servicios que requieren acceso, en este caso
el servicio `client`.

Para probar el acceso desde el cliente, primero iniciemos el servicio con
`docker-compose up -d` y luego nos conectamos al servicio:

{{< highlight bash >}}
$ docker-compose exec kafka bash
# bin/kafka-console-producer.sh --broker-list kafka:9092 --topic topic1
test
# bin/kafka-topics.sh --zookeeper zookeeper:2181 --list      
topic1
{{< /highlight >}}

# Clúster Multi-Nodo

Una vez creado nuestro clúster, escalar nuestro contenedor de ´kafka´
es tan sencillo como utilizar el comando `scale`:

{{< highlight bash >}}
docker-compose scale kafka=3
{{< /highlight >}}

Este comando creará dos contenedores adicionales:

{{< highlight bash >}}
$ docker-compose scale kafka=3
Creating and starting kafkacluster_kafka_2 ... done
Creating and starting kafkacluster_kafka_3 ... done
{{< /highlight >}}

Para nosotros, como desarrolladores(as) de aplicaciones, solo necesitamos
saber uno de los host o IPs de los `broker` (nodo del clúster de Kafka),
para conectarnos al clúster. O también podemos usar el nombre del servicio.

Como la documentación especifíca, el cliente (p.ejem: `productor` o `consumidor`)
solo utilizará este dato para iniciar la conexión y obtener la lista completa de
`brokers` del clúster. Esto significa que la escalabilidad de Kafka es
transparente para nuestra aplicación.

Para validar que todos los brokers son parte del clúster, usaremos el client
de Zookeeper.

Desde el contenedor cliente:

{{< highlight bash >}}
$ docker-compose exec kafka bash
# bin/zookeeper-shell.sh zookeeper:2181
ls /brokers/ids
[1003, 1002, 1001]
{{< /highlight >}}

# Escalando Topics

En Kafka, los `Topics` son distribuidos en `Partitions`. Las `Particiones`
permiten la **escalabilidad**, haciendo posible que los `Topics` quepan en
varios nodos; y **paralelismo**, dejando que distintas instancias de un mismo
**Grupo de Consumidores** puedan consumir messages en paralelo.

Aparte de este beneficio, Kafka tiene la habilidad de **replicar** estas
`Particiones`, logrando alta disponibilidad. En este case, si tienes varias `replicas`
de una `partición`, una será la partición `líder` y las demás replicas serán
`seguidoras`.

## Agregando nuevos `Topics` al clúster

Una vez que el clúster tiene mayor número de nodos, Kafka no utilizará estos
nuevos nodos hasta que nuevos tópicos sean creados.

Veamos como probamos esto:

1. Iniciemos un clúster simple, con un solo nodo

<script type="text/javascript" src="https://asciinema.org/a/9xzqgicktaqhzp1fofjk9ejgm.js" id="asciicast-9xzqgicktaqhzp1fofjk9ejgm" async></script>

2. Luego iniciemos un cliente, y creemos un topic `topic1`

<script type="text/javascript" src="https://asciinema.org/a/2schnuetb24mjx6txopew51hc.js" id="asciicast-2schnuetb24mjx6txopew51hc" async></script>

3. Escalemos el clúster a 3 nodos

<script type="text/javascript" src="https://asciinema.org/a/ahibdzz7xt67q53sc5ert6qdp.js" id="asciicast-ahibdzz7xt67q53sc5ert6qdp" async></script>

4. Agregemos topics para ocupar los demás brokers

Usando múltiples particiones:

<script type="text/javascript" src="https://asciinema.org/a/enq2czkpgdf0tbf3u6fwir3ml.js" id="asciicast-enq2czkpgdf0tbf3u6fwir3ml" async></script>

O usando varias réplicas:

<script type="text/javascript" src="https://asciinema.org/a/f0u67h5ufiz4zkup84a1t8t5g.js" id="asciicast-f0u67h5ufiz4zkup84a1t8t5g" async></script>

Para decidir que `factor de replicación` utilizar o cuantas  `particiones`,
depende de cada caso de uso. Estos temas merecen su propio post.

## Expandiendo `Topics` en el clúster

Expandir topics en el clúster significa mover `topics` y `particiones`
una vez que se tengan más `brokers` en el `clúster`.

Esto se puede realizar en 3 pasos:

1. Identificar que `topics` se quieren mover a un nuevo `broker`.

2. Generar el plan de reasignación. Esto se puede realizar de forma automática
o manual, si se sabe cómo redistribuir los topics.

3. Ejecutar el plan de reasignación.

Estos pasos se encuentran documentados aquí: http://kafka.apache.org/documentation/#basic_ops_cluster_expansion

He automatizado un poco los pasos con unos script en Ansible:

Dentro del archivo `playbooks/prepare-reassignment.yml` hay dos variables a definir:

{{< highlight yaml >}}
vars:
  topics:
    - topic1
  broker_list: 1003
{{< /highlight >}}

Estas prepararán un plan para mover el topic `topic1` al `broker` con id `1003`.

<script type="text/javascript" src="https://asciinema.org/a/c6332x8t7yumpj65ie4qudgem.js" id="asciicast-c6332x8t7yumpj65ie4qudgem" async></script>

Puedes copiar ese JSON generado en `playbooks/reassign-topic-plan.json`

{{< highlight json >}}
{
  "version":1,
  "partitions":[{"topic":"topic1","partition":0,"replicas":[1003]}]
}
{{< /highlight >}}

Y ejecutar el otro playbook: `playbooks/execute-reassignment.yml`

<script type="text/javascript" src="https://asciinema.org/a/99308.js" id="asciicast-99308" async></script>

# Confluent Platform images

Todos estos pasos se pueden ejecutar igualmente con
[Confluent Platform](https://www.confluent.io/).

Para ello, agregué los directorios `confluent-cluster` y `confluent-client` para
poder probarlo:

<script type="text/javascript" src="https://asciinema.org/a/a446bixdfn3l8xqoiolmsmlqg.js" id="asciicast-a446bixdfn3l8xqoiolmsmlqg" async></script>

Espero que este post los ayude a entender un poco más sobre los `topics` en
Kafka y como los `contenedores` nos pueden ayudar a crear clústers en segundos :)

Y, ya saben, ejecuten ...

<blockquote class="twitter-tweet" data-lang="es"><p lang="en" dir="ltr">.<a href="https://twitter.com/apachekafka">@apachekafka</a> everywhere :) <a href="https://t.co/AcEmkRBCpv">pic.twitter.com/AcEmkRBCpv</a></p>&mdash; Gwen (Chen) Shapira (@gwenshap) <a href="https://twitter.com/gwenshap/status/777660752626851840">19 de septiembre de 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
