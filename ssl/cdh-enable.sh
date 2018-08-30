#!/bin/bash

HOST=$1
TLS_ENABLED=$2
CLUSTER_NAME=$3

BASE_DIR=$(dirname $0)
source $BASE_DIR/../config.sh $HOST $TLS_ENABLED

services=("hdfs" "yarn" "hue" "hive" "impala" "hbase" "oozie")
for service in ${services[@]}
do
  service_name=`curl -u $CM_USER:$CM_PASS "$API_URL/clusters/$CLUSTER_NAME/services" --insecure | grep roleInstancesUrl | cut -d '/' -f 6 | grep -P "^$service"`
  echo $service_name
  if [ -d $BASE_DIR/$service ]; then
    echo "Running bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_NAME $service_name $TLS_ENABLED"
    bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_NAME $service_name $TLS_ENABLED
  fi
done

echo ""
echo "Restarting Cluster"
curl -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
  -d "{ \"restartOnlyStaleServices\": \"true\", \"redeployClientConfiguration\": \"true\" }" \
  "$API_URL/clusters/$CLUSTER_NAME/commands/restart"

