---
title: Data on the Outside vs Data on the Inside
date: 2018-01-06
section: notes
tags:
- distributed systems
- papers
- reviews
- microservices
categories:
- reviews
draft: true
---

Encuentro este *paper* tan relevante y preciso hoy como lo fue en 2005, cuando fue publicado.
Es fascinante como luego de 12 años y con nuevas tecnologías en voga, los mismos conceptos 
siguen aplicando. 

Sobre todo encuentro esencial evaluar los conceptos propuestos por **Pat Helland**
en relación a *Microservicios*: En este *paper* se describen los retos que afrontan los 
desarrolladores cuando salen de un entorno *monolítico*, donde se puede confiar en 
que todos los componentes están ubicados en un mismo entorno (i.e. un mismo servidor), 
y se tienen que enfrentar a una realidad donde ya no se puede confiar en que todos los 
componentes estan en mismo espacio/tiempo, y métodos como transacciones atómicas 
implementado con *two-phase commit* no son recomendables ya que atenta directamente contra
uno de los objetivos de distribuir componentes, que es aumentar la disponibilidad. 

Pat inicia su sustentación introduciendo las características de una *Arquitectura Orientada a Servicios* 
(SOA), actualmente relevante a Arquitecturas de Microservicios:

> "Cada *servicio* esta compuesto de una cantidad de código y datos que son privados para ese servicio.
> Estos *servicios* son diferentes a las aplicaciones clasicas, que viven en un silo y interactuan
> solo con humanos, en que se interconectan a través de mensajes con otros servicios."

Más importante, define las implicancias de Transacciones en SOA:

> "Para participar en una transacción [ACID](https://en.wikipedia.org/wiki/ACID) require que 
> los participantes esten dispuestos a mantener **bloquear** registros en la base de datos
> hasta que el coordinador de transacciones decida *confirmar* o *abortar* la transacción. 
> Para los componentes independientes, este es ceder seriamente sus niveles de independencia
> y require mucha **confianza** de que el sistema coordinador va a realizar esa decisión 
> a tiempo. 
> **Estar restringido a mantener bloqueos activos sobre registros en la base de datos puede ser devastador para la disponibiilidad del sistema**"

Por lo tanto, solo se deberían considerar transacciones atómicas solo entre componentes 
que tienen un alto nivel de confianza, por ejemplo: *brokers* de Kafka confian internamente 
en el servicio de Zookeeper para asignar la réplica líder de una partición.

//TODO describing Operators, Operands and Reference Data

## *Data: Then and Now*

Este capítulo va más a detalle sobre el impacto en espacio/tiempo de aplicar transacciones en SOA.

Cuando uno se encuentra dentro de los límites de un *servicio* las transacciones 
son serializables y nos dan la ilusión de que estamos en un "ahora".

> "La Serializabilidad transaccional te hacen sentir solo"
 
Podemos asumir que las operaciones que estamos ejecutando: una precede a otra, una sigue a otra,
o son completamente independientes.

Cuando salimos de los límites de un *servicio* las cosas cambian completamente:

> "Los contenidos de un mensaje (e.g. *request* o *response*) son siempre del  pasado! Nunca son de 'ahora'."
>
> "No existe simultaneidad a la distancia!
>
> - Similar a la velocidad de la luz que limita la informacion
> - Al momento que uno ve un objeto a la distancia, puede haber cambiado!
> - Al momento que uno ve un mensaje, sus datos pueden haber cambiado!" 

> "Servicios, transacciones, y bloqueos estan limitados por la simultaneidad
>
> - Dentro de una transacción, las cosas son simultaneas
> - La simultaneidad solo existe dentro de una transaccion!
> - La simultaneidad solo existe dentro de un servicio!"

> "**Cada servicio tiene su propia perspectiva**"

Y luego remata con la siguiente comparación:

> **"Moverse hacia SOA es como ir de la física de Newton a la física de Einstein**
>
> Con Newton el tiempo marcha hacia adelante, uniformemente, con conocimiento instantaneo a la distancia.
>
> Antes de SOA, la computación distruida se esforzaba en hacer que varios sistemas aparenten ser uno con RPC, 2PC, etc.
>
> En el universo de Einstein, todo es relativo a la perspectiva de cada uno.
>
> SOA tiene un "ahora" dentro de cada servicio y el "pasado" arrivando a través de mensajes"

Esta cita me parece clave considerar cuando se esta evaluando migrar de una arquitectura monolítica a
una distribuida, como Microservicios: Los beneficios tienen que ser mayores a la complejidad que implica 
trabajar en base a leyes distintas, como aprender las teorías de Einstein luego de estar acostumbrado a las leyes de Newton.

Como Adrian Colyer describe en [su revisión del *paper*](https://blog.acolyer.org/2016/09/13/data-on-the-outside-versus-data-on-the-inside/):

> Quizás debamos renombrar la operacion de refactorización “extraer microservicios” a “cambiar el modelo de espacio y timepo” ;).

