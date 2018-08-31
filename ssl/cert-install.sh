#!/bin/bash

set -e

CM_HOST="$1"
TLS_ENABLED="$2"
TYPE="$3"

BASE_DIR=$(dirname $0)
source $BASE_DIR/../config.sh $CM_HOST $TLS_ENABLED

if [ "$TYPE" == '' ] || ( [ "$TYPE" != 'self' ] && [ "$TYPE" != 'ca' ] ); then
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

# for CA signed certificates, simply use the rootca.pem file as certificate
concat_cert_ca_signed()
{
  ssh root@$CM_HOST "cp $CERT_DIR/rootca.pem $CERT_DIR/$CA_CERTIFICATE"
  for host in "${CLUSTER_HOSTS[@]}"
  do
    ssh root@$host "cp $CERT_DIR/rootca.pem $CERT_DIR/$CA_CERTIFICATE"
  done
}

concat_cert_self_signed()
{
  CM_HOST=$1
  CLUSTER_HOSTS=$2
 
  echo ""
  echo "Concatenating pem files together from all hosts"
  ssh root@$CM_HOST "cat $CERT_DIR/server.pem" > /tmp/tmp-cert-concat.pem
  for host in "${CLUSTER_HOSTS[@]}"
  do
    ssh root@$host "cat $CERT_DIR/server.pem" >> /tmp/tmp-cert-concat.pem
  done
  
  # after finished, re-upload them back to their original location
  echo ""
  echo "Re-uploading concatenated files back to each host"
  scp /tmp/tmp-cert-concat.pem root@$CM_HOST:$CERT_DIR/$CA_CERTIFICATE
  for host in "${CLUSTER_HOSTS[@]}"
  do
    scp /tmp/tmp-cert-concat.pem root@$host:$CERT_DIR/$CA_CERTIFICATE
  done
  
  rm -f /tmp/tmp-cert-concat.pem
}

# generating certificates on each host
run_on_host $CM_HOST $TYPE
for host in "${CLUSTER_HOSTS[@]}"
do
  run_on_host $host $TYPE
done

# now after all certificates generated, we need to concat them all into one file
# so that they can each server can be trusted with each other, needed for Hue, Impala etc
if [ "$TYPE" == "ca" ]; then
  concat_cert_ca_signed $CM_HOST ${CLUSTER_HOSTS[@]}
else
  concat_cert_self_signed $CM_HOST ${CLUSTER_HOSTS[@]}
fi

