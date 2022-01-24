---
title: Ansible has a debug mode to pause and troubleshoot
date: 2022-01-21
section: til
tags:
- ansible
- automation
categories:
- ops
---

I have been running Ansible for a while now.
My usual/naive way of debugging has always been adding a `debug` module[[1]](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html), and get the execution running til that point.

I figured that there are better ways to deal with this[[2]](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_debugger.html#examples).
By using the debug mode, tasks will stop when failing (by default) and you'll be able to introspect into the task, variables, and context when things failed.
Even better, you'll be able to re-execute if there was a transient error.

## References:

[1] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html

[2] https://docs.ansible.com/ansible/2.9/user_guide/playbooks_debugger.html#examples