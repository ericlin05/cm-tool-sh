# A command line tool for managing Hadoop Cluster via CM API using Shell Script

## Overview

This tool is developed for ease of managing CDH cluster via Cloudera Manager API. Currently it supports:

* Enable SSL/TLS for Cloudera Manager
* Enable SSL/TLS for below CDH components (other services will be added in the near future):
  * hdfs
  * yarn
  * hive
  * impala
  * oozie
  * hbase
  * hue

## Usage

To enable SSL/TLS for the cluster, there are three steps:

* Generate certificates on each host:
  
  ```
    bash ssl/cert-install.sh CM_HOST TLS_ENABLED TYPE
    
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not"
    TYPE:        Either "ca" for CA Signed Certificate or "self" for Self-Signed Certificate"
  ```
  
  If you choose to generate Self-Signed certificates, this script will generate Java KeyStore, 
  Private Key and Public Key files automatically and save them to /opt/cloudera/security/jks directory.
  
  If you choose to generate Internal CA Signed Certificates, it requires that you already have 
  Root CA (rootca.pem) and Intermediate CA (intca-x.pem) certificates under the "ca" directory 
  at the root of project directory. 
  
  It will display you with the Public Key output and you will need to generate the Certificate 
  file from your Internal CA system, copy and paste the result into the script output when prompted. 
  This process need to be done per host, so please be patient.
  
* Update Cloudera Manager Server and Agent Configuration to enable SSL/TLS
  
  ```
    bash ssl/cm/enable.sh CM_HOST TLS_ENABLED
  
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not"
  ```
  
  This script will update CM server and agent configurations to enable SSL/TLS, 
  restart all CM agent and server processes automatically.
  
  It assumes that the SSL Certificates are generated from first step.
   
* Update CDH configurations in Cloudera Manager to enable SSL for each services

  ```
    bash ssl/cdh/enable.sh CM_HOST TLS_ENABLED
    
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not"
  ```
   
  This script will automatically detect the number of clusters and services managed by Cloudera Manager and 
  will ask you to choose which cluster and services you want to enable SSL for. 
  
  After configurations are updated, it will go ahead to restart the cluster at the end.
  
  It also assumes that the SSL Certificates are generated from first step.
  