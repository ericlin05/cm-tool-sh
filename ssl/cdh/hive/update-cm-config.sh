#!/bin/bash

set -e

CM_HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../include.sh
source $BASE_DIR/../../../config.sh $CM_HOST $TLS_ENABLED

echo ""
echo "Updating HiveServer2 KeyStore Path and Password"
curl -s -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_enable_ssl\", \"value\": \"true\" }, { \"name\": \"hiveserver2_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hiveserver2_keystore_path\", \"value\": \"$CERT_DIR/server.jks\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating HiveServer2 TrustStore Location and Password"
curl -s -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_truststore_file\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"hiveserver2_truststore_password\", \"value\": \"$TRUSTSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating HiveServer2 WebUI to enable SSL"
ROLE_GROUP_ID=`curl -s -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-HIVESERVER2\-' | sed -e 's/.*"\(.*HIVESERVER2.*\)".*/\1/g'`

curl -s -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_enabled\", \"value\": \"true\" }, { \"name\": \"ssl_server_keystore_location\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"ssl_server_keystore_password\", \"value\": \"$KEYSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "DONE"
echo ""
