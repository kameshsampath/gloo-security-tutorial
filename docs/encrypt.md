---
title: Gloo Edge Encrypting Traffic
summary: Gloo Edge Encrypting Traffic.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

At the end of this chapter you would have known how to:

- [x] Create Certificates for Fruits App
- [x] Configure Gloo Virtual Service with SSL/TLS

## Certifcate Request

As part of earlier [chapter](./step-certificates.md), we have step our CA and `StepIssuer` that helps us to create `cert-manager` CertificateRequests to generate the certificates.

As first step of that we need to create a CSR, we can use step cli to create the CSR.

Create a password file to that will be used to encrypt the keys, for the sake of this demo let use use our `$STEP_CA_PASSWORD` as our password to encrypt the keys,

```shell
echo "$STEP_CA_PASSWORD" > $TUTORIAL_HOME/certs/password-file
```

Let us create the CSR and keys,

```shell
step certificate create gloo-demos --csr \
  --san "${MINIKUBE_IP}.nip.io" \
  --san "*-${MINIKUBE_IP}.nip.io" \
  --san "${MINIKUBE_IP}" \
  --password-file $TUTORIAL_HOME/certs/password-file \
  $TUTORIAL_HOME/certs/gloo-demos.csr $TUTORIAL_HOME/certs/gloo-demos.key
```

If all goes well you should have the `gloo-demos.csr` and `gloo-demos.key` files in the `$TUTORIAL_HOME/certs` folder.

## Create Certificate Request

Having created the CSR we are good to create the  cert-manager's `CertificateRequest`,

As first step let us base64 encode the `gloo-demos` CSR,

```shell
export GLOO_DEMOS_CSR=$(cat $TUTORIAL_HOME/certs/gloo-demos.csr | openssl base64 | tr -d '\n' )
```

Create the `CertificateRequest`,

```shell
envsubst< $TUTORIAL_HOME/cluster/ssl/certificate-request.yaml | kubectl apply -f - 
```

Check the status of the `CertificateRequest`,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system {MINIKUBE_IP}.nip.io -o json | jq '.status.conditions[]'
```

If all went well you should see an output like,

```json hl_lines="10-13"
{
  "lastTransitionTime": "2021-08-26T07:34:30Z",
  "message": "Certificate request has been approved by cert-manager.io",
  "reason": "cert-manager.io",
  "status": "True",
  "type": "Approved"
}
{
  "lastTransitionTime": "2021-08-26T07:34:30Z",
  "message": "Certificate issued",
  "reason": "Issued",
  "status": "True",
  "type": "Ready"
}
```

Wait for the certificate to be updated in the request, you can check the same via,

CA Certificate can be retrieved by,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${MINIKUBE_IP}.nip.io -o json | jq -r '.status.certificate' | base64 -D >$TUTORIAL_HOME/certs/gloo-demos-ca.crt
```

TLS Certificate can be retrieved by,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${MINIKUBE_IP}.nip.io -o json | jq -r '.status.certificate' | base64 -D > $TUTORIAL_HOME/certs/gloo-demos.crt
```

## Verify Certificates

Get the root CA bundle,

```shell
kubectl get -n step-certificates-system -o jsonpath="{.data['root_ca\.crt']}" configmaps/step-certificates-certs  > $TUTORIAL_HOME/certs/root_ca.crt
```

```shell
if step certificate verify $TUTORIAL_HOME/certs/gloo-demos.crt --roots $TUTORIAL_HOME/certs/root_ca.crt --host=$MINIKUBE_IP.nxp.io ;
then
  echo 'Verification succeeded!'
else
 echo 'Verification failed!'
fi
```

With `Verification succeeded!`, we are now all set to encrypt our gateway traffic.

## Create SSL Secret

To be able to encrypt the traffic via Gloo Gateway, we need to configure the TLS certicates. The TLS certficate is configured using Kubernetes Secret.

Decrypt the private key that we used to create the Certificate Signing Request,

```shell
step certificate key $TUTORIAL_HOME/certs/gloo-demos.key --out=$TUTORIAL_HOME/certs/gloo-demos-key.pem
```

Let us create a Kubernetes secret that we will use later to configure the TLS for Gloo Virtual Service,

```shell
glooctl create secret tls $MINIKUBE_IP.nip.io-tls \
  --certchain $TUTORIAL_HOME/certs/gloo-demos.crt \
  --privatekey=$TUTORIAL_HOME/certs/gloo-demos-key.pem 
```

## Encrypt Fruits API Route

### One Way TLS

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
      namespace: gloo-system
  virtualHost:
    domains:
      - "${MINIKUBE_IP}.nip.io"
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

Get the HTTPS proxy URL,

```shell
export GLOO_PROXY_URL=$(glooctl proxy url --local-cluster-name="$PROFILE_NAME" \
  --port=https)
```

Let us check the service over SSL,

```shell
http --verify=$TUTORIAL_HOME/certs/gloo-demos-ca.crt "$GLOO_PROXY_URL/api/fruits/" "Host:$MINIKUBE_IP.nip.io"
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

### Mutual TLS (mTLS)

To enhance the security we can enable Fruits API to be `mtLS`. To make it configured in mTLS mode update the Virtual Service as shown,

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: fruits-api
  namespace: gloo-system
spec:
  displayName: FruitsAPI
  sslConfig:
    {-- oneWayTls: --}{--true--}
    secretRef:
      name: "${MINIKUBE_IP}.nip.io-tls"
      namespace: gloo-system
  virtualHost:
    domains:
      - "${MINIKUBE_IP}.nip.io"
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

Let us update the VirtualService to enable `mTLS`,

```shell
envsubst < $TUTORIAL_HOME/apps/microservice/fruits-api/gloo/virtual-service-mtls.yaml \
  | kubectl apply -f - 
```

Let us check the service again,

```shell
http --verify=$TUTORIAL_HOME/certs/gloo-demos-ca.crt "$GLOO_PROXY_URL/api/fruits/" "Host:$MINIKUBE_IP.nip.io"
```

Now let us add the client certificates and do the call again,

```shell
http "$GLOO_PROXY_URL/api/fruits/" 
```

Returns a list of fruits,

```json
--8<-- "includes/response.json"
```

---8<--- "includes/abbrevations.md"

[^1]: [cert-manager Self-Signed Certificates](https://cert-manager.io/docs/configuration/selfsigned/){target=_blank}
