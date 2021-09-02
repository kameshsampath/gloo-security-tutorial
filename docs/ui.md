---
title: Application UI
summary: The Fruits Application UI.
authors:
  - Kamesh Sampath
date: 2021-09-01
---

At the end of this chapter you would have:

- [x] Create Certifiates for UI Application
- [x] Deployed Fruits Application UI
- [x] Configure Gloo Virtual Service

## Ensure environment

Lets ensure that we have all the required environment variables set for this module,

```bash
echo "\n Tutorial Home: $TUTORIAL_HOME \n"
echo "\n Gloo Gateway Proxy IP: $GLOO_GATEWAY_PROXY_IP \n"
echo "\n Gloo Proxy HTTP URL: $GLOO_PROXY_HTTP_URL \n"
echo "\n Gloo Proxy HTTP URL: $GLOO_PROXY_HTTPS_URL \n"
echo "\n ROOT CA Cert: $ROOT_CA_CERT \n"
```

## Prepare Fruits UI Deployment

### Create Namespace

```shell
kubectl create ns ui
```

### Fruits UI SSL Certificates

To create the Fruits UI SSL certificate, we need to know the Fruits UI service LoadBalancer IP. To get the LB IP let us create the Fruits UI service,

```shell
kustomize build $TUTORIAL_HOME/apps/microservice/ui/overlays/minikube | envsubst | kubectl apply -f -
```

Get the Fruits UI LoadBalancer IP,

```shell
export FRUITS_UI_IP=$(kubectl get svc -n ui fruits-app-ui -ojson | jq -r '.status.loadBalancer.ingress[0].ip')
```

!!! note
    As you would have observed the deployment `fruits-app-ui` is not up as we have set the replicas to `0`. We will scale the application once we have certificates ready to be used.

### Create Fruits UI CSR

Let us create the CSR and keys,

```shell
step certificate create fruits-ui --csr \
  --san "${FRUITS_UI_IP}.nip.io" \
  --san "*-${FRUITS_UI_IP}.nip.io" \
  --san "*.${FRUITS_UI_IP}.nip.io" \
  --san "${FRUITS_UI_IP}" \
  --password-file $TUTORIAL_HOME/certs/password-file \
  $TUTORIAL_HOME/certs/fruits-ui.csr $TUTORIAL_HOME/certs/fruits-ui-key
```

If all goes well you should have the `fruits-ui.csr` and `fruits-ui-key` files in the `$TUTORIAL_HOME/certs` folder.

## Create Certificate Request

Having created the CSR we are good to create the  cert-manager's `CertificateRequest`,

As first step let us base64 encode the `fruits-ui` CSR,

```shell
export FRUITS_UI_CSR=$(cat $TUTORIAL_HOME/certs/fruits-ui.csr | step base64 | tr -d '\n' )
```

Create the `CertificateRequest`,

```shell
envsubst< $TUTORIAL_HOME/apps/microservice/ui/certificate-request.yaml | kubectl create -f - 
```

Check the status of the `CertificateRequest`,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${FRUITS_UI_IP}.nip.io -o json | jq '.status.conditions[]'
```

If all went well you should see an output like,

```json hl_lines="10-13"
{
  "lastTransitionTime": "2021-08-27T16:15:14Z",
  "message": "Certificate request has been approved by cert-manager.io",
  "reason": "cert-manager.io",
  "status": "True",
  "type": "Approved"
}
{
  "lastTransitionTime": "2021-08-27T16:15:14Z",
  "message": "Certificate issued",
  "reason": "Issued",
  "status": "True",
  "type": "Ready"
}
```

Wait for the certificate to be updated in the request, you can check the same via,

CA Certificate can be retrieved by,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${FRUITS_UI_IP}.nip.io -o json | jq -r '.status.ca' | step base64 -d >$TUTORIAL_HOME/certs/fruits-ui-ca.crt
```

TLS Certificate can be retrieved by,

```shell
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${FRUITS_UI_IP}.nip.io -o json | jq -r '.status.certificate' | step base64 -d > $TUTORIAL_HOME/certs/fruits-ui.crt
```

## Verify Certificates

```shell
$TUTORIAL_HOME/bin/verifyCerts.sh $TUTORIAL_HOME/certs/fruits-ui.crt $FRUITS_UI_IP.nip.io
```

With `Verification succeeded!`, we are now all set to encrypt our gateway traffic.

## Create SSL Secret

To be able to encrypt the traffic via Gloo Gateway, we need to configure the TLS certicates. The TLS certficate is configured using Kubernetes Secret.

Decrypt the private key that we used to create the Certificate Signing Request,

```shell
step certificate key $TUTORIAL_HOME/certs/fruits-ui-key --out=$TUTORIAL_HOME/certs/fruits-ui.key
```

!!! note
    The command out put says its public key, but its actually decrypted private key

```shell
kubectl create secret generic fruits-ui-tls -n ui \
  --from-file=tls.crt=$TUTORIAL_HOME/certs/fruits-ui.crt \
  --from-file=tls.key=$TUTORIAL_HOME/certs/fruits-ui.key \
  --from-file=ca.crt=$TUTORIAL_HOME/certs/fruits-ui-ca.crt
```

### Created Trusted CA Secret

Lets also make sure the `trusted-ca` secret is available in the deployment namespace `ui`:

```bash
kubectl get secrets trusted-ca -n ui
```

If you dont find the CA secret, create the same by,

```bash
envsubst < $TUTORIAL_HOME/cluster/gloo/trusted-ca.yaml | kubectl apply -n ui -f -
```

## Scale Deployment UI

As we have already deployed the `fruits-app-ui`, its enough that we scale it,

```bash
kubectl -n ui scale --replicas=1 deploy/fruits-app-ui
```

Wait for the UI application to be up and running,

```bash
kubectl rollout status -n ui deploy/fruits-app-ui --timeout=60s
```

## Access UI

```bash
export FRUITS_UI_URL="https://${FRUITS_UI_IP}.nip.io"
echo $FRUITS_UI_URL
```

Open the `$FRUITS_UI_URL` on your browser.
