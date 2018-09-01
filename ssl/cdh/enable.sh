#!/bin/bash

set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash enable.sh CM_HOST TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not"
  echo ""
  exit
fi

HOST=$1
TLS_ENABLED=$2

NUMBER_REGEXP='^[0-9]$'

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh $HOST $TLS_ENABLED

# checking the list of available clusters
clusters=(`curl -s -u $CM_USER:$CM_PASS "$API_URL/clusters" $INSECURE | grep '"name"' | sed -e 's/.*"\(.*\)".*/\1/g'`)

echo "I have detected following clusters:"
echo ""
tLen=${#clusters[@]}
for (( i=0; i<${tLen}; i++ ));
do
  a=$(( i+1 ))
  echo "$a) ${clusters[$i]}" 
done

# if there are more than 1 clusters, ask user to select one
if [ $tLen -gt 1 ]; then
  echo ""
  echo -n "Please select which one to use: "
  read choice
  
  while ( ! [[ "$choice" =~ ${NUMBER_REGEXP} ]] ) || [ $choice -gt $tLen ] || [ $choice -lt 1 ]
  do
    echo -n "Bad input, try again (integer please): "
    read choice
  done
  
  choice=$(( choice-1 ))
  CLUSTER_NAME=${clusters[$choice]}
else
# otherwise, use the one available
  CLUSTER_NAME=${clusters[0]}
fi

echo ""
echo -n "You have selected to update cluster \"$CLUSTER_NAME\" to enable SSL, please confirm (yes or no): "
read confirm

if [ "$confirm" != "yes" ]; then
  echo ""
  echo "You decided to abort, bye"
  echo ""
  exit 0
fi

# retrieving the list of available services in the cluster chosen
# so that we can ask user to choose from
available_services=(`curl -s -u $CM_USER:$CM_PASS "$API_URL/clusters/$CLUSTER_NAME/services" $INSECURE | grep '"serviceUrl"' | sed -e 's@.*/\(.*\)".*@\1@g'`)

echo "I have detected following services available for cluster \"$CLUSTER_NAME\":"

i=0
# the final list of services to be enabled with SSL
services=()
for service in ${available_services[@]}
do
  for s_service in ${SUPPORTED_SERVICES[@]}
  do
    # checking if the supported service is in the list
    m=`echo $service | grep "^$s_service" | wc -l`
    if [ "$m" == "1" ]; then
      services[$i]=$s_service
      i=$(( i+1 ))
    fi
  done
done

# printing out the choices available
echo ""
tLen=${#services[@]}
for (( i=0; i<${tLen}; i++ ));
do
  a=$(( i+1 ))
  echo "$a) ${services[$i]}" 
done

a=$(( i+1 ))
echo "$a) all"

echo ""
echo -n "Please select which service to use: "
read choice

choiceLimit=$(( tLen+1 ))
while ( ! [[ $choice =~ ${NUMBER_REGEXP} ]] ) || [ $choice -gt $choiceLimit ] || [ $choice -lt 1 ]
do
  echo -n "Bad input, try again (integer please): "
  read choice
done

if [ $choice -eq $choiceLimit ]; then
  CHOSEN_SERVICES=${services[@]}
else
  choice=$(( choice-1 ))
  CHOSEN_SERVICES=(${services[$choice]})
fi

echo ""
echo ${CHOSEN_SERVICES[*]}
echo ""
echo -n "You have chosen to enable SSL/TLS for above service(s) (yes or no): "
read confirm

if [ "$confirm" != "yes" ]; then
  echo ""
  echo "You decided to abort, bye"
  echo ""
  exit 0
fi

for service in ${CHOSEN_SERVICES[@]}
do
  echo $service
  if [ -d $BASE_DIR/$service ]; then
    echo "Running bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_NAME $service $TLS_ENABLED"
    bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_NAME $service $TLS_ENABLED
  fi
done

if [ ${#CHOSEN_SERVICES[@]} -eq 1 ]; then
  echo ""
  echo "Restarting Service ${CHOSEN_SERVICES[0]}"
  curl -s -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
    "$API_URL/clusters/$CLUSTER_NAME/services/$service/commands/restart"
else
  echo ""
  echo "Restarting Cluster"
  curl -s -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
    -d "{ \"restartOnlyStaleServices\": \"true\", \"redeployClientConfiguration\": \"true\" }" \
    "$API_URL/clusters/$CLUSTER_NAME/commands/restart"
fi

echo "DONE"
