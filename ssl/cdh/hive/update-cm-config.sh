#!/bin/bash

set -e

HOST=$1
CLUSTER=$2
HIVE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../../config.sh $HOST $TLS_ENABLED

echo ""
echo "Updating HiveServer2 KeyStore Path and Password"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_enable_ssl\", \"value\": \"true\" }, { \"name\": \"hiveserver2_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hiveserver2_keystore_path\", \"value\": \"$CERT_DIR/server.jks\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$HIVE/config"

echo ""
echo "Updating HiveServer2 TrustStore Location and Password"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_truststore_file\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"hiveserver2_truststore_password\", \"value\": \"$TRUSTSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$HIVE/config"

echo ""
echo "DONE"
echo ""
