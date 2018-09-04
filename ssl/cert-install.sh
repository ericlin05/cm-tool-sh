#!/bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash cert-install.sh CM_HOST TLS_ENABLED TYPE"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not"
  echo "  TYPE:        Either \"ca\" for CA Signed Certificate or \"self\" for Self-Signed Certificate"
  echo ""
  exit
fi

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
  cm_host=$2
  tls_enabled=$3
  cert_type=$4

  echo ""
  echo "========================================================"
  echo "Running on host: $host"
  ssh root@$host "rm -fr $REMOTE_DIR; mkdir $REMOTE_DIR"
  echo ""
  echo "Copying files to remote host $host:$REMOTE_DIR"
  scp -r $BASE_DIR/../* root@$host:$REMOTE_DIR

  echo ""
  echo "Running command: bash $REMOTE_DIR/ssl/cert-gen.sh $cm_host $tls_enabled $cert_type"
  ssh root@$host "bash $REMOTE_DIR/ssl/cert-gen.sh $cm_host $tls_enabled $cert_type"

  echo ""
  echo "Cleaning up files"
  ssh root@$host "rm -fr $REMOTE_DIR"
  echo "========================================================"
}

# for CA signed certificates, simply use the rootca.pem file as certificate
concat_cert_ca_signed()
{
  echo ""
  echo "Copying the rootca.pem file to each host under $CERT_DIR/$CA_CERTIFICATE"
  for host in "${CLUSTER_HOSTS[@]}"
  do
    ssh root@$host "cp $CERT_DIR/rootca.pem $CERT_DIR/$CA_CERTIFICATE"
  done
}

concat_cert_self_signed()
{
  echo ""
  echo "Concatenating pem files together from all hosts"
  for host in "${CLUSTER_HOSTS[@]}"
  do
    echo "Copying $CERT_DIR/server.pem on host $host to /tmp/tmp-cert-concat.pem:"
    echo ""
    ssh root@$host "cat $CERT_DIR/server.pem" >> /tmp/tmp-cert-concat.pem

    # we also need to copy each host's certificate to CM server so that
    # we can import it into CM's truststore
    if [ "$CM_HOST" != "$host" ]; then
      echo "Copying certificate from $host to $CM_HOST and import into $CM_HOST's truststore file"
      scp root@$host:$CERT_DIR/$host.pem $CERT_DIR
      $JAVA_HOME/bin/keytool -import -alias $host -file $CERT_DIR/$host.pem -trustcacerts -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass $TRUSTSTORE_PASS -noprompt
      echo "$JAVA_HOME/bin/keytool -import -alias $host -file $CERT_DIR/$host.pem -trustcacerts -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass $TRUSTSTORE_PASS -noprompt"
      echo ""
    fi
  done
  
  # after finished, re-upload them back to their original location
  echo ""
  echo "Re-uploading concatenated files back to each host"
  for host in "${CLUSTER_HOSTS[@]}"
  do
    scp /tmp/tmp-cert-concat.pem root@$host:$CERT_DIR/$CA_CERTIFICATE
  done
  
  rm -f /tmp/tmp-cert-concat.pem
}

# generating certificates on each host
for host in "${CLUSTER_HOSTS[@]}"
do
  run_on_host $host $CM_HOST $TLS_ENABLED $TYPE
done

# now after all certificates generated, we need to concat them all into one file
# so that they can each server can be trusted with each other, needed for Hue, Impala etc
if [ "$TYPE" == "ca" ]; then
  concat_cert_ca_signed
else
  concat_cert_self_signed
fi
