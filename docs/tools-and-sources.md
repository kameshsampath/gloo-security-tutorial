---
title: Tools and Sources
summary: Tools and demo sources that are required for this tutorial.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

We will be using the following tools as part of the tutorial. Please have them installed and configured before proceeding further.

## Download Tools

| Tool      | macos                          | linux | windows|
| ----------- | ----------- |  ----------- | ----------- |
[minikube](https://minikube.sigs.k8s.io/docs/){target=_blank} |[Install](https://minikube.sigs.k8s.io/docs/start/){target=_blank}|[Install](https://minikube.sigs.k8s.io/docs/start/){target=_blank}|[Install](https://minikube.sigs.k8s.io/docs/start/){target=_blank}
|[helm](https://helm.sh){target=_blank}| `brew install helm`|[Install](https://helm.sh/docs/intro/install/){target=_blank}|`choco install kubernetes-helm`
|[glooctl](https://docs.solo.io/gloo-edge/latest/getting_started/){target=_blank}|[Download](https://github.com/solo-io/gloo/releases/download/v1.8.10/glooctl-darwin-amd64)|[Download](https://github.com/solo-io/gloo/releases/download/v1.8.10/glooctl-linux-amd64)|[Download](https://github.com/solo-io/gloo/releases/download/v1.8.10/glooctl-windows-amd64.exe)
|[jq](https://stedolan.github.io/jq/){target=_blank}|`brew install jq`|[Download](https://stedolan.github.io/jq/download/){target=_blank}|`chocolatey install jq`
|[kubectl](https://kubectl.docs.kubernetes.io){target=_blank}|`brew install kubectl`|[Download](https://kubectl.docs.kubernetes.io/installation/kubectl/binaries/){target=_blank}|`choco install kubernetes-cli`
|[kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/){target=_blank}|`brew install kustomize`|[Download](https://kubectl.docs.kubernetes.io/installation/kustomize/binaries/){target=_blank}|`choco install kustomize`
|[step cli](https://smallstep.com/docs/step-cli/installation){target=_blank}|`brew install step`|[Download](https://smallstep.com/docs/step-cli/installation#linux){target=_blank}|[Download](https://smallstep.com/docs/step-cli/installation#windows){target=_blank}

!!! important
  You will need Gloo Edge Enterprise License Key to run the demo exercises. If you dont have one, get a trial license from [solo.io](https://www.solo.io/products/gloo-edge#enterprise-trial).

## Demo Sources

Clone the demo sources from the GitHub respository,

```shell
git clone https://github.com/kameshsampath/gloo-security-tutorial
cd gloo-security-tutorial
```

For convinience, we will refer the clone demo sources folder as `$TUTORIAL_HOME`,

```shell
export PROFILE_NAME="gloo-tutorial"
export TUTORIAL_HOME="$PWD"
```

## Kubernetes Cluster Setup

As part of this tutorial we will use minikube as our target cluster. To create the minikube cluster run the following command,

```shell
$TUTORIAL_HOME/bin/start-minikube.sh
```

### Metallb

As we will need to access the Gloo Gateway proxy on the host, we will use [metallb](https://metallb.universe.tf) addon to minikube.

Enable the metallb addon by running,

```shell
minikube -p$PROFILE_NAME addons enable metallb
```

Wait for the metallb deployment to be ready,

```shell
kubectl rollout status -n metallb-system deploy/controller --timeout=60s
```

Get the minikube IP by running the command,

```shell
export MINIKUBE_IP=$(minikube -p$PROFILE_NAME ip)
echo $MINIKUBE_IP
```

Once the addon is enabled run the following command to configure the LoadBalancer IP range,

```shell
minikube -p $PROFILE_NAME addons configure metallb
```

!!! important
    Ensure that the **Enter Load Balancer Start IP** and **Enter Load Balancer End IP** is in the same subnet of `$MINIKUBE_IP`.
    For an example if `$MINIKUBE_IP` is `192.168.64.20`, the set the `Enter Load Balancer Start IP` to be something like `192.168.64.200` and `Enter Load Balancer End IP` to be something like `192.168.64.250`, that will give enough slack for you to create new minikube clusters without any ip clash.


Once you have setup minikube you are all set to move to next chapter to setup the certificate authority.