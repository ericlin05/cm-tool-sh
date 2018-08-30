#!/bin/bash

set -e

SERVER_HOST="$1"
IS_SECURE="$2"
TYPE="$3"

BASE_DIR=$(dirname $0)
source $BASE_DIR/../config.sh $SERVER_HOST $IS_SECURE

if [ $TYPE == '' ] || [ $TYPE != 'self' ] || [ $TYPE != 'ca' ]; then
  TYPE='self'
fi

run_on_host()
{
  host=$1
  cert_type=$2
  echo ""
  echo "========================================================"
  echo "Running on host: $host"
  ssh root@$host "rm -fr $REMOTE_DIR; mkdir $REMOTE_DIR"
  echo ""
  echo "Copying files to remote host $host:$REMOTE_DIR"
  scp -r $BASE_DIR/../* root@$host:$REMOTE_DIR

  echo ""
  echo "Running command: bash $REMOTE_DIR/ssl/cert-gen.sh $cert_type"
  ssh root@$host "bash $REMOTE_DIR/ssl/cert-gen.sh $cert_type" 

  echo ""
  echo "Cleaning up files"
  ssh root@$host "rm -fr $REMOTE_DIR"
  echo "========================================================"
}

# generating certificates on each host
run_on_host $SERVER_HOST $TYPE
for host in "${CLUSTER_HOSTS[@]}"
do
  run_on_host $host $TYPE
done

# now after all certificates generated, we need to concat them all into one file
# so that they can each server can be trusted with each other, needed for Hue, Impala etc
echo ""
echo "Concatenating pem files together from all hosts"
ssh root@$SERVER_HOST "cat $CERT_DIR/server.pem" > /tmp/tmp-cert-concat.pem
for host in "${CLUSTER_HOSTS[@]}"
do
  ssh root@$host "cat $CERT_DIR/server.pem" >> /tmp/tmp-cert-concat.pem
done

# after finished, re-upload them back to their original location
echo ""
echo "Re-uploading concatenated files back to each host"
scp /tmp/tmp-cert-concat.pem root@$SERVER_HOST:$CERT_DIR/$CA_CERTIFICATE
for host in "${CLUSTER_HOSTS[@]}"
do
  scp /tmp/tmp-cert-concat.pem root@$host:$CERT_DIR/$CA_CERTIFICATE
done

rm -f /tmp/tmp-cert-concat.pem

