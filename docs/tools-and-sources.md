---
title: Tools and Sources
summary: Tools that are required for this tutorial.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Tools

We will be using the following tools as part of the tutorial. Please have them installed and configured before proceeding further,

- [minikube](https://minikube.sigs.k8s.io/docs/){target=_blank}
- [helm](https://helm.sh/docs/intro/install/){target=_blank}
- [glooctl](https://docs.solo.io/gloo-edge/latest/getting_started/){target=_blank}
- [jq](https://stedolan.github.io/jq/){target=_blank}
- [kubectl](https://kubectl.docs.kubernetes.io/installation/kubectl/){target=_blank}
- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/){target=_blank}
- [step cli](https://smallstep.com/docs/step-cli/installation){target=_blank}
- Gloo Edge Enterprise License Key

## Demo Sources

Clone the demo sources from the GitHub respository,

```shell
git clone https://github.com/kameshsampath/gloo-security-tutorial
cd gloo-security-tutorial
```

For convinience, we will refer the clone demo sources folder as `$TUTORIAL_HOME`,

```shell
export TUTORIAL_HOME="$PWD"
```

## Kubernetes Cluster Setup

As part of this tutorial we will use minikube as our target cluster.

To create the minikube cluster run the following command,

```shell
$TUTORIAL_HOME/bin/start-minikube.sh
```
