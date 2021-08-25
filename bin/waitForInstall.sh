#!/bin/bash

set -eu
set -o pipefail

trap '{ echo "" ; exit 1; }' INT

GLOO_NAMESPACE=${1:-gloo-system}

# TODO improve to start only after deployments are created
kubectl get deploy -n "$GLOO_NAMESPACE" --no-headers -oname  |\
  while IFS="" read -r deploy; \
  do 
    kubectl rollout status -n "$GLOO_NAMESPACE" "$deploy" --timeout=120s
  done;
