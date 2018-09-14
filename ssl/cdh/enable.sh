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
clusters=(`curl -s -S -u $CM_USER:$CM_PASS "$API_URL/clusters" $INSECURE | grep clusterUrl | sed -e 's#.*clusterRedirect/\(.*\)",#\1#g'`)

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

# The URL's space is %20
CLUSTER_URL_NAME=`echo $CLUSTER_NAME | sed -e 's/+/%20/g'`

# remove "+" so that we display proper name
CLUSTER_NAME=`echo $CLUSTER_NAME | sed -e 's/+/ /g'`

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
available_services=(`curl -s -S -u $CM_USER:$CM_PASS "$API_URL/clusters/$CLUSTER_URL_NAME/services" $INSECURE | grep '"serviceUrl"' | sed -e 's@.*/\(.*\)".*@\1@g'`)

echo "I have detected following services available for cluster \"$CLUSTER_NAME\":"

# the final list of services to be enabled with SSL
declare -A services
for service in ${available_services[@]}
do
  for s_service in ${SUPPORTED_SERVICES[@]}
  do
    # checking if the supported service is in the list
    m=`echo $service | grep -i "^$s_service" | wc -l`
    if [ "$m" == "1" ]; then
      services[$s_service]=$service
    fi
  done
done

# printing out the choices available
echo ""
for key in ${!services[@]}
do
  echo "$key"
done

echo "all"

echo ""
echo -n "Please select which service to use: "
read choice

while [ -z ${services["$choice"]} ] && [ "$choice" != "all" ]
do
  echo -n "Bad input, try again: "
  read choice
done

declare -A CHOSEN_SERVICES
if [ "$choice" == "all" ]; then
  for key in ${!services[@]}
  do
    CHOSEN_SERVICES[$key]=${services[$key]}
  done
else
  CHOSEN_SERVICES["$choice"]=${services["$choice"]}
fi

echo ""
echo ${!CHOSEN_SERVICES[@]}
echo ""
echo -n "You have chosen to enable SSL/TLS for above service(s) (yes or no): "
read confirm

if [ "$confirm" != "yes" ]; then
  echo ""
  echo "You decided to abort, bye"
  echo ""
  exit 0
fi

num_services=0
for service in ${!CHOSEN_SERVICES[@]}
do
  if [ -d $BASE_DIR/$service ]; then
    echo ""
    echo "##############################################################"
    echo "Updating $service.."
    echo "Running bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_URL_NAME ${CHOSEN_SERVICES[$service]} $TLS_ENABLED"
    bash $BASE_DIR/$service/update-cm-config.sh $HOST $CLUSTER_URL_NAME ${CHOSEN_SERVICES[$service]} $TLS_ENABLED
    echo "##############################################################"
    echo ""

    num_services=$(( num_services+1 ))
  fi
done

if [ $num_services -eq 1 ]; then
  echo ""
  echo "Restarting Service ${CHOSEN_SERVICES[$choice]}"
  curl -s -S -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
    "$API_URL/clusters/$CLUSTER_URL_NAME/services/$service/commands/restart"
else
  echo ""
  echo "Restarting Cluster"
  curl -s -S -X POST -H "Content-Type:application/json" -u $CM_USER:$CM_PASS $INSECURE \
    -d "{ \"restartOnlyStaleServices\": \"true\", \"redeployClientConfiguration\": \"true\" }" \
    "$API_URL/clusters/$CLUSTER_URL_NAME/commands/restart"
fi

echo "DONE"
