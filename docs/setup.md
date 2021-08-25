---
title: Gloo Edge Setup
summary: Install and configure Gloo Edge Enterprise.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Ensure Environment

Make sure you have the Gloo Enterprise License Key before proceeding to install. Export the license key to variable,

```shell
export GLOO_LICENSE_KEY=<your Gloo EE License Key>
```

## Download glooctl

Download and install latest **glooctl** by running,

```shell
curl -sL https://run.solo.io/gloo/install | sh
```

Add glooctl to the system path,

```shell
export PATH=$HOME/.gloo/bin:$PATH
```

## Prepare Gloo Edge install

Create the `gloo-system` namespace to install `Gloo Edge`,

```shell
kubectl create namespace gloo-system
```

Create a secret with our custom CA root certificate,

```shell
kubectl create secret generic trusted-ca --from-file=tls.crt=$TUTORIAL_HOME/certs/root_ca.crt -n gloo-system
```

Add `helm` repository,

```shell
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
helm repo update
```

Get the latest Gloo Edge version

```shell
export GLOO_EE_VERSION=$(helm search repo glooe -ojson | jq -r '.[0].version')
```

As we need to ensure Gloo uses our custom CA, we need to patch the Gloo' `extauth` deployment and inject our root CA.

Run the command to create the patch,

```shell
envsubst < $TUTORIAL_HOME/cluster/gloo/extauth-patch-template > $TUTORIAL_HOME/cluster/gloo/extauth-patch.yaml
```

## Install Gloo Edge

Now we are all set to install Gloo Edge, Gloo Edge proxy is a Kubernetes service of type `LoadBalancer`, for the purpose of this blog we will configure it to be of type `NodePort` so that we can access from the host machine.

```shell
helm install gloo glooe/gloo-ee --namespace gloo-system \
 --set license_key=$GLOO_LICENSE_KEY \
{== --set gloo.gatewayProxies.gatewayProxy.service.httpsNodePort=30080 ==}\
{== --set gloo.gatewayProxies.gatewayProxy.service.httpsNodePort=30443 ==}\
 --post-renderer $TUTORIAL_HOME/cluster/gloo/kustomize.sh \
 --wait
```

!!! note
    - You can safely ignore the helm warnings

It will take few minutes for the gloo to be ready, watch the status of the deployments using:

```shell
$TUTORIAL_HOME/bin/waitForInstall.sh
```

Once all the gloo components(deployments) comes up, do a sanity check by running,

```shell
glooctl check
```

A successful gloo edge installation should show an output like,

```text
Checking deployments... OK
Checking pods... OK
Checking upstreams... OK
Checking upstream groups... OK
Checking auth configs... OK
Checking rate limit configs... OK
Checking VirtualHostOptions... OK
Checking RouteOptions... OK
Checking secrets... OK
Checking virtual services... OK
Checking gateways... OK
Checking proxies... OK
Checking rate limit server... OK
No problems detected.
I0818 09:29:26.773174    6734 request.go:645] Throttling request took 1.041899775s, request: GET:https://127.0.0.1:57778/apis/storage.k8s.io/v1?timeout=32s

Detected Gloo Federation!
```
