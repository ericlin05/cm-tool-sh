#!/bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo ""
  echo "Usage: bash enable-agent.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not"
  echo ""
  exit
fi

CM_HOST="$1"
TLS_ENABLED="$2"

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh $CM_HOST $TLS_ENABLED

for host in "${CLUSTER_HOSTS[@]}"
do
  echo ""
  echo "========================================================"
  echo "Running on host to enable TLS and restart CM agent: $host"
  # this command enables CM Agent to use TLS
  # https://www.cloudera.com/documentation/enterprise/latest/topics/how_to_configure_cm_tls.html#concept_a3w_g5d_xn
  SED_CMD1="sed -e 's/use_tls=0/use_tls=1/g' /etc/cloudera-scm-agent/config.ini > /tmp/config.ini.tmp"

  # this command Enable Server Certificate Verification on Cloudera Manager Agents
  # https://www.cloudera.com/documentation/enterprise/latest/topics/how_to_configure_cm_tls.html#topic_3
  SED_CMD2="sed -e 's@# verify_cert_file.*@verify_cert_file=$CERT_DIR/$CA_CERTIFICATE@g' /tmp/config.ini.tmp > /tmp/config.ini.tmp2"
  SED_CMD3="sed -e 's@^verify_cert_file=.*@verify_cert_file=$CERT_DIR/$CA_CERTIFICATE@g' /tmp/config.ini.tmp2 > /tmp/config.ini.tmp3"

  MV_CMD="mv /tmp/config.ini.tmp3 /etc/cloudera-scm-agent/config.ini ; rm -f /tmp/config.ini.tmp*"
 
  # once all config updated, restart CM agent
  ssh root@$host "$SED_CMD1 && $SED_CMD2 && $SED_CMD3 && $MV_CMD && service cloudera-scm-agent restart"
  echo "DONE"
done
