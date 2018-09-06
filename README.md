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

**This tool needs to be run on the Cloudera Manager server host, running on Agent hosts has not been tested.** 

It uses Unix's "curl" command to communicate with Cloudera Manager API, so it must be installed. 

It uses SSH to run commands remotely to generate certificates and update agent configuration files using
"root" user, because we need to update and restart services that requires "root" privilege, so to avoid 
being asked to enter passwords, it is advised to have passwordless setup from the host you want to run 
the tool to all other hosts. 

I have provided a simple setup script to do this for you:

```bash
bash setup.sh CM_HOST TLS_ENABLED

CM_HOST:     Cloudera Manager Host URL, without port number
TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0
```

Above script will help you to generate the public/private key pair on the CM host and then copy the IDs 
to the remote server to setup.

To enable SSL/TLS for the cluster, there are three steps:

* Generate certificates on each host:
  
  ```bash
    bash ssl/cert-install.sh CM_HOST TLS_ENABLED TYPE
    
    CM_HOST:     Cloudera Manager Host URL, without port number
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0
    TYPE:        Either "ca" for CA Signed Certificate or "self" for Self-Signed Certificate
  ```
  
  If you choose to generate Self-Signed certificates, this script will generate Java KeyStore, 
  Private Key and Public Key files automatically and save them to /opt/cloudera/security/jks directory.
  
  If you choose to generate Internal CA Signed Certificates, it requires that you already have 
  Root CA (rootca.pem) and Intermediate CA (intca-x.pem) certificates under the "ssl/ca" directory 
  at the root of project directory. 
  
  It will display you with the Public Key output and you will need to generate the Certificate 
  file from your Internal CA system, copy and paste the result into the script output when prompted. 
  This process needs to be done per host, so please be patient.
  
* Update Cloudera Manager Server and Agent Configuration to enable SSL/TLS
  
  ```bash
    bash ssl/cm/enable.sh CM_HOST TLS_ENABLED
  
    CM_HOST:     Cloudera Manager Host URL, without port number
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0
  ```
  
  This script will update CM server and agent configurations to enable SSL/TLS, 
  restart all CM agents, server and management services processes automatically.
  
  It assumes that the SSL Certificates are generated from first step.
   
* Update CDH configurations in Cloudera Manager to enable SSL for each services

  ```bash
    bash ssl/cdh/enable.sh CM_HOST TLS_ENABLED
    
    CM_HOST:     Cloudera Manager Host URL, without port number
    TLS_ENABLED: Whether the current Cloudera Manager already has TLS enabled or not, 1 or 0
  ```
   
  This script will automatically detect the number of clusters and services managed by Cloudera Manager and 
  will ask you to choose which cluster and services you want to enable SSL for. 
  
  After configurations are updated, it will go ahead to restart the cluster at the end.
  
  It also assumes that the SSL Certificates are generated from first step.
 
 ## Known Issues & Limitations
 
 * Relies on **/usr/bin/bigtop-detect-javahome** to detect JAVA_HOME
 * Need to be run on Cloudera Manager host
 * Manual step required for Hue to connect to Impala & HiveServer2, please refer to below links:
   * [Enabling Hue TLS/SSL Communication with HiveServer2](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_ssl_hue.html#concept_lxw_cyf_jr)
   * [Enabling Hue TLS/SSL Communication with Impala](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_ssl_hue.html#concept_cfy_3dl_zt)
 
 ## TODOs
 * Support disablement of SSL/TLS for any service
 * Support SSL/TLS for other CDH components
 * Support enabling HA services for various CDH components
 * Support enabling Kerberos for CDH
 * Support enabling Sentry for various CDH components
 * More to come... 
 