---
title: Enable Certificate Revocation on Kafka clusters
date: 2022-02-09
section: til
tags:
- kafka
- ssl

categories:
- ops
- security
---

Recently I got a question on how to manage revoked SSL certificates in Kafka clusters.
With a proper Public Key Infrastructure, a Certificate Revocation List (CRL) can be available for clients to validate if a certificate is still valid regardless of its time-to-live.
For instance, if a private key has been compromised, then a certificate can be revoked before it's valid date.

<!--more-->

This is enforced at the JVM level, actually: 

```yaml
      ## Here is where CRL validation for revoked certificates is enabled.
      KAFKA_OPTS: "-Dcom.sun.security.enableCRLDP=true -Dcom.sun.net.ssl.checkRevocation=true"
```

If Kafka brokers have these flags enabled, the brokers will check that the CRL endpoint is accessible at boot time.
If it isn't, then the startup it fails.

Proof-of-concept to reproduce this configuration with Vault as a PKI: https://github.com/jeqo/docker-composes/tree/main/cp-vault-pki
