#!/bin/bash

# this will force this script to exit if any of the commands failed
set -e

TYPE="$1"

BASE_DIR=$(dirname $0)
source $BASE_DIR/../../config.sh ""

echo "Extracting Java Home path at: $JAVA_HOME"

if [ $TYPE == '' ] || [ $TYPE != 'self' ] || [ $TYPE != 'ca' ]; then
  TYPE='self'
fi

generate_ca_signed()
{
  echo ""
  echo "Generating certificate signing request to file: $CERT_DIR/$(hostname -f).csr"
  keytool -certreq -alias $(hostname -f) -keystore $CERT_DIR/$(hostname -f).jks -file $CERT_DIR/$(hostname -f).csr -ext san=dns:$(hostname -f) -storepass cloudera
  
  echo ""
  cat $CERT_DIR/$(hostname -f).csr
  echo ""
  echo "Once done, download the certificate, please copy and paste the certificate below:"
  echo "Ctrl-d to continue"
  certificate=$(cat)
  
  echo ""
  echo "The certificate you entered was:"
  echo "$certificate"
  echo ""
  echo "Saving to $CERT_DIR/$(hostname -f).pem" 
  echo "$certificate" > $CERT_DIR/$(hostname -f).pem
  
  # Inspect the signed certificate to verify that both server and client authentication options are present
  echo ""
  echo "Verifying that the certificate has 'TLS Web Server Authentication and 'TLS Web Client Authentication' entries:"
  c=`openssl x509 -in $CERT_DIR/$(hostname -f).pem -noout -text | grep 'TLS Web Server Authentication' | grep 'TLS Web Client Authentication' | wc -l`
  echo "Verified"
  
  if [ $c -eq "0" ]; then
    echo "Valication failed, unable to find section for 'TLS Web Server Authentication' or 'TLS Web Client Authentication'"
    echo "Please re-submit your certificate signing request"
    exit 1;
  fi
  
  echo ""
  echo "Importing the root CA certificate into the JDK truststore"
  $JAVA_HOME/bin/keytool -importcert -alias rootca -keystore $JAVA_HOME/jre/lib/security/jssecacerts -file $CERT_DIR/rootca.pem -storepass changeit -noprompt
  
  echo ""
  echo "Appending the intermediate CA certificate to the signed host certificate: $CERT_DIR/$(hostname -f).pem"
  cat $CERT_DIR/intca.pem >> $CERT_DIR/$(hostname -f).pem
  
  echo "Importing it into the keystore: $CERT_DIR/$(hostname -f).jks"
  $JAVA_HOME/bin/keytool -importcert -alias $(hostname -f) -file $CERT_DIR/$(hostname -f).pem -keystore $CERT_DIR/$(hostname -f).jks -storepass cloudera -noprompt
  
}

generate_self_signed()
{
  if [ ! -f $CERT_DIR/$(hostname -f).pem ]; then
    keytool -export -alias $(hostname -f) -keystore $CERT_DIR/$(hostname -f).jks -rfc -file $CERT_DIR/$(hostname -f).pem -storepass $KEYSTORE_PASS;

    echo ""
    # Import the public cert into the java trust store, so that anything that runs with 
    # java on this machine will trust our key. Repeat on all machines.
    keytool -import -alias $(hostname -f) -file $CERT_DIR/$(hostname -f).pem -trustcacerts -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass changeit -noprompt;
  fi
  
}

########################################################################################
# Main logic starts here
########################################################################################

echo ""

# create directory is not exists yet
mkdir -p $CERT_DIR

if [ ! -f $CERT_DIR/$(hostname -f).jks ]; then
  echo ""
  echo "Generating Java KeyStore to file: $CERT_DIR/$(hostname -f).jks"
  keytool -genkeypair -alias $(hostname -f) -keyalg RSA -keystore $CERT_DIR/$(hostname -f).jks -keysize 2048 -dname "CN=$(hostname -f),OU=Support,O=Cloudera,L=Melbourne,ST=Victoria,C=AU" -ext san=dns:$(hostname -f) -storepass $KEYSTORE_PASS -keypass $TRUSTSTORE_PASS
fi

# Create the truststore based on default cacerts if not created yet
if [ ! -f $JAVA_HOME/jre/lib/security/jssecacerts ]; then
  # Copy the JDK cacerts file to jssecacerts as follows
  # The Oracle JDK uses the jssecacerts file for its default truststore if it exists.
  # Otherwise, it uses the cacerts file. Creating the jssecacerts file allows you to trust
  # an internal CA without modifying the cacerts file that is included with the JDK.
  echo ""
  echo "Copying the JDK cacerts file to jssecacerts under: $JAVA_HOME/jre/lib/security"
  /bin/cp $JAVA_HOME/jre/lib/security/cacerts $JAVA_HOME/jre/lib/security/jssecacerts
fi
  
if [ $TYPE == "ca" ]; then
  generate_ca_signed
else
  generate_self_signed
fi

echo ""
echo "DONE"
