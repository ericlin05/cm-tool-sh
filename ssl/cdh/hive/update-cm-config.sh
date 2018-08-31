#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo ""
  echo "Usage: bash enable-agent.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  CLUSTER:     The name of the cluster to update"
  echo "  SERVICE:     The service to update, values can be hive, impala, hdfs etc"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not, "
  echo "               used to determine the URL to use"
  echo ""
  exit
fi

set -e

CM_HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../../config.sh $CM_HOST $TLS_ENABLED

echo ""
echo "Updating HiveServer2 KeyStore Path and Password"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_enable_ssl\", \"value\": \"true\" }, { \"name\": \"hiveserver2_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hiveserver2_keystore_path\", \"value\": \"$CERT_DIR/server.jks\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating HiveServer2 TrustStore Location and Password"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hiveserver2_truststore_file\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"hiveserver2_truststore_password\", \"value\": \"$TRUSTSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "DONE"
echo ""
