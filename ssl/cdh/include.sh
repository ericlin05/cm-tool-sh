#!/usr/bin/env bash

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash update-cm-config.sh CM_HOST CLUSTER SERVICE TLS_ENABLED"
  echo "  CM_HOST:     Cloudera Manager Host URL, without port number"
  echo "  CLUSTER:     The name of the cluster to update"
  echo "  SERVICE:     The service to update, values can be hive, impala, hdfs etc"
  echo "  TLS_ENABLED: Whether Cloudera Manager already has TLS enabled or not, "
  echo "               used to determine the URL to use"
  echo ""
  exit
fi
