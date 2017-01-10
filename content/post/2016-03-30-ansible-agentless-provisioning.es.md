---
title: Ansible - Provisionamiento sin agentes
date: 2016-03-30
section: post
tags:
- ansible
- docker
categories: 
- devops
---

Ansible es una herramienta de automatización reconocida por ser sencilla
y potente a la vez. Según mi experiencia, puedo decir que esto se debe
principalmente al lenguaje que utiliza: YAML, y a tener una arquitectura
sin agentes o "agentless".

## YAML y los componentes de Ansible

> "YAML is a human friendly data serialization standard for all programming
  languages" (Source: http://yaml.org/)

Esto signifíca que es verdaderamente fácil de entender y comenzar a trabajar
con YAML. Por ejemplo:

```yaml
- hosts: webserver
  tasks:
    - package: apache
        state: latest
```

Este **"playbook"** dice que el host *webserver* que tiene 1 tarea: instalar
el paquete más actual de Apache, usando el **"module"** *package*.

Bastante sencillo no?

Para revisar que tan potente puede ser Ansible, se puede revisar el índice
de Modules:
http://docs.ansible.com/ansible/modules_by_category.html

Para lograr reusabilidad: estas tareas pueden ser agrupadas como **"roles"**,
que son una compilación de tareas que buscan cumplir un objetivo común.
Por ejemplo: un rol Java para instalar JDK en tu nodo.

Estos son los componentes principales de Ansible: Playbooks, Modules, and Roles.

## Arquitectura "Agentless"

Esto significa que no necesitas un "ansible-client" en tus nodos para ejecutar
tareas. Tu solo necesitarías un "master" que diga que tareas ejecutar en tus
nodos. Esto es muy importante comparado con otras herramientas, donde necesitas
un "\***-client" para poder interpretar y ejecutar los comandos:
https://www.ansible.com/benefits-of-agentless-architecture

Es verdad que no necesitas un cliente con Ansible, pero requires de algunos
paquetes. Pero estos paquetes son SSH y otros relacionados a Python, que son
bastante comunes:
http://docs.ansible.com/ansible/intro_installation.html#managed-node-requirements

Ansible también mantiene un enfoque "push", donde el "master" envía comandos a
los nodos. Esto también diferente a otras herramientas que están basadas en un
enfoque "push", donde los nodos piden los comandos a un "master". Aunque este
enfoque es opcional con Ansible:
http://docs.ansible.com/ansible/playbooks_intro.html#ansible-pull

Por último, hay una funcionalidad que quiero mencionar: Tipo de Conexión.
Por defecto, Ansible se basa en SSH para ejecutar comandos en los nodos, pero
hay casos en los que SSH no es una opción o no se necesita: por ejemplo para
ejecutar comandos localmente, o en Windows, o en Docker.

En estos casos, la opción de tipo de conexión permite que tus "playbook" se
ejecuten usando WinRM si tu nodo es Windows, o ejecutarlos localmente, o
utilizar comandos Docker Exec.

Vamos a ver un poco de código:

He implementedo un role de Ansible para instalar Java hace algún tiempo:
https://github.com/jeqo/ansible-role-java

Solo para explicar que hace, vemos el archivo de tareas principal:

```yaml
---
  - debug:
      msg: "This Java Provider will be installed: {{ java_provider }}"

  - include: install-{{ java_provider }}.yml

  - include: set-java-home.yml
```

Primero muestra un mensaje con el tipo de proveedor:
variable "java_provider" y luego definir la variable de entorno: JAVA_HOME.

Este rol también tiene una carpeta de pruebas "tests", con un "playbook" con
algunas pruebas:

```yaml
- name: test install openjdk jdk 8 on centos 7
  hosts: test01
  roles:
    - role: java
      java_provider: openjdk
      java_version: 8
      java_type: jdk
- name: test install openjdk jre 8 on centos 7
  hosts: test02
  roles:
    - role: java
      java_provider: openjdk
      java_version: 8
      java_type: jre
# more tests...
```

Y para ejecutar las pruebas utilizo Vagrant y VirtualBox:

```ruby
Vagrant.configure(2) do |config|

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "test.yml"
    ansible.galaxy_role_file = "roles.yml"
  end

  config.vm.define "test01" do |node|
    node.vm.box = "jeqo/ansible-centos7"
  end

  config.vm.define "test02" do |node|
    node.vm.box = "jeqo/ansible-centos7"
  end

  # more test nodes...
end
```

Ejecutemos la prueba de instalación de OpenJDK 8 en Centos:

