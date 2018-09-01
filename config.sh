#!/usr/bin/env bash

set -e

host=$1
is_secure=$2

CM_USER="admin"
CM_PASS="admin"

if [ -z "$host" ]; then
  echo ""
  echo "No CM host URL provided!"
  echo ""
  exit 1
fi

CM_URL="http://$host:7180"
INSECURE=""

if [ $is_secure == 1 ]; then
  CM_URL="https://$host:7183"
  INSECURE=" --insecure"
fi

VERSION=`curl -s -u $CM_USER:$CM_PASS "$CM_URL/api/version" $INSECURE`
echo "API Version is: $VERSION"

API_URL="$CM_URL/api/$VERSION"
echo "API Url: $API_URL"

CLUSTER_HOSTS=(`curl -s -u $CM_USER:$CM_PASS "$API_URL/hosts" $INSECURE | grep 'hostname' | sed -e 's/.* : "\(.*\)".*/\1/g'`)

. /usr/bin/bigtop-detect-javahome

if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=`readlink -e /etc/alternatives/java | sed 's/\/jre\/bin\/java//g'`
fi 

CERT_DIR="/opt/cloudera/security/jks"
REMOTE_DIR="/tmp/certificate-install"

KEYSTORE_PASS="cloudera"
TRUSTSTORE_PASS="changeit"

# concatenated pem files from each host
CA_CERTIFICATE=ca-certificate.pem

SUPPORTED_SERVICES=("hdfs" "yarn" "hue" "hive" "impala" "hbase" "oozie")
