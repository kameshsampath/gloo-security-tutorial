#!/bin/bash

set -eu

PROFILE_NAME=${PROFILE_NAME:-gloo-security-tutorial}
MEMORY=${MEMORY:-8192}
CPUS=${CPUS:-6}

unamestr=$(uname)

if [ "$unamestr" == "Darwin" ];
then
  minikube start -p "$PROFILE_NAME" \
  --memory="$MEMORY" \
  --driver="${MINIKUBE_DRIVER:-hyperkit}" \
  --cpus="$CPUS" \
  --disk-size=50g \
  --insecure-registry='10.0.0.0/24' 
else
  minikube start -p "$PROFILE_NAME" \
  --memory="$MEMORY" \
  --cpus="$CPUS" \
  --disk-size=50g \
  --insecure-registry='10.0.0.0/24'
fi

minikube profile "$PROFILE_NAME"
