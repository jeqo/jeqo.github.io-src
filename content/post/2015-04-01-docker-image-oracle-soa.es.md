---
Title: Oracle SOA Suite 12c sobre Docker
date: 2015-04-01
Section: post
Tags: 
- oracle
- soa
- docker
Categories: 
- devops
---

Buenas noticias llegaron desde Oracle hace un par de semanas: [Oracle WebLogic Server es ahora soportado en  Docker!](https://blogs.oracle.com/WebLogicServer/entry/oracle_weblogic_server_now_running).

<blockquote class="twitter-tweet" lang="es"><p>I&#39;m glad we announced support for <a href="https://twitter.com/OracleWebLogic">@OracleWebLogic</a> on <a href="https://twitter.com/docker">@Docker</a> last week, not today :-) <a href="https://t.co/6E9UxrgY3n">https://t.co/6E9UxrgY3n</a></p>&mdash; Bruno Borges  (@brunoborges) <a href="https://twitter.com/brunoborges/status/583252433343758336">abril 1, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

Esto es muy emocionante. **Docker** es una nueva tecnología que propone una nueva forma de virtualización
a través de contenedores (OS, Configurations, Platform, Application) Para [más información acerca de Docker](https://www.docker.com/whatisdocker/)

Bueno, WebLogic sobre Docker es genial, pero me he propuesto ir unos pasos más adelante y *Dockerize* los
productos de **SOA** y **BPM**  (como [Guido Schmitz hizo con  Oracle Stream Explorer](https://guidoschmutz.wordpress.com/2015/03/29/installing-oracle-stream-explorer-in-a-docker-image/))

<blockquote class="twitter-tweet" lang="es"><p>Just published my latest blog “Providing Oracle Stream Explorer environment using Docker”. <a href="https://twitter.com/hashtag/oracle?src=hash">#oracle</a> <a href="https://twitter.com/hashtag/StreamExplorer?src=hash">#StreamExplorer</a> <a href="http://t.co/WNFGCmFVca">http://t.co/WNFGCmFVca</a></p>&mdash; gschmutz (@gschmutz) <a href="https://twitter.com/gschmutz/status/582232826772357120">marzo 29, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

He utilizado el [repositorio de Oracle](http://github.com/oracle/docker) como base para crear una
imagen con Oracle SOA Suite 12c instalado, y una configuración para utilizar esa imagen en la
creación de otro contenedor con un dominio listo para ejecutar.

## Obtener el repositorio ##

Para probar esta entrada del blog, debe tener instalado [Docker en su máquina](https://docs.docker.com/).

El repositorio se encuentra ubicado en: [http://github.com/jeqo/oracle-docker](http://github.com/jeqo/oracle-docker)

Mi contribución está en la carpeta ['OracleSOA'](https://github.com/jeqo/oracle-docker/tree/master/OracleSOA).

## Creación de la imagen con Oracle SOA Suite 12c ##

Primero se deben [descargar los instaladores de Oracle SOA Suite 12c Quick Start](http://www.oracle.com/technetwork/middleware/soasuite/downloads/index.html),
y colocarlos en la carpeta OracleSOA/dockerfiles/12.1.3. De la misma forma
 [descargar Java Development Kit 7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html),
 y colocarlo en el mismo folder.

Abrir un terminal en el directorio *OracleSOA*, ir a dockerfiles, y ejecutar el script *buildDockerImage.sh* con el argumento *-d* que indica que es la versión de desarrollo:

```bash
sh buildDockerImage.sh -d
```

Esta ejecución crear una imagen llamada: **oracle/soa:12.1.3-dev**

## Dockerize un dominio con SOA Suite ##

Ahora que tenemos una imagen Docker con SOA instalado, podemos reutilizarla para
crear dominios con WLST.

Existe un ejemplo de este procedimiento en *OracleSOA/samples*.

Para ejecutarlo, ir a *OracleSOA/samples/12c-domain* y correr el siguiente comando:

```bash
docker build -t mysoa .
```

Esto debe crear un imagen *mysoa* que contiene un Compact Domain instalado en: */u01/oracle/work/domains/soa-domain*

Eso es todo! Para crear un contenedor desde la imagen, ejecutar:

```bash
docker run -i -t mysoa
```

### Siguientes pasos ###

* BPM sobre Docker
* Publicar imagenes en Docker Hub Registry
* Dominios Extendidos sobre Docker: Usar una base de datos Oracle Database para instalar Oracle SOA/BPM Schemas
* SOA/BPM Cluster sobre Docker containers
