#!/usr/bin/env bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash setup.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not"
  echo ""
  echo "This script helps to setup the public/private key pair from the CM host to the rest of hosts so that script"
  echo "can do the job without user intervention"
  echo ""
  exit
fi

CM_HOST="$1"
TLS_ENABLED="$2"

BASE_DIR=$(dirname $0)
source $BASE_DIR/config.sh $CM_HOST $TLS_ENABLED

if ! [ -f ~/.ssh/id_rsa ]; then
  echo "Generating public/private keys for current user, please leave passphrase empty"
  ssh-keygen
fi

for host in "${CLUSTER_HOSTS[@]}"
do
  echo "Copying public key to host $host, on prompt, please allow connection and enter password"
  ssh-copy-id root@$host
done

echo "DONE"
