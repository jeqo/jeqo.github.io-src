---
title: Create a NFS instance on AWS using Vagrant and Chef
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

I was creating AWS EC2 instances to install Oracle Fusion Middleware products, and I found an issue: How to download Oracle's installers if I want to use installers on several instances? This could consume a lot of network bandwith and I want to make this process repeatable, so I don't want to wait 1 hour each installation only downloading files.

<!--more-->

So, I found this solution: [How to setup an Amazon AWS EC2 NFS Share](https://theredblacktree.wordpress.com/2013/05/23/how-to-setup-a-amazon-aws-ec2-nfs-share/). But to make it more reusable, I create a Vagrant & Chef configuration to replicate and share this method here: [Git repository](https://github.com/jeqo/vagrant-aws-chef-nfs)

## What are the steps?

1. You need to install Vagrant (vagrant-aws and vagrant-omnibus) and Chef SDK
2. You have to create [Chef Server](https://manage.opscode.com/) account and upload the cookbooks
3. You need to create [AWS account](http://aws.amazon.com/) to create instances remotly.
4. You have to create a Vagrant configuration and customize it to create an AWS EC2 instance
5. Test it.

Well, I've created a configuration on GitHub and I'll show you how to use it:

<iframe width="560" height="315" src="//www.youtube.com/embed/gqhY82kdHh4" frameborder="0" allowfullscreen></iframe>

I hope you find it useful. Feel free to share your comments!
