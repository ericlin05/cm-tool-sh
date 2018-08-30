#!/bin/bash

set -e

HOST=$1
TLS_ENABLED=$2

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh $HOST $TLS_ENABLED

echo ""
echo "Updating CM KeyStore Path and Password"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"KEYSTORE_PATH\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"KEYSTORE_PASSWORD\", \"value\": \"cloudera\" }, { \"name\": \"WEB_TLS\", \"value\": \"true\" } ] }" \
  "$API_URL/cm/config"

echo ""
echo "Updating TrustStore Location and Password"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_client_truststore_location\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"ssl_client_truststore_password\", \"value\": \"changeit\" } ] }" \
  "$API_URL/cm/service/config"

echo ""

echo "Enabling CM Agnet TLS:"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d '{ "items": [ { "name": "AGENT_TLS", "value": "true" } ] }' \
  "$API_URL/cm/config"

echo ""
echo "DONE"
echo ""
