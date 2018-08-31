#!/bin/bash

# this will force this script to exit if any of the commands failed
set -e

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
  echo ""
  echo "Usage: bash cert-gen.sh TYPE"
  echo "  TYPE: either \"ca\" for CA Signed Certificate or \"self\" for Self-Signed Certificate"
  echo ""
  exit
fi

TYPE="$1"

BASE_DIR=$(dirname $0)
CA_DIR=$BASE_DIR/ca
source $BASE_DIR/../config.sh ""

echo "Extracting Java Home path at: $JAVA_HOME"

# default to generating self-signed certificates
if [ "$TYPE" == '' ] || ( [ "$TYPE" != 'self' ] && [ "$TYPE" != 'ca' ] ); then
  TYPE='self'
fi

generate_ca_signed()
{
  echo ""
  echo "Copying Root and Intermidate CA certificates to $CERT_DIR"
  cp $CA_DIR/*.pem $CERT_DIR

  echo ""
  echo "Generating certificate signing request to file: $CERT_DIR/$(hostname -f).csr"
  $JAVA_HOME/bin/keytool -certreq -alias $(hostname -f) -keystore $CERT_DIR/$(hostname -f).jks \
    -file $CERT_DIR/$(hostname -f).csr -ext san=dns:$(hostname -f) -storepass cloudera
  
  echo ""
  echo "Please copy and paste below certificate signing request to your CA and generate a signed certificate,"
  echo "and then paste the content below, so that we can validate and move forward"
  echo ""
  cat $CERT_DIR/$(hostname -f).csr
  echo ""
  echo "Once done, download the certificate, please copy and paste the certificate below:"
  echo "Ctrl-d to continue"
  echo ""
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
    echo "Please re-submit your certificate signing request and start the process again"
    exit 1;
  fi
  
  echo ""
  echo "Importing the root CA certificate into the JDK truststore"
  $JAVA_HOME/bin/keytool -importcert -alias rootca -keystore $JAVA_HOME/jre/lib/security/jssecacerts \
    -file $CERT_DIR/rootca.pem -storepass changeit -noprompt
  
  echo ""
  echo "Appending the intermediate CA certificate to the signed host certificate: $CERT_DIR/$(hostname -f).pem"
  for cert_file in `ls $CERT_DIR/intca*.pem`
  do
    cat $cert_file >> $CERT_DIR/$(hostname -f).pem
  done
  
  echo "Importing it into the keystore: $CERT_DIR/$(hostname -f).jks"
  $JAVA_HOME/bin/keytool -importcert -alias $(hostname -f) -file $CERT_DIR/$(hostname -f).pem \
    -keystore $CERT_DIR/$(hostname -f).jks -storepass $KEYSTORE_PASS -noprompt
}

generate_self_signed()
{
  echo ""
  echo "Generating certificate from keystore file"
  $JAVA_HOME/bin/keytool -export -alias $(hostname -f) -keystore $CERT_DIR/$(hostname -f).jks \
    -rfc -file $CERT_DIR/$(hostname -f).pem -storepass $KEYSTORE_PASS;

  echo ""
  echo "Importing certificate file into Java truststore under $JAVA_HOME/jre/lib/security/jssecacerts"
  # Import the public cert into the java trust store, so that anything that runs with java on this machine will trust our key. Repeat on all machines.
  $JAVA_HOME/bin/keytool -import -alias $(hostname -f) -file $CERT_DIR/$(hostname -f).pem \
    -trustcacerts -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass $TRUSTSTORE_PASS -noprompt;
}

########################################################################################
# Main logic starts here
########################################################################################

# make sure we start with clean cerficates
if [ -d $CERT_DIR ]; then
  echo ""
  echo "$CERT_DIR already exists, removing it"
  rm -fr $CERT_DIR
fi 

mkdir -p $CERT_DIR

echo ""
echo "======================================================================================================"
echo "Generating Java KeyStore to file: $CERT_DIR/$(hostname -f).jks"
keytool -genkeypair -alias $(hostname -f) -keyalg RSA -keystore $CERT_DIR/$(hostname -f).jks \
  -keysize 2048 -dname "CN=$(hostname -f),OU=Support,O=Cloudera,L=Melbourne,ST=Victoria,C=AU" \
  -ext san=dns:$(hostname -f) -storepass $KEYSTORE_PASS -keypass $KEYSTORE_PASS

# Copy the JDK cacerts file to jssecacerts as follows
# The Oracle JDK uses the jssecacerts file for its default truststore if it exists. 
# Otherwise, it uses the cacerts file. Creating the jssecacerts file allows you to trust 
# an internal CA without modifying the cacerts file that is included with the JDK.
echo ""
echo "Copying the JDK cacerts file to jssecacerts under: $JAVA_HOME/jre/lib/security"
cp $JAVA_HOME/jre/lib/security/cacerts $JAVA_HOME/jre/lib/security/jssecacerts
  
if [ $TYPE == "ca" ]; then
  generate_ca_signed
else
  generate_self_signed
fi

echo ""
echo "Creating symbolic links (symlink) for the certificate and keystore files: "
echo "Certificate: $CERT_DIR/server.pem"
echo "Keystore: $CERT_DIR/server.jks"
ln -s $CERT_DIR/$(hostname -f).pem $CERT_DIR/server.pem
ln -s $CERT_DIR/$(hostname -f).jks $CERT_DIR/server.jks

# Now need to convert jks to pem
# https://www.cloudera.com/documentation/enterprise/latest/topics/cm_sg_openssl_jks.html#concept_ek3_sdl_rp
# 1. Export the private key and certificate command line:
echo ""
echo "Generating private key file from keystore"
keytool -importkeystore -srckeystore $CERT_DIR/server.jks \
-srcstorepass $KEYSTORE_PASS -srckeypass $KEYSTORE_PASS -destkeystore $CERT_DIR/$(hostname -f).p12 \
-deststoretype PKCS12 -srcalias $(hostname -f) -deststorepass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS

# 2. Extract the certificate file from the resulting PKCS12 file:
# openssl pkcs12 -in $CERT_DIR/$(hostname -f).p12 -passin pass:$KEYSTORE_PASS  -nokeys \
# -out $CERT_DIR/test.pem

# 3. Use OpenSSL to extract the private key from the PKCS keystore when needed. 
# The command shown below extracts the key and saves it to a keystore that is protected using the password you provide:
openssl pkcs12 -in $CERT_DIR/$(hostname -f).p12 -passin pass:$KEYSTORE_PASS \
   -nocerts -out $CERT_DIR/$(hostname -f).key -passout pass:$KEYSTORE_PASS

echo ""
echo "And creating symlink for $CERT_DIR/server.key"
ln -s $CERT_DIR/$(hostname -f).key $CERT_DIR/server.key

echo "======================================================================================================"
echo ""
