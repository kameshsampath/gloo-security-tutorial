---
title: Public Key Infrastructure
summary: Setup Private Certificate Authority.
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

## Configure Step CA

By default the `step-ca` issues TLS certicates that are valid only for **24 hours**. For the tutorial purpose we will reconfigure it to be **720 hours(30 days)**. For more information on the step configuration check the [documentation](https://smallstep.com/docs/step-ca/configuration).

```bash
CA_JSON=$(kubectl get cm -n step-certificates-system step-certificates-config -o json | jq -r '.data["ca.json"]' |  jq -c '.authority.claims += { "maxTLSCertDuration": "720h" }' | jq -Rs .)
```

Update the `step-certificates-config`,

```bash
kubectl patch configmap/step-certificates-config \
  -n step-certificates-system  \
  --type merge \
  -p "{\"data\":{\"ca.json\": $CA_JSON }}"
```

Lets restart the statefulset to make sure the updated configuration takes effect,

```bash
kubectl rollout restart  -n step-certificates-system statefulset/step-certificates 
```

Wait for the stateful set `step-certificates` to be up

```bash
kubectl rollout status -n step-certificates-system statefulset/step-certificates --timeout=60s
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

Save the root CA file,

```shell
kubectl get -n step-certificates-system -o jsonpath="{.data['root_ca\.crt']}" configmaps/step-certificates-certs > $TUTORIAL_HOME/certs/root_ca.crt
```

You can inspect the root ca certficate by,

```shell
step certificate inspect $TUTORIAL_HOME/certs/root_ca.crt
```

Get CA root certifiate as PEM,

```shell
export ROOT_CA_CERT=$(kubectl get -n step-certificates-system -o jsonpath="{.data['root_ca\.crt']}" configmaps/step-certificates-certs | step base64 | tr -d '\n')
```

Get the Provisioner Key ID,

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

## Configure Gloo Edge

We have now setup the Certifcate Authority and Issuer. We need to update the Gloo Edge deployment to trust the CA,

Create a secret with our custom CA root certificate,

```shell
envsubst < $TUTORIAL_HOME/cluster/gloo/trusted-ca.yaml | kubectl apply -n gloo-system -f -
```

As we need to ensure that Gloo extauth uses our custom CA, we need to patch the Gloo' `extauth` deployment and inject our root CA.

```shell
export GLOO_EE_IMAGE=$(kubectl get -n gloo-system deployments.apps extauth -o json | jq -r '.spec.template.spec.containers | .[] | select(.name == "extauth") | .image')
```

Create the patch,

```shell
envsubst < $TUTORIAL_HOME/cluster/gloo/extauth-patch-template > $TUTORIAL_HOME/cluster/gloo/extauth-patch.json
```

Run the command to patch the `extauth` deployment,

```shell
kubectl patch deployment -n gloo-system extauth --type='json' -p "$(cat $TUTORIAL_HOME/cluster/gloo/extauth-patch.json)"
```

Verify if the patch was successful,

```shell
exit_code=$(kubectl get pods -n gloo-system -l gloo=extauth -o json  | jq '.items[0].status.initContainerStatuses|.[]|select(.name=="add-ca-cert")|.state.terminated.exitCode')
exit_reason=$(kubectl get pods -n gloo-system -l gloo=extauth -o json  | jq '.items[0].status.initContainerStatuses|.[]|select(.name=="add-ca-cert")|.state.terminated.reason')
echo "Exit Code: $exit_code"
echo "Exit Reason: $exit_reason"
```

You should see the following output,

```text
Exit Code: 0
Exit Reason: "Completed"
```

[^1]: https://cert-manager.io/docs/configuration/external/