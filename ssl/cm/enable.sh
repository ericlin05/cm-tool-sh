#!/bin/bash

set -e

# This script helps to enable TLS for:
# - CM Admin Console
# - CM Management Services
# _ CM Agents
# Steps followed from below official doc:
# https://www.cloudera.com/documentation/enterprise/latest/topics/how_to_configure_cm_tls.html

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash enable.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not"
  echo ""
  exit
fi

CM_HOST=$1
TLS_ENABLED=$2

BASE_DIR=$(dirname $0)

source $BASE_DIR/../../config.sh $CM_HOST $TLS_ENABLED

# Update CM Configurations to enable TLS for CM, CM Management Services and CM Agents
sh $BASE_DIR/update-cm-config.sh $CM_HOST $TLS_ENABLED

echo ""
echo "Please make sure that above commands returned correctly."
echo -n "And confirm \"yes\" to continue restarting CM server and agents: "
read response

if [ $response == "yes" ]; then
  #sh $BASE_DIR/enable-agent.sh $CM_HOST $TLS_ENABLED

  echo ""
  echo "Restarting CM server on host: $CM_HOST"
  ssh root@$CM_HOST 'service cloudera-scm-server restart'
  echo ""

  # do not capture the error so that we can continue checking CM's status
  set +e

  # waiting for CM to start so that we can restart CM management services
  test=""
  echo "Waiting 10 seconds for CM to start up:"
  while [ -z "$test" ]
  do
    sleep 5;
    echo "Continue waiting 5 seconds for CM to start up:"
    test=`curl -s -u $CM_USER:$CM_PASS "$CM_URL/api/version" $INSECURE`
  done

  echo ""
  echo "Restarting CM Management Services"
  curl -s -S -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  "$API_URL/cm/service/commands/restart"
fi
