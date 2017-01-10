---
title: Chef Cookbook para Oracle Fusion Middleware 12c
date: 2014-12-09
section: post
tags:
- oracle
- fmw
- bpm
- chef
categories: 
- devops
---

Las herramientas de provisionamiento de software han cambiado la forma de
crear ambientes: Cuánto tiempo que se toma para instalar Sistema Operativo,
base de datos, configurar la plataforma, desplegar aplicaciones? Pueden
ser días, hasta semanas. Ahora que se pueden transladar estos pasos en código,
este proceso se ve transformado en horas, hasta minutos.

En esta entrada voy a mostrar como provisionar un Dominio WebLogic con Oracle
SOA Suite 12c, utilizando un *Chef cookbook* que he compartido en [Chef Supermarket](http://supermarket.chef.io).

## Provisionamiento con Chef ##

Chef es una herramienta para configurar software, basada en Ruby. Para mayor información
sobre como iniciar con Chef, [ir aquí](http://learn.chef.io/)

### Chef Cookbooks y Recipes ###

 **Chef Cookbooks** son grupos de **Recipes** (o recetas), y una **Recipe** es una
 secuencia de instrucciones llamadas **Resources** (o recursos).
 *Directory, Execute, Service, Package* son algunos recursos disponibles.

Por ejemplo: Si uno quiere instalar un servidor HTTP Server, primero se debe instalar el recurso *Package*, y luego iniciar el recurso *Service*.

## Oracle Fusion Middleware Cookbook ##

He compartido este "Chef cookbook": [oracle-fmw](https://supermarket.chef.io/cookbooks/oracle-fmw).
La idea es tener un grupo de recetas para configurar ambientes con diferentes productos
de Oracle Fusion Middleware como: SOA, BPM, BAM, OSB, etc.

En este primer release se incluyen las siguientes recetas:

- **prepare-infrastructure-12c**: Crear los usuarios y grupos de Sistema Operativo, instala paquetes base
para la ejecución de futuros scripts de FMW.
- **install-bpm_qs-12c**: Instala Oracle BPM 12c, que incluye los siguientes productos en la versión 12.1.3: JDeveloper, Oracle SOA, Oracle OSB, Oracle BAM, Oracle BAM and others.
- **create-rcu_repository-12c**: Crea repositorios en base de datos con RCU.
- **create-domain-12c**: Crea un Dominio WebLogic con estos productos: SOA, BAM, BPM, OSB.

En una siguiente entrada mostraré como utilizar este "cookbook". Mientras tanto puede descargar, usar y compartir mejoras en [Chef Supermarket](https://supermarket.chef.io/cookbooks/oracle-fmw) y [GitHub](https://github.com/jeqo/oracle-fmw).
