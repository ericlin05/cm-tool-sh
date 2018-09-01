#!/bin/bash

set -e

CM_HOST=$1
CLUSTER=$2
SERVICE=$3
TLS_ENABLED=$4

BASE_DIR=$(dirname $0)
source $BASE_DIR/../include.sh
source $BASE_DIR/../../../config.sh $CM_HOST $TLS_ENABLED

# https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_ssl_oozie.html

echo ""
echo "Updating Oozie SSL configurations"
echo "$API_URL/cm/config $CM_USER:$CM_PASS $INSECURE"
curl -s -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"oozie_use_ssl\", \"value\": \"true\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/config"

echo ""
echo "Updating Oozie Role Group to enable SSL"
ROLE_GROUP_ID=`curl -s -u $CM_USER:$CM_PASS $INSECURE "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups" | grep name | grep '\-OOZIE_SERVER\-' | sed -e 's/.*"\(.*OOZIE_SERVER.*\)".*/\1/g'`

curl -s -X PUT -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"items\": [ { \"name\": \"oozie_https_keystore_file\", \"value\": \"$CERT_DIR/server.jks\" }, { \"name\": \"oozie_https_truststore_file\", \"value\": \"$JAVA_HOME/jre/lib/security/jssecacerts\" }, { \"name\": \"oozie_https_keystore_password\", \"value\": \"$KEYSTORE_PASS\" }, { \"name\": \"oozie_https_truststore_password\", \"value\": \"$TRUSTSTORE_PASS\" } ] }" \
  "$API_URL/clusters/$CLUSTER/services/$SERVICE/roleConfigGroups/$ROLE_GROUP_ID/config"

echo ""
echo "DONE"
