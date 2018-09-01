# A command line tool for managing Hadoop Cluster via Cloudera Manager API using Shell Script

## Overview

This tool is developed for ease of managing CDH cluster via Cloudera Manager API. Currently it supports:

* Generate SSL/TLS Certificates
* Enable SSL/TLS for Cloudera Manager
* Enable SSL/TLS for below CDH components (other services will be added in the near future):
  * hdfs
  * yarn
  * hive
  * impala
  * oozie
  * hbase
  * hue

## How to use the tool

This tool needs to be run from a host within the cluster, ideally the Cloudera Manager server host. 

It uses SSH to run commands remotely to generate certificates and update agent configuration files using
"root" user, because we need to update and restart services that requires "root" privilege, so to avoid 
being asked to enter passwords, it is advised to have passwordless setup from the host you want to run 
the tool to all other hosts. 

This can be achieved by:

```bash
ssh-keygen
ssh-copy-id root@host1
ssh-copy-id root@host2
ssh-copy-id root@host3
```

To enable SSL/TLS for the cluster, there are three steps:

* Generate certificates on each host:
  
  ```bash
    bash ssl/cert-install.sh CM_HOST TLS_ENABLED TYPE
    
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0"
    TYPE:        Either "ca" for CA Signed Certificate or "self" for Self-Signed Certificate
  ```
  
  If you choose to generate Self-Signed certificates, this script will generate Java KeyStore, 
  Private Key and Public Key files automatically and save them to /opt/cloudera/security/jks directory.
  
  If you choose to generate Internal CA Signed Certificates, it requires that you already have 
  Root CA (rootca.pem) and Intermediate CA (intca-x.pem) certificates under the "ssl/ca" directory 
  at the root of project directory. 
  
  It will display you with the Public Key output and you will need to generate the Certificate 
  file from your Internal CA system, copy and paste the result into the script output when prompted. 
  This process need to be done per host, so please be patient.
  
* Update Cloudera Manager Server and Agent Configuration to enable SSL/TLS
  
  ```bash
    bash ssl/cm/enable.sh CM_HOST TLS_ENABLED
  
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0"
  ```
  
  This script will update CM server and agent configurations to enable SSL/TLS, 
  restart all CM agent and server processes automatically.
  
  It assumes that the SSL Certificates are generated from first step.
   
* Update CDH configurations in Cloudera Manager to enable SSL for each services

  ```bash
    bash ssl/cdh/enable.sh CM_HOST TLS_ENABLED
    
    CM_HOST:     Cloudera Manager Host URL, without port number"
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0"
  ```
   
  This script will automatically detect the number of clusters and services managed by Cloudera Manager and 
  will ask you to choose which cluster and services you want to enable SSL for. 
  
  After configurations are updated, it will go ahead to restart the cluster at the end.
  
  It also assumes that the SSL Certificates are generated from first step.
  