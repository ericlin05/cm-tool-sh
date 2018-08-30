#!/bin/bash

set -e

CM_HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../../config.sh $CM_HOST $TLS_ENABLED

# https://www.cloudera.com/documentation/enterprise/latest/topics/impala_ssl.html

echo ""
echo "Updating Impala SSL configurations"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"client_services_ssl_enabled\", \"value\": \"true\" }, { \"name\": \"ssl_server_certificate\", \"value\": \"$CERT_DIR/server.pem\" }, { \"name\": \"ssl_private_key\", \"value\": \"$CERT_DIR/server.key\" }, { \"name\": \"ssl_private_key_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"ssl_client_ca_certificate\", \"value\": \"$CERT_DIR/$CA_CERTIFICATE\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating Impala Daemon Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-IMPALAD\-' | sed -e 's/.*"\(.*IMPALAD.*\)".*/\1/g'` 

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"webserver_certificate_file\", \"value\": \"$CERT_DIR/server.pem\" }, { \"name\": \"webserver_private_key_file\", \"value\": \"$CERT_DIR/server.key\" }, { \"name\": \"webserver_private_key_password_cmd\", \"value\": \"$KEYSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "Updating Catalog Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-CATALOGSERVER\-' | sed -e 's/.*"\(.*CATALOGSERVER.*\)".*/\1/g'` 

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"webserver_certificate_file\", \"value\": \"$CERT_DIR/server.pem\" }, { \"name\": \"webserver_private_key_file\", \"value\": \"$CERT_DIR/server.key\" }, { \"name\": \"webserver_private_key_password_cmd\", \"value\": \"$KEYSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "Updating StateStore Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-STATESTORE\-' | sed -e 's/.*"\(.*STATESTORE.*\)".*/\1/g'` 

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"webserver_certificate_file\", \"value\": \"$CERT_DIR/server.pem\" }, { \"name\": \"webserver_private_key_file\", \"value\": \"$CERT_DIR/server.key\" }, { \"name\": \"webserver_private_key_password_cmd\", \"value\": \"$KEYSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "DONE"
echo ""
