---
title: Private ACME CA
summary: Setup Private ACME Certificate Authority.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Overview

As part of this tutorial we will use the [step](https://smallstep.com) to setup a local private ACME CA. We will then use this CA to issue the certificates for all the other exercises that we will do as part of this demo.

## Deploy CA

```shell
kubectl apply -k $TUTORIAL_HOME/cluster/ca
```

## Retrieve ROOT CA

```shell
export CA_SVC_NODEPORT=$(kubectl get svc -n my-acme-ca ca -ojsonpath='{.spec.ports[?(@.name == "https")].nodePort}')
export CA_POD_NAME=$(kubectl get pods -n my-acme-ca -lapp=ca --no-headers | awk '{print $1}')
export ROOT_CA_FINGERPRINT=$(kubectl -n my-acme-ca exec -it $CA_POD_NAME -c ca -- step certificate fingerprint /home/user/.step/certs/root_ca.crt | tr -d '\n\r')
```

Download the root certificate

```shell
step ca root $TUTORIAL_HOME/certs/root_ca.crt \
 --ca-url "https://$(minikube -p$PROFILE_NAME ip):$CA_SVC_NODEPORT" \
 --fingerprint=$ROOT_CA_FINGERPRINT
```

With us now having our custom trusted CA, we will install Gloo Edge and configure it to use our custom CA as trusted CA.
