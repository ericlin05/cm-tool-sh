#!/bin/bash

set -e

CM_HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../include.sh
source $BASE_DIR/../../../config.sh $CM_HOST $TLS_ENABLED

# https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_ssl_hbase.html

echo ""
echo "Updating HBase SSL configurations"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_server_keystore_location\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"ssl_server_keystore_keypassword\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"ssl_server_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hbase_hadoop_ssl_enabled\", \"value\": \"true\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating HBase Rest Server Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-HBASERESTSERVER\-' | sed -e 's/.*"\(.*HBASERESTSERVER.*\)".*/\1/g'`

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hbase_restserver_keystore_file\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"hbase_restserver_keystore_keypassword\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hbase_restserver_keystore_password\", \"value\": \"$KEYSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "Updating HBase Thrift Server Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-HBASETHRIFTSERVER\-' | sed -e 's/.*"\(.*HBASETHRIFTSERVER.*\)".*/\1/g'`

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"hbase_thriftserver_http_keystore_file\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"hbase_thriftserver_http_keystore_keypassword\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hbase_thriftserver_http_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"hbase_thriftserver_http_use_ssl\", \"value\": \"true\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "DONE"
echo ""
