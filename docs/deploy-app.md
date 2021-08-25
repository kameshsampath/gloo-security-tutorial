---
title: Deploy Microservices
summary: Deploy Cloud Native Application.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

# Deploy App

The demo application that will be deployed is a simple Fruits microservice. The source code the Fruits API is available [here](https://github.com/kameshsampath/gloo-fruits-api){target=blank}.

At the end of this chapter you would have deployed a cloud native application that will be used in learning the Gloo Concepts.

## Deploy Database

```shell
kubectl apply -k $TUTORIAL_HOME/apps/microservice/fruits-api/db
```

Wait for the DB to be up

```shell
kubectl rollout status -n db deploy/postgresql --timeout=60s
```

{==

Waiting for deployment "postgresql" rollout to finish: 0 of 1 updated replicas are available...

deployment "postgresql" successfully rolled out

==}

## Deploy REST API

```shell
kubectl apply -k $TUTORIAL_HOME/apps/microservice/fruits-api/app
```

Wait for the REST API to be up

```shell
kubectl rollout status -n fruits-app deploy/fruits-api --timeout=60s
```

{==

Waiting for deployment "fruits-api" rollout to finish: 0 of 1 updated replicas are available...

deployment "fruits-api" successfully rolled out

==}
