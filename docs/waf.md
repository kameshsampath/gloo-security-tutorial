---
title: Gloo Edge Web Application Firewall
summary: Gloo Edge Web Application Firewall.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

# Gloo Edge::Web Application Firewall

At the end of this chapter you would have known how to:

- [x] Configure WAF

A WAF protects web applications by monitoring, filtering and blocking potentially harmful traffic and attacks that can overtake or exploit them.

Gloo Edge Enterprise includes the ability to enable the ModSecurity [Web Application Firewall](https://docs.solo.io/gloo-edge/latest/guides/security/waf/){target=_blank}for any incoming and outgoing HTTP connections.

For this demo, let us assume that our application does not support *Firefox* yet so for any requests that come with *Firefox* browser agent need to be blocked and informed.

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: fruits-api
  namespace: gloo-system
spec:
  displayName: FruitsAPI
  virtualHost:
    options:
      # -------- Web Application Firewall - Check User-Agent  -----------
      waf: # (1)
        ruleSets: # (2)
        - ruleStr: | # (3)
            SecRuleEngine On
            SecRule REQUEST_HEADERS:User-Agent ".*Firefox.*" "deny,status:403,id:107,phase:1,msg:'unsupported user agent'" 
        customInterventionMessage: "Firefox not supported" # (4)
    domains:
      - "*"
    routes:
      # --------------------- Application Routes -----------------
      - matchers:
          - prefix: /api/
        routeAction:
          single:
            upstream:
              name: fruits-app-fruits-api-8080
              namespace: gloo-system
        options:
          prefixRewrite: /v1/api/
          # ---------------- Rate limit config ----------------------
          rateLimitConfigs:
            refs:
            - name: global-limit
              namespace: gloo-system

```

1. Define WAF rules
2. The WAF block can have one or more `ruleSets`
3. The rule inspects the `User-Agent` header
4. The message to display for rule voilations

Let us update the Virtual Service with WAF enabled,

```shell
kubectl apply -n gloo-system -f $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service-waf.yaml
```

Try simulating the API request as if it was generated from *Firefox* browser:

```shell
http $GLOO_PROXY_URL/api/fruits/ User-Agent:Firefox
```

The request should with a response,

```text
{== HTTP/1.1 403 Forbidden ==}
content-length: 21
content-type: text/plain
date: Wed, 18 Aug 2021 11:24:46 GMT
server: envoy

{== Firefox not supported ==}
```

No try the same request with any other user agent which should succeed.

```shell
http $GLOO_PROXY_URL/api/fruits/ User-Agent:Safari
```
