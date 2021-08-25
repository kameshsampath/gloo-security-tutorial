---
title: Gloo Edge Authentication
summary: Integrate Gloo Edge with oAuth.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

At the end of this chapter you would have known how to:

- [x] Deploy [dexidp](https://dexidp.io){target=_blank}
- [x] Configure authentication to Fruits API

## Pre-requisties

We will be integrating GitHub via dexidp. For us to integrate dex with [GithHub oAuth](https://github.com/settings/applications/new) you need to have oAuth app registered and have the follwing credentials handy,

- GitHub oAuth ClientId
- GitHub oAuth CientSecret
- GitHub Organisation to use

## Ensure Enviroment

We will use the following variables as part of this module,

```shell
export MINIKUBE_IP=$(minikube -p $PROFILE_NAME ip)
export GH_OAUTH_CLIENT_ID=<your github oauth client id> # (1)
export GH_OAUTH_CLIENT_SECRET=<your github oauth client secret> # (2)
export GH_OAUTH_ORG=<the github org to use> # (3)
```

1. The GitHub oAuth Client Id
2. The GitHub oAuth Client secret corresponding to client id
3. The GitHub org or team to restrict the acess

## Create Github Secret Env file

Copy the template to env file,

```shell
cp $TUTORIAL_HOME/cluster/dex/github.env.secret.template $TUTORIAL_HOME/cluster/dex/github.env.secret
```

Update the `$TUTORIAL_HOME/cluster/dex/github.env.secret` values to map to your environment.

## Deploy Dex

```shell
kustomize build $TUTORIAL_HOME/cluster/dex | envsubst | kubectl apply -f - 
```

Wait for the dex deployment to be up and running

```shell
kubectl rollout status -n dex deploy/dex --timeout=60s
```

## Create Gloo oAuth Secret

We have configured the `fruits-app` static client to identify itself with dex using a secret, the following snippet from dex config.yaml shows the base64 encoded `secret` that was configured,

```yaml hl_lines="7"
staticClients:
- id: fruits-app
  redirectURIs:
  - 'http://$MINIKUBE_IP:30080/callback'
  name: 'Fruits App'
  # value is fruits-app-secret
 secret: "nJ1aXRzLWFwcC1zZWNyZXQ="
```

The value of the `client-secret` is same as the `secret` value in the dex `config.yaml`.

Let us create the Gloo oAuth secret to be used,

```shell
glooctl create secret oauth \
  --client-secret 'fruits-app' fruits-app-oauth
```

## Gloo oAuth Config

```shell
envsubst < $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/auth-config.yaml \
  | kubectl apply -f -
```

## Update Virtual Service

Now let us update the virtual service to use the oAuth config,

```shell
envsubst < $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service-oauth.yaml \
  | kubectl apply -f -
```

---8<--- "includes/abbrevations.md"
