---
title: Imagen de Oracle SOA Suite 12c en Docker
date: 2015-09-04
section: post
tags:
- oracle
- soa
- docker
- packer
categories: 
- devops
---

Luego de encontrar algunas limitaciones en la construcción de una imagen en
Docker con Oracle SOA Suite 12c instalado usando Dockerfiles (como acceso
a volumenes, tamaño de filesystem por defecto), he investigado como
mejorar este proceso, y he encontrado [Packer](https://packer.io/)
(del mismo equipo que creo Vagrant, Hashicorp).

Para obtener mayor información sobre porqué utilizar Packer en vez de
Dockerfiles, [ir aquí](http://mmckeen.net/blog/2013/12/27/advanced-docker-provisioning-with-packer/).

También he movido el directory [OracleSOA](https://github.com/jeqo/oracle-docker/tree/master/OracleSOA)
que cree sobre el repositorio de Oracle Docker [oracle-docker](https://github.com/oracle/docker)
hacia un repositorio independiente: [github.com/jeqo/oracle-soa-12c-docker](https://github.com/jeqo/oracle-soa-12c-docker).

## Mejoras ##

Basicamente, los scripts de Dockerfile fueron transformados en shell scripts
y son invocados desde Packer en la etapa de provisionamiento

```json
  "provisioners": [
    {
      "type": "shell",
      "scripts": [
        "scripts/create-user.sh"
      ]
    },
    {
      "type": "file",
      "source": "./files/",
      "destination": "/u01/"
    },
    {
      "type": "shell",
      "scripts": [
        "scripts/install-java.sh"
      ],
      "environment_vars": [
        "JAVA_RPM=/data/{{user `java_rpm`}}"
      ]
    },
    {
      "type": "shell",
      "scripts": [
        "scripts/install-soa.sh"
      ],
      "environment_vars": [
        "SOA_ZIP=/data/{{user `soa_zip`}}",
        "SOA_PKG={{user `soa_pkg`}}",
        "SOA_PKG2={{user `soa_pkg2`}}",
        "JAVA_HOME=/usr/java/default",
        "MW_HOME=/u01/oracle/soa"
      ]
    }
  ]
```

Luego del provisionamiento exitoso, se procesa la imagen para
guardarla en Docker Hub:

```json
  "post-processors": [
    [
      {
        "type": "docker-tag",
        "repository": "jeqo/oracle-soa-12c",
        "tag": "12.1.3-dev"
      },
      "docker-push"
    ]
  ]
```

Realmente la configuración en JSON es bastante simple y concreta.

Una vez que la imagen esta cargada en Docker Hub, se puede utilizar
la herramienta preferida: Docker, Dockerfiles, o Vagrant, para crear un
dominio sobre la imagen creada. [Ejemplo](https://github.com/jeqo/oracle-soa-12c-docker/tree/master/samples/12c-domain)
explicado en mi [post anterior](http://jeqo.github.io/blog/devops/docker-image-oracle-soa-es/).
