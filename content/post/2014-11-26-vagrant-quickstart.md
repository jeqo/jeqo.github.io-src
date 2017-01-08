---
Title: Vagrant and Chef Quickstart
date: 2014-11-26
Section: post
Tags: 
- vagrant
- virtualbox
Categories: 
- Devops
---

I have some months working with Vagrant and I think it's owesome! Integration with almost all kind of virtualization platforms: VirtalBox, VMware, Docker, AWS EC2, Hyper-V and so on. Also it's able to use differente Provisioners: Chef, Puppet, bash, Docker, Ansible. I really like it.

<!--more-->

So, when I start working with Vagrant I choose VirtualBox as my virtualization platform and Chef as my provisioner, and when trying different configurations I start finding some tips to share:

1. First step: Should I create my base box? or should I use a base box already created?
2. Can I increase my disk space? how?
3. Can I increase my swap memory? how?

So, I decide to create a post to start creating Vagrant boxes and resolve this issues. Let's start:

> First of all, install [Vagrant](https://www.vagrantup.com/downloads.html)

## Create a Vagrant Box

If you read Vagrant documentation, you will find everything is based in a **box**. What's a box? In my opinion, a box is an abstraction from a base virtual environment: It has an OS installed, some basic configuration, and packaged to be reused. And what's a **base box**? A base box is a template to create boxes. For instance: A VirtualBox *base box* is a VirtualBox VM with an OS installed, a disk space defined, and a basic configuration, and a *box* is a Virtual Machine up and running. An Amazon Web Service EC2 *box* is an instance and a *base box* is a [file containing an AMI id](https://github.com/mitchellh/vagrant-aws/tree/master/example_box), that is a Virtual Machine template from AWS.

Now that I know what is a box, how can I created? You can created by yourself: creating a simple VM, installing a base OS, and running a Vagrant command to create a "base box". The process to do this depends on what virtualization platform you are using, for example: on VirtualBox you can do [this](https://docs.vagrantup.com/v2/virtualbox/boxes.html) (official documentation) or a [more detailed way](http://www.skoblenick.com/vagrant/creating-a-custom-box-from-scratch/).

This process is easy, but what if you want to use a cloud base box to be sure that anyone will change a package or configuration? There are two sites that I found where you can search, use directly or download base boxes:

* [Vagrantbox.es](http://www.vagrantbox.es/)
* [Vagrant Cloud](https://vagrantcloud.com/) the Vagrant's official site

Now you can search an specific distribution and use it whenever you want.

Ok, I have a base box, how can I use it to create a new box? The basic artifact you need is a Vagrant file:

{{< highlight shell >}}
mkdir vagrant-box
vagrant init
{{< /highlight >}}

Running this creates a *Vagrantfile* that contains the information to create a new box.

{{< highlight ruby >}}
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "base"
end
{{< /highlight >}}

This *ruby* script starts a *method* where you have a variable *config* from *Vagrant.configure("2")*. This variable is what you use to start defining your *box* properties.

> First important command: **vagrant init**

This is not enough to create a box. You need two more attributes:

{{< highlight ruby >}}
...
  # URL or path to base box file
  # config.vm.box_url = "https://storage.us2.oraclecloud.com/v1/istoilis-istoilis/vagrant/oel65-64.box"
  config.vm.box_url = "file://c:/boxes/oel65-64.box"
...
{{< /highlight >}}

With this you can execute *vagrant up* to run the script. This will create a VM on VirtualBox with the same configuration as *base box*.

> Second important command: **vagrant up [--provider=virtualbox]**

You can validate a new VM is created from VirtualBox. Depending on your base box you will have certain ammount of RAM memory, disk space and cpu's.

Great! so if you only want to clone your VM, this is enough.



## Customize a Vagrant Box

What if I want to change my VM name? What if I want more memory? What if I want to create two instances?

All these customizations are possible from *Vagrantfile*.

Let's start changing VM resources:

As this is a virtualization platform specific requirement, you have to make these changes on an embedded method:

{{< highlight ruby >}}
...
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--name"  , "basemachine"]
    vb.customize ["modifyvm", :id, "--cpus"  , 2]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
  end
...
{{< /highlight >}}

In VirtualBox, these are the most important parameters: RAM memory (in MB), VM name, CPUs number, and chipset.

Ok, let's try it... wait, I already have a Vagrant box started

> Third important command: **vagrant destroy**

For me, this is the greatest benefit of using Vagrant, you can destroy you box and you don't care! Well, 
you care if it's a box in production, but when you are creating your environment you can destroy and 
recreate over and over again, fast and easy.

Run: *vagrant destroy*, and *vagrant up* again.

Now you know how to create and parametrize your Vagrant Box on VirtualBox.

Two more important parameters:

* **Network**: By default your box use a NAT network that VirtualBox creates out-of-the-box. But, what if you (obviously) want to connect to your box? You need to use the "Host-only" network:


{{< highlight ruby >}}
...
  config.vm.network :private_network, ip: "192.168.56.XYZ"
...
{{< /highlight >}}

> Normally this is the network IP: 192.168.56.1, so your VMs use this IP as gateway.

* **Shared Directories**: Using VirtualBox utility to create shared directories is annoying! With Vagrant is as easy as add thit to your script:

{{< highlight ruby >}}
...
  # Mount c:\data directory to /data directory on box. mount_options is optional
  config.vm.synced_folder "/data" , "/data", :mount_options => ["dmode=777", "fmode=777"]
...
{{< /highlight >}}

Some other parameters:

{{< highlight ruby >}}
...
  # Hostname
  config.vm.hostname = "basemachine"
...
{{< /highlight >}}

For more information: [Vagrant Docs](https://docs.vagrantup.com/v2/vagrantfile/index.html)



## Resolving some common issues

Excellent! you can create and parametrized Vagrant boxes. If your base box have enough disk and swap size, perfect! 
But, what if your base box have 10GB as disk space and your swap space is 512MB or less?

Well these issues took me a couple of days to resolve, so this is how to handle it:


### Increase Disk space

Normally (sadly), cloud base box comes with VMDK disks formats. If you are lucky and your disk format is VDI, 
you can solve this directly [like this](http://derekmolloy.ie/resize-a-virtualbox-disk/). But, VMDK can't be expanded, 
so you need to add another disk to your VM. If making this manually is hard, can you imaging doing this from Vagrant? 
Well, now that I solved is not that difficult:

1. Create an script called *"bootstrap.sh"* on your working directory, and add these lines:

{{< highlight shell >}}
pvcreate /dev/sdb
vgextend VolGroup /dev/sdb
lvextend /dev/VolGroup/lv_root /dev/sdb
resize2fs /dev/VolGroup/lv_root
{{< /highlight >}}

> VolGroup and lv_root can change on different distributions. But it works for me on Ubuntu also.

And then add this code to your *Vagrantfile*:

{{< highlight ruby >}}
...
  config.vm.provider :virtualbox do |vb|
  ...
  # Validate this should be run it once
  if ARGV[0] == "up" && ! File.exist?("./disk1.vdi")
    vb.customize [
      'createhd',
      '--filename', "./disk1.vdi",
      '--format', 'VDI',
      # 100GB
      '--size', 100 * 1024
    ]

    vb.customize [
      'storageattach', :id,
      '--storagectl', 'SATA Controller',
      '--port', 1, '--device', 0,
      '--type', 'hdd', '--medium',
      file_to_disk
    ]
  end

  if ARGV[0] == "up" && ! File.exist?("./disk1.vdi")
    # Run script to map new disk
    config.vm.provision "shell", path: "bootstrap.sh"
    # Run script to increase swap memory
    config.vm.provision "shell", path: "increase_swap.sh"
  end
...
{{< /highlight >}}

This creates a VDI disk file with 100GB of capacity. And is attached to your OS.

> This problem is solved when you create cloud Vagrant boxes, like AWS EC2 instances with Vagrant :D


### Increase Swap Memory

As I install Oracle Fusion Middleware products, they require some amount of swap memory, but *base box* comes with a small amount of swap.

To resolve this, add this script called *"increase_swap.sh"* on your working directory:

{{< highlight shell >}}
#!/bin/sh

# size of swapfile in megabytes
swapsize=8000

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
  echo 'swapfile not found. Adding swapfile.'
  fallocate -l ${swapsize}M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
  echo 'swapfile found. No changes made.'
fi

# output results to terminal
df -h
cat /proc/swaps
cat /proc/meminfo | grep Swap
{{< /highlight >}}

If you destroy and up your box now, you will have a new box with 8GB of swap memory added and 100GB of additional disk space.



## Additional tricks


### Get Started with Chef (Provisioning!)

What if you want to install some package or service? You can do this with a bash (as we increase memory and disk) but is not flexible and can take a lot of effort. At this days provisioning is a trend and products as Docker, Puppet and Chef are getting very popular, so I will use Chef to show you how to install Apache and start HTTP service:

> To learn more about chef: [Learn Chef](http://learn.getchef.com)


Create the following directories and create a file:

chef/cookbooks/http/recipes/install-httpd.rb

Chef base artifacts are Cookbooks that group common Recipes. For example you can create a Cookbook called "java" and add recipes to install different versions.

Add this code to the file:

{{< highlight ruby >}}
package "httpd" do
  action :install
end

service "httpd" do
  action [ :start, :enable ]
end
{{< /highlight >}}


This recipe *install* "httpd" package and ensure service "httpd" is *started* and will be started when the machine is restarted.

To call this simple recipe from Vagrant you need to add this to your file:


{{< highlight ruby >}}
...
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = "../chef/cookbooks"
    chef.add_recipe "http::install-httpd"
  end
...
{{< /highlight >}}

> *chef-solo* is when you use your client independently, and *chef-client* is when you use a Chef Server

Now if you destroy and re-create your Vagrant box again you could test that your HTTP server is up and running

[http://ip or hostname](http://ip or host)


### Properties file

The last trick I want to share is how to create a properties file for your Vagrant configuration.

What if you want to repeat this process to create another box? You can parametrized your Vagrantfile with a properties file.

To do this:

* Create a file like this one called "vagrant.rb":

{{< highlight yaml >}}
box:
  name: "base-machine"
  disk_path: "./disk1.vdi"
  url: "file://c:/boxes/oel65-64.box"
  ip: "192.168.56.20"
  shared_directory: "/data"
  disk_size: 40
  ram_memory: 2048
  cpus: 2
  swap_memory: 4096
chef:
  repo_location: "C:/dev/jeqo/chef-repo"
{{< /highlight >}}


* Add the "yaml" library:

{{< highlight ruby >}}
  require "yaml"
{{< /highlight >}}


* Then read and use properties:

{{< highlight ruby >}}
...
  props = YAML.load_file("vagrant.rb")

  config.vm.box = "#{props['box']['name']}"
...
{{< /highlight >}}

Well, it's a long but (i hope) an easy post. I hope you enjoyed :)

Here is the [Git repository](https://github.com/jeqo/vagrant-quickstart)

Feel free to send your comments and question!


> Disclosure: I'm not a Ruby developer (yet), so if I'm using a wrong term about ruby code sorry :)  I just trying to describe the source code, that I think is enough for Vagrant files.

#### Resources

* Vagrant Docs: [https://docs.vagrantup.com/v2/](https://docs.vagrantup.com/v2/)

* Increase Swap: [http://programmaticponderings.wordpress.com/2013/12/19/scripting-linux-swap-space/](http://programmaticponderings.wordpress.com/2013/12/19/scripting-linux-swap-space/)

* Add a new disk to VirtualBox VM with Vagrant: [https://gist.github.com/leifg/4713995](https://gist.github.com/leifg/4713995)

* Getting started with Chef: [https://learn.getchef.com](https://learn.getchef.com)

* VirtualBox API documentation: [https://www.virtualbox.org/manual/ch08.html](https://www.virtualbox.org/manual/ch08.html)
