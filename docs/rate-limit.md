---
title: Gloo Edge Rate Limit
summary: Gloo Edge Rate Limit Cloud Native Application.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

# Gloo Edge::Rate Limit

At the end of this chapter you would have known how to:

- [x] Configure Rate Limiting

As part of this section we will configure [Rate limiting](https://en.wikipedia.org/wiki/Rate_limiting){targe=_blank}.

```yaml
apiVersion: ratelimit.solo.io/v1alpha1
kind: RateLimitConfig
metadata:
  name: global-limit
  namespace: gloo-system
spec:
  raw:
    descriptors:
    - key: generic_key
      value: count
      rateLimit:
        requestsPerUnit: 10 #(1)
        unit: MINUTE #(1)
    rateLimits:
    - actions:
      - genericKey:
          descriptorValue: count

```

1. Number of requests
2. The duration for the request threshold, is this case 1 minute

Let us apply the rate limiting configuration,

```shell
kubectl apply -n gloo-system -f $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/ratelimit-config.yaml
```

Update the service with ratelimit,

```shell
kubectl apply -n gloo-system -f $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service-ratelimit.yaml
```

Let us now send requests to the API, with our current configuration we should start to get `HTTP 429` once we exceed 10 requests,

```shell
$TUTORIAL_HOME/bin/poll.sh
```

Wait for a minute more to try polling again to see the requests getting executed successfully.

{== TODO Rate Limite for Authenticated/UnAuthenticated users ==}

---8<--- "includes/abbrevations.md"
