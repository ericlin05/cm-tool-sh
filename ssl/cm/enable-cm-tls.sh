#!/bin/bash

# This script helps to enable TLS for:
# - CM Admin Console
# - CM Management Services
# _ CM Agnets
# Steps followed from below official doc:
# https://www.cloudera.com/documentation/enterprise/latest/topics/how_to_configure_cm_tls.html

set -e

HOST=$1
TLS_ENABLED=$2

BASE_DIR=$(dirname $0)

# Update CM Configurations to enable TLS for CM, CM Management Services and CM Agents
sh $BASE_DIR/update-cm-config.sh $HOST $TLS_ENABLED

echo ""
echo "Please make sure that above commands returned correctly and confirm \"yes\" to continue restarting CM server and agents"
read response

if [ $response == "yes" ]; then
  sh $BASE_DIR/enable-cm-agent-tls.sh $HOST $TLS_ENABLED

  echo ""
  echo "Restarting CM server on host: $HOST"
  ssh root@$HOST 'systemctl restart cloudera-scm-server'
  echo ""
  echo "After CM restarted, please log into CM and restart Cloudera Management services"
  echo ""
fi

