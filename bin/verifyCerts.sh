#!/bin/bash

set -eu

set -o pipefail 

if step certificate verify "$1" --roots "$TUTORIAL_HOME/certs/root_ca.crt" --host="$2" ;
then
  echo 'Verification succeeded!'
else
 echo 'Verification failed!'
fi