```
vagrant up test01
...

PLAY [test install openjdk jdk 8 on centos 7] **********************************

TASK [setup] *******************************************************************
ok: [test01]

TASK [java : debug] ************************************************************
ok: [test01] => {
    "msg": "This Java Provider will be installed: openjdk"
}

TASK [java : include] **********************************************************
included: /home/jeqo/dev/jeqo/ansible-role-java/tests/roles/java/tasks/install-openjdk.yml for test01

TASK [java : set_fact] *********************************************************
skipping: [test01]

TASK [java : set_fact] *********************************************************
ok: [test01]

TASK [java : set_fact] *********************************************************
skipping: [test01]

TASK [java : set_fact] *********************************************************
ok: [test01]

TASK [java : install openjdk (debian)] *****************************************
skipping: [test01]

TASK [java : install openjdk (redhat)] *****************************************

```

Pero que pasa si quiero ejecutar este rol en Docker? Necesito configurar
SSH para hacerlo utilizando el modo de conexión por defecto. Esto es
considerado un anti-patrón:
https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/

Pero, desde la versión 2.0 de Ansible que tiene el tipo de conexión Docker
incluido en la instalación. Así que hice algunas pruebas:
https://github.com/jeqo/poc-ansible-docker

En este repositorio tengo un "playbook" que crea el contenedor:

```yaml
- hosts: 127.0.0.1
  connection: local
  tasks:
    - name: my container
      docker:
        name: poccontainer
        image: centos
        command: sleep infinity
        state: started
```

Aquí utilizo el tipo de tipo de conexión local para ejecutar comandos
localmente.

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
a5e49bd032be        centos              "sleep infinity"    About an hour ago   Up About an hour                        poccontainer
```

Una vez que tenga el contenedor en ejecución, se puede ejecutar
el provisionamiento:

```yaml
- hosts: poccontainer
  connection: docker
  pre_tasks:
    - package: name=sudo
    - command: "sed -i -e \"s/Defaults    requiretty.*/ #Defaults    requiretty/g\" /etc/sudoers"
  roles:
    - role: java
      java_provider: openjdk
      java_type: jdk
      java_version: 8
```

Las "pre-tasks" se necesitan para configurar el paquete "sudo" y poder
configurar "tty" en el contenedos. Esto se requiere cuando ejecutar un
"playbook" con el parámetro: "become", que ejecuta un comando como "sudo".
Luego se ejecuta el rol como en cualquier nodo:

{{< highlight shell >}}
$ ansible-playbook provisioning.yml -vvvv
Using /home/jeqo/dev/jeqo/poc-ansible-docker/ansible.cfg as config file
Loaded callback default of type stdout, v2.0
2 plays in provisioning.yml

PLAY ***************************************************************************

TASK [setup] *******************************************************************
ESTABLISH DOCKER CONNECTION FOR USER: None
<poccontainer> EXEC ['/usr/bin/docker', 'exec', '-i', u'poccontainer', '/bin/sh', '-c', '/bin/sh -c \'( umask 22 && 
mkdir -p "` echo $HOME/.ansible/tmp/ansible-tmp-1459355431.02-32251179247729 `" && 
echo "` echo $HOME/.ansible/tmp/ansible-tmp-1459355431.02-32251179247729 `" )\'']
<poccontainer> PUT /tmp/tmpNCOaxi TO /root/.ansible/tmp/ansible-tmp-1459355431.02-32251179247729/setup
<poccontainer> EXEC ['/usr/bin/docker', 'exec', '-i', u'poccontainer', '/bin/sh', '-c', u'/bin/sh -c \'LANG=en_US.UTF-8 
LC_ALL=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8 /usr/bin/python /root/.ansible/tmp/ansible-tmp-1459355431.02-32251179247729/setup; 
rm -rf "/root/.ansible/tmp/ansible-tmp-1459355431.02-32251179247729/" > /dev/null 2>&1\'']
ok: [poccontainer]
{{< /highlight >}}

## Conclusiones

- Estos ejemplos muestran cual versátil es Ansible, usando roles y tipos de
conexión. Pero hay más plataformas donde Ansible puede ser utilizada, como AWS:
https://aws.amazon.com/blogs/apn/getting-started-with-ansible-and-dynamic-amazon-ec2-inventory-management/
y otras plataformas en la nube:
http://docs.ansible.com/ansible/list_of_cloud_modules.html

- Una posible pregunta puede ser: ¿Puede Ansible reemplazar los Dockerfile?
Puede ser, depende de ti. Los Dockerfile son bastante sencillos y solo
funcionan en Docker. Los Dockerfile también tiene una característica interesante
que crea una imagen en cada paso de ejecución, lo que hace que la distribución
de imágenes sea más sencilla. Esto falta aún en Ansible, donde los comandos
se ejecutan sobre un contenedor en ejecución. En Ansible también está faltando
las opciones de "commit" y "push" en Docker, pero esto se puede reemplazar
facilmente así:

```yaml
- hosts: 127.0.0.1
  connection: local
  tasks:
    - name: commit
      command: docker commit poccontainer
```

Sin embargo, Ansible también tiene un módulo para ejecutar Dockerfiles:
http://docs.ansible.com/ansible/docker_image_module.html

Espero que esto les ayude a utilizar Ansible y Docker.
