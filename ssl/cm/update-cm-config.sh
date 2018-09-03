#!/bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash enable-agent.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not, "
  echo "               used to determine the URL to use"
  echo ""
  exit
fi

CM_HOST=$1
TLS_ENABLED=$2

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh $CM_HOST $TLS_ENABLED

echo ""
echo "Updating CM KeyStore Path and Password"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -s -S -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"KEYSTORE_PATH\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"KEYSTORE_PASSWORD\", \"value\": \"cloudera\" }, { \"name\": \"WEB_TLS\", \"value\": \"true\" } ] }" \
  "$API_URL/cm/config"

echo ""
echo "Updating TrustStore Location and Password For Cloudera Management services"
curl -s -S -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_client_truststore_location\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"ssl_client_truststore_password\", \"value\": \"changeit\" } ] }" \
  "$API_URL/cm/service/config"

echo ""

echo "Enabling CM Agnet TLS:"
curl -s -S -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d '{ "items": [ { "name": "AGENT_TLS", "value": "true" }, { "name": "NEED_AGENT_VALIDATION", "value": "true" } ] }' \
  "$API_URL/cm/config"

echo ""
echo "DONE"
echo ""