La responsabilidad de lidiar el *presente* dentro de un servicio y el *pasado* (o *futuro* dependiendo del punto de vista) 
que llega a través de mensajes es de la logica de aplicación del mismo servicio (i.e. es responsabilidad del desarrollador) 

> "El mundo ya no es más plano!
>
> - SOA reconoce que hay más de una computadora trabajando juntas!
> - Varias máquinas significa varios dominios de tiempo.
> - Varios dominios de tiempo significa que nosotros debemos lidiar con la ambigüedad para permitir la coexistencia, cooperación, 
> y trabajo conjunto.

## *Data on the Outside: Immutability*

Cuando estamos fuera de un *servicio* 

## *Data on the Outside: Reference Data* 

## *Data on the Inside*

## *Representations of Data*

--------

The relevance of this paper today is as it was in 2005.
It is fascinating how technologies have changed these 12 years
and if we just change terms like XML to JSON, SOA to Micro-Services
or Relational Database to NoSQL Data Stores, the concepts will be
still accurate.

Pat Helland explains the dichotomy (as Ben Stopford called in his [post](https://www.confluent.io/blog/data-dichotomy-rethinking-the-way-we-treat-data-and-services/))
between data behind a Service boundary and data on the outside when
you follow a service-oriented architecture.

He highlight key challenges that will be need to be embraced if
the decision to follow this path is taken, like:

> "[In SOA] atomic transactions with two-phase commit **do not occur** accross multiple services."

and

> "Data owned by a service is, in general, **never allowed out of it** unless it is
> processed by application logic"

But this is just the beginning. Here is one quote I found amazing:

> **"Going to SOA is like going from Newton's physics to Einstein's physics**
>
> Newton's time marched forward uniformly with instant knowledge at a distance.
>
> Before SOA, distributed computing strove to make many systems look like one with RPC, 2PC, etc.
>
> In Einstein's universe, everything is relative to one's perspective.
>
> SOA has "now" inside and the "past" arriving in messages"

Everyone that is thinking to break a monolith system into a bunch of services
shall read this and ensure that the benefits worth taking these challenges.

As Adrian Colyer call it in its review here: https://blog.acolyer.org/2016/09/13/data-on-the-outside-versus-data-on-the-inside/

> Perhaps we should rename the “extract microservice” refactoring operation to “change model of time and space” ;).

The service developer that is aware of this challenge will have present that
the application logic will have to reconcile the "now" inside a service and
the "then" arriving as messages.

> **The world is no longer flat!!** SOA is recognizing that there is more than
> one computer working together.

From this first part we can conclude 2 main issues that have to be embrace in a SOA:

* ACID transaction won't be part of your toolbox
* Reconcile "now" and "then" is part of the application logic

Then this paper describes Data on the Ouside and Data on the Inside characteristics.
On one side, data on the outside:

> Data on the outside must be immutable and/or versioned data

Time-stamping, versioning, and not reusing important identifier, Helland says, are
excellent techniques to keep you messages immutable.

Two concepts are stablished when talking about data:

* Operators: action information that is part of a message. (e.g. Order amount, items)
* Operands: reference data, that gives context to the Operators. (e.g. Dapartment information linked to an Order)

And about Reference Data, Helland says:

> Each piece of reference data has both a *version independent identifier* and
> multiple versions, each of which is labeled iwth a *version dependent identifier*.
> For each piece, there is exactly one publishing service.

This concept of Reference Data is one key concept that in my experience creates
the most difficult scenarios in a SOA. Sharing data is a key feature and implement it
correctly is usually difficult: how much data should be shared? how do we control the access
to sensitive data on the consumer sides? Which approach should be taken to implement this
funcionality, request/response, messaging, log-oriented?

Nowadays I would say that Apache Kafka is a good fit to express and propagate`Reference Data`.

On the other side, to work with Data on the Inside we should take some considerations:

* Transactionality is ensured inside a service.
* Incoming Data is usually kept stored as a binary copy for auditing and non-repudiation.

XML and SQL are discussed as a way to represent data. Where XML extensibility and SQL
relational capabilities are key depending on the context (i.e. inside or outside data).
XML is unbounded vs Relational bounded representations.

![outside vs inside](/images/2017-10-13-data-on-the-outside-vs-data-on-the-inside/outside-vs-inside.png)

And finally compare the benefits and weakness of the 3 ways to represent data: XML, SQL and Objects:

![xml vs sql vs objects](/images/2017-10-13-data-on-the-outside-vs-data-on-the-inside/sql-xml-object.png)

Concluding:

> We simply need all three of these representations and we need to use them in a fashion that plays to their respective strenghts!

## Referencia

* Link: [cidrdb.org/cidr2005/papers/P12.pdf](cidrdb.org/cidr2005/papers/P12.pdf)
* Author: Pat Helland
* Year: 2005
