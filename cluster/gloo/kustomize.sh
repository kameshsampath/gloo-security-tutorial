#!/bin/sh
cat <&0 > "$TUTORIAL_HOME/cluster/gloo/all.yaml"
kustomize build "$TUTORIAL_HOME/cluster/gloo"