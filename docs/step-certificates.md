---
title: CA and Issuer
summary: Setup Private ACME Certificate Authority.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Overview

As part of this tutorial we will use the [step](https://smallstep.com) to automate the setup local private CA. We will then use this CA to issue the certificates that we will use with Gloo as part of the other module exercises.

At the end of this chapter you would have setup,

- [x] Cert Manager
- [x] smallstep CA
- [x] smallstep Step Issuer

## Ensure Environment

```shell
export MINIKUBE_IP=$(minikube -p$PROFILE_NAME ip)
export STEP_CA_PASSWORD=password
export STEP_PROVISIONER_NAME=mygloodemos@example.com
```

## Download all Cert Manager

Download and install [cert-manager](https://github.com/jetstack/cert-manager/releases). Ensure that cert-manager is added to the system-path.

Verify `cert-manager`:

```shell
kubectl cert-manager version --short
```

The command should show an output like

```shell
Client Version: v1.5.1
error: could not detect the cert-manager version: the cert-manager CRDs are not yet installed on the Kubernetes API server
```

## Install Cert Manager

The error shown in the command is OK as we are yet to install the `cert-manager` in the cluster. Let us install by running,

```shell
kubectl cert-manager x install
```

Now running the version command `kubectl cert-manager version --short` again should show an output like:

```shell
Client Version: v1.5.1
Server Version: v1.5.3
```

## Deploy step-certificates

We can deploy the step-certificates to our existing kubernetes cluster using `helm`.

Add `step-certificates` helm repository,

```shell
helm repo add smallstep https://smallstep.github.io/helm-charts/
helm repo update
```

Update helm values file,

```shell
envsubst < $TUTORIAL_HOME/cluster/step-ca/values.tpl > $TUTORIAL_HOME/cluster/step-ca/values.yaml
```

Create the namespace to install `step-certificates`,

```shell
kubectl create ns step-certificates-system
```

Install `step-certificates` from repository,

```shell
helm install step-certificates smallstep/step-certificates \
  -n step-certificates-system \
  -f $TUTORIAL_HOME/cluster/step-ca/values.yaml \
  --wait
```

## Install Step Issuer

We will use [step-issuer](https://github.com/smallstep/step-issuer) as way to automate the certificate requests.

Create the namespace to install `step-issuer-system`,

```shell
kubectl create ns step-issuer-system
```

```shell
helm install -n step-issuer-system step-issuer smallstep/step-issuer --wait
```

## Deploy Step Issuer

In order to use the `step-certificates` CA we need to setup a `StepIssuer` to act as `cert-manager` issuer[^1].

The step-issuer needs few credentials from the step-certficates that we deployed earlier.

For convinience let us extract them and store in environment variables,

Get CA root certifiate as PEM,

```shell
export ROOT_CA_CERT=$(kubectl get -n step-certificates-system -o jsonpath="{.data['root_ca\.crt']}" configmaps/step-certificates-certs | openssl base64 | tr -d '\n')
```

Get the Provisioner Name,

```shell
export PROVISIONER_KID=$(kubectl get -n step-certificates-system -o jsonpath="{.data['ca\.json']}" configmaps/step-certificates-config \
  | jq -r --arg NAME "$STEP_PROVISIONER_NAME" \
  '.authority.provisioners | .[] | select(.name == $NAME) | .key.kid' | tr -d '\n' )
```

Create the Issuer,

```shell
envsubst < $TUTORIAL_HOME/cluster/step-ca/issuer.yaml | kubectl apply -f -
```

Wait for the issuer to be ready,

```shell
while [ "$(kubectl get stepissuers.certmanager.step.sm -n step-certificates-system step-issuer -o json | jq -r '.status.conditions|.[]|select(.type == "Ready")|.status')" != "True" ];
do
  echo "Waiting for StepIssuer to be ready"
  sleep .3
done
```

We have now setup the Certifcate Authority and Issuer. In the next module we will setup gloo and make it trust the our CA.

[^1]: https://cert-manager.io/docs/configuration/external/