---
Title: Chef Cookbook for Oracle Fusion Middleware 12c
date: 2014-12-09
Section: post
Tags: 
- oracle
- fmw
- bpm
- chef
Categories: 
- devops
---

Provisioning tools have change the way we create software environments: How much time we spend installing OS, databases, configuring platforms, applications? Now you can translate this steps into code, getting the software development benefits and challenges into infrastructure: versioning, reuse, continuous improvement.

<!--more-->

In this post, I will show you how to provision Oracle SOA Suite 12c using a Chef cookbook that I created and shared it on [Chef Supermarket](http://supermarket.chef.io).

## Provisioning with Chef

Chef is a provisioning tool, based on Ruby. Let you organize your "infrastructure" recipes on *Cookbooks*. Here you can find the [Chef Supermarket](https://supermarket.chef.io). For a Chef tutorial [go here](http://learn.chef.io/)

### Chef Cookbooks and Recipes

 **Chef Cookbooks** are groups of **Recipes**, and a **Recipe** is a sequence of instructions called **Resources**. *Directory, Execute, Service, Package* are some resources.

For instance: If you want to install an HTTP Server, first you should install a *Package*, and then start HTTP *Service*.

## Oracle Fusion Middleware Cookbook

I've created this cookbook: [oracle-fmw](https://supermarket.chef.io/cookbooks/oracle-fmw). The idea is to have a group of recipes to provide Fusion Middleware environments with different products like: SOA, BPM, BAM, OSB, and so on.

In the first release, this cookbook includes the following recipes:

- **prepare-infrastructure-12c**: Creates the required OS user and group, installs the required OS packages and execute some scripts to set required parameters.
- **install-bpm_qs-12c**: Installs Oracle BPM 12c which includes the following products (12.1.3): JDeveloper, Oracle SOA, Oracle OSB, Oracle BAM, Oracle BAM and others.
- **create-rcu_repository-12c**: Creates RCU repositories on Oracle Database instance.
- **create-domain-12c**: Creates a WebLogic Domain with these (optional) products: SOA, BAM, BPM, OSB.

In a following post I will show you how to use this cookbook. In the mind time you can download it, use it and improve it from [Chef Supermarket](https://supermarket.chef.io/cookbooks/oracle-fmw) and [GitHub](https://github.com/jeqo/oracle-fmw).
