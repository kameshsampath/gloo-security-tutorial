---
title: Gloo Edge Encrypting Traffic
summary: Gloo Edge Encrypting Traffic.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

# Gloo Edge::Encrypting Traffic

At the end of this chapter you would have known how to:

- [x] Deploy Cert Manager
- [x] Configure Gloo Proxy to use Certficates

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
Server Version: v1.5.1
```

## Self Signed Certifcates

Before we start to encrypt the Gloo Gateway traffic, we will generate the certificates that could be used as the SSL certificates.

For this tutorial we will use our own Self-Signed[^1] certificates generated using **cert-manager**.

```shell
kustomize build $TUTORIAL_HOME/cluster/ssl | envsubst | kubectl apply -f -
```

Check the certifcate secret that is created,

```shell
kubectl get secrets -n my-certs "$MINIKUBE_IP.nip.io-tls" -o yaml
```

Inspect the details of the secret,

```shell
kubectl cert-manager inspect secret -n my-certs "$MINIKUBE_IP.nip.io-tls"
```

The command should show an output like,

```text
Valid for:
        DNS Names: 
                - 192.168.64.9.nip.io
                - *.example.com
                - localhost
                - 127.0.0.1.nip.io
        URIs: <none>
        IP Addresses: 
                - 192.168.64.9
                - 127.0.0.1
        Email Addresses: <none>
        Usages: 
                - cert sign
                - server auth

Validity period:
        Not Before: Sat, 21 Aug 2021 14:52:09 UTC
        Not After: Thu, 20 Aug 2026 14:52:09 UTC

Issued By:
        Common Name:    <none>
        Organization:   <none>
        OrganizationalUnit:     example
        Country:        <none>

Issued For:
        Common Name:    <none>
        Organization:   <none>
        OrganizationalUnit:     example
        Country:        <none>

Certificate:
        Signing Algorithm:      SHA256-RSA
        Public Key Algorithm:   RSA
        Serial Number:  2401601519814705181152316905762162533
        Fingerprints:   40:F5:A5:A4:B8:11:E2:6E:88:A9:E3:0B:3D:D0:F3:56:89:59:9B:70:65:DA:73:A3:F5:DD:B0:1B:A4:98:52:EC
        Is a CA certificate: true
        CRL:    <none>
        OCSP:   <none>

Debugging:
        Trusted by this computer:       no: x509: certificate signed by unknown authority
        CRL Status:     No CRL endpoints set
        OCSP Status:    Cannot check OCSP: No OCSP Server set
```

## Encrypt Fruits API Route

Let us update the Virtual Service to enable SSL via the `sslConfig` block as shown,

```yaml hl_lines="8-12"
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: fruits-api
  namespace: gloo-system
spec:
  displayName: FruitsAPI
  sslConfig:
    oneWayTls: true # (1)
    secretRef:
      name: "${MINIKUBE_IP}.nip.io-tls"
      namespace: my-certs
  virtualHost:
    domains:
      - "*"
    routes:
      # Application Routes
      # ------------
      - matchers:
          - prefix: /api/
        routeAction:
          single:
            upstream:
              name: fruits-app-fruits-api-8080
              namespace: gloo-system
        options:
          prefixRewrite: /v1/api/
```

1. By default Envoy Proxy does enable [mTLS](https://www.envoyproxy.io/docs/envoy/latest/start/quick-start/securing){target=_blank} when the Kubernetes secret has `ca.crt`.For this demo we will make this one way TLS by just trusting server alone.

Update the Virtual Service by adding the certs block,

```shell
envsubst < $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service-ssl.yaml \
  | kubectl apply -f - 
```

Let us check the service over SSL,

```shell
$TUTORIAL_HOME/bin/call.sh https
```

Returns a list of fruits,

```json
--8<-- "includes/response.json"
```

With us having enabled SSL, Gloo Edge will route all the traffic over **https** i.e. we will not able to acess the service over **http**.

Let us verify the sam by calling the service over http,

```shell
$TUTORIAL_HOME/bin/call.sh
```

Throws an error like,

```shell
http: error: ConnectionError: HTTPConnectionPool(host='192.168.64.9', port=30080): Max retries exceeded with url: /api/fruits/ (Caused by NewConnectionError('<urllib3.connection.HTTPConnection object at 0x106c090a0>: Failed to establish a new connection: [Errno 61] Connection refused')) while doing a GET request to URL: http://192.168.64.9:30080/api/fruits/
```

---8<--- "includes/abbrevations.md"

[^1]: [cert-manager Self-Signed Certificates](https://cert-manager.io/docs/configuration/selfsigned/){target=_blank}
