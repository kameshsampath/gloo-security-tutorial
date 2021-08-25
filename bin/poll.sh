#!/bin/bash

set -eu
set -o pipefail

trap '{ echo "" ; exit 1; }' INT

PROFILE_NAME=${PROFILE_NAME:-gloo-security-tutorial}
PORT=${1:-http}

GLOO_PROXY_URL=$(glooctl proxy url \
  --local-cluster-name "$PROFILE_NAME" \
  --port="$PORT")
  
export GLOO_PROXY_URL

cmdArgs=("--body")

if [ "$PORT" == "https" ];
then
  cmdArgs+=("--verify=no")
fi

while true
do
  http "$GLOO_PROXY_URL/api/fruits/" "${cmdArgs[@]}"
  sleep .3
done;
