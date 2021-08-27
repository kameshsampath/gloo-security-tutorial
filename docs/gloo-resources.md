---
title: Gloo Edge with Microservice
summary: Integrate Gloo Edge with Cloud Native Application.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Integrate with Gloo Edge

We have now deployed the Fruits API, in the up coming sections we will create the necessary Gloo Edge resources that will allow configure and access the API. To have more understanding on core concepts check the Gloo Edge [documentation](https://docs.solo.io/gloo-edge/latest/introduction/architecture/concepts/){target=_blank}.

At the end of this chapter you would have known how to:

- [x] [Discover Upstreams](https://docs.solo.io/gloo-edge/latest/introduction/architecture/concepts/#upstreams){target=_blank}
- [x] [Create Virtual Services](https://docs.solo.io/gloo-edge/latest/introduction/architecture/concepts/#virtual-services){target=_blank}


## Discover Upstreams

The Gloo Edge installation that as done as part of the demo is enabled to do auto discovery of the upstreams. The Fruits API that we deployed earlier would have been discovered as `fruits-app-fruits-api-8080`.

Let us check to see if thats available,

``` shell
glooctl get upstream fruits-app-fruits-api-8080
```

```text
-----------------------------------------------------------------------------+
|          UPSTREAM          |    TYPE    |  STATUS  |          DETAILS          |
-----------------------------------------------------------------------------+
| fruits-app-fruits-api-8080 | Kubernetes | Accepted | svc name:      fruits-api |
|                            |            |          | svc namespace: fruits-app |
|                            |            |          | port:          8080       |
|                            |            |          |                           |
-----------------------------------------------------------------------------+
```

## Route

A Route is a Gloo Virutal Service resource that allows us to access the API i.e. the services that are deployed on to Kubernetes.

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: fruits-api
  namespace: gloo-system
spec:
  displayName: FruitsAPI
  virtualHost:
    domains: # (1)
      - "$GLOO_GATEWAY_PROXY_IP.nip.io"
    routes:
      # Application Routes
      # ------------
      - matchers:
          - prefix: /api/ #(2)
        routeAction:
          single:
            upstream: #(3)
              name: fruits-app-fruits-api-8080
              namespace: gloo-system
        options:
          prefixRewrite: /v1/api/ #(4)

```

1. Domains that will be allowed by the Gateway
2. The prefix to access the API
3. The upstream that wil be used to route the request
4. The url rewrite to do before passing the request to backend

Let us create the virutal service,

```shell
envsubst < $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service.yaml | kubectl apply -n gloo-system -f -
```

Check the status of the virtual service

```shell
glooctl get vs fruits-api
```

```text
----------------------------------------------------------------------------------------------
| VIRTUAL SERVICE | DISPLAY NAME | DOMAINS | SSL  |  STATUS  | LISTENERPLUGINS |       ROUTES        |
----------------------------------------------------------------------------------------------
| fruits-api      |              | *       | none | Accepted |                 | / -> 1 destinations |
----------------------------------------------------------------------------------------------
```

## Invoke API

We need to use the Gloo proxy to access the API, we can use glooctl to get the proxy URL,

```shell
export GLOO_PROXY_URL="http://$GLOO_GATEWAY_PROXY_IP.nip.io"
```

Check if the API is accessible,

```shell
http $GLOO_PROXY_URL/api/fruits/
```

The command should return a list of fruits as shown,

```json
--8<-- "includes/response.json"
```

---8<--- "includes/abbrevations.md"

---8<--- "app/microservice/fruits-api/app/deployment.yaml"
