---
title: Crear una instancia NFS en AWS usando Vagrant y Chef
date: 2014-11-30
section: posts
tags:
- nfs
- aws
- vagrant
- chef
categories: 
- devops
---

Estuve probando la creación de instancias en AWS EC2 para instalar productos de Oracle
Fusion Middleware, y encontré una restricción: Cómo descargar los instaladores si
quiero reutilizarlos en varias instancias? Cómo evitar un consumo alto
de ancho de banda? Y cómo hacer este procedimiento repetitivo?

Entre varias soluciones, en este momento decidi aplicar : [How to setup an Amazon AWS EC2 NFS Share](https://theredblacktree.wordpress.com/2013/05/23/how-to-setup-a-amazon-aws-ec2-nfs-share/).
Pero para hacerla reutilizable cree una configuración en Vagrant y Chef para provisionar
una instancia en AWS con NFS configurado: [Git repository](https://github.com/jeqo/vagrant-aws-chef-nfs)

## Qué pasos seguí? ##

1. Instalar Vagrant (vagrant-aws y vagrant-omnibus) y Chef SDK
2. Crear una cuenta para crear un [Chef Server](https://manage.opscode.com/) y cargar los "cookbooks"
3. Tener una [AWS account](http://aws.amazon.com/) para crear instancias de forma remota.
4. Crear una configuración en Vagrant para tener una instancia con NFS
5. Probar.

Este video muestra como utilizar la configuración del repositorio en GitHub:

<iframe width="560" height="315" src="//www.youtube.com/embed/gqhY82kdHh4" frameborder="0" allowfullscreen></iframe>
