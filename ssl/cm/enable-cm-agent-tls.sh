#!/bin/bash

set -e

HOST="$1"
TLS_ENABLED="$2"

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh $HOST $TLS_ENABLED

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
  SED_CMD2="sed -e 's/# verify_cert_file=/verify_cert_file=\/opt\/cloudera\/security\/pki\/rootca.pem/g' /tmp/config.ini.tmp > /tmp/config.ini.tmp2"
  SED_CMD2="sed -e 's/^verify_cert_file.*/# verify_cert_file=\/opt\/cloudera\/security\/pki\/rootca.pem/g' /tmp/config.ini.tmp > /tmp/config.ini.tmp2"

  MV_CMD="rm -f /tmp/config.ini.tmp ; mv /tmp/config.ini.tmp2 /etc/cloudera-scm-agent/config.ini"
 
  # once all config updated, restart CM agent
  ssh root@$host "$SED_CMD1 && $SED_CMD2 && $MV_CMD && systemctl restart cloudera-scm-agent"
  echo "DONE"
done
