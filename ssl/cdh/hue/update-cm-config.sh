#!/bin/bash

set -e

HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../../config.sh $HOST $TLS_ENABLED

# https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_ssl_hue.html 

echo ""
echo "Updating Hue Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-HUE_SERVER\-' | sed -e 's/.*"\(.*HUE_SERVER.*\)".*/\1/g'`

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_cacerts\", \"value\": \"$CERT_DIR/$CA_CERTIFICATE\" }, { \"name\": \"ssl_private_key_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"ssl_private_key\", \"value\": \"$CERT_DIR/server.key\" }, { \"name\": \"ssl_certificate\", \"value\": \"$CERT_DIR/server.pem\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "Updating Hue LOAD BALANCER Config to enable SSL"
ROLE_GROUP_ID=`curl -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-HUE_LOAD_BALANCER\-' | sed -e 's/.*"\(.*HUE_LOAD_BALANCER.*\)".*/\1/g'`

curl -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"ssl_certificate\", \"value\": \"$CERT_DIR/server.pem\" }, { \"name\": \"ssl_certificate_key\", \"value\": \"$CERT_DIR/server.key\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "DONE"
echo ""
