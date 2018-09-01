#!/bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
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

  # Level 1 TLS for CM
  SED_CMD1="sed -e 's/use_tls=0/use_tls=1/g' /etc/cloudera-scm-agent/config.ini"

  # this command Enable Server Certificate Verification on Cloudera Manager Agents
  # https://www.cloudera.com/documentation/enterprise/latest/topics/how_to_configure_cm_tls.html#topic_3
  # Level 2 TLS for CM
  SED_CMD2=" | sed -e 's@.*verify_cert_file=.*@verify_cert_file=$CERT_DIR/$CA_CERTIFICATE@g'"

  # Level 3 TLS for CM
  SED_CMD3=" | sed -e 's@.*client_key_file=.*@client_key_file=$CERT_DIR/server.key@g'"
  SED_CMD4=" | sed -e 's@.*client_cert_file=.*@client_cert_file=$CERT_DIR/server.pem@g'"
  SED_CMD5=" | sed -e 's@.*client_keypw_file=.*@client_key_file=$AGENT_KEYPASS@g'"
  SED_CMD6=" > /tmp/cm_config.ini.tmp"

  SED_CMD7="mv /tmp/cm_config.ini.tmp /etc/cloudera-scm-agent/config.ini ; rm -f /tmp/cm_config.ini.tmp"

  CREATE_PW_CMD="echo \"$KEYSTORE_PASS\" > $AGENT_KEYPASS ; chown root:root $AGENT_KEYPASS ; chmod 440 $AGENT_KEYPASS"
 
  # once all config updated, restart CM agent
  ssh root@$host "$CREATE_PW_CMD && $SED_CMD1 $SED_CMD2 $SED_CMD3 $SED_CMD4 $SED_CMD5 $SED_CMD6 && $SED_CMD7 && service cloudera-scm-agent restart"
  echo "DONE"
done
