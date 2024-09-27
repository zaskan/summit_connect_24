#!/bin/bash

# Set a single password for both keystore and key
CERT_PASSWORD="kafkacertpass"

# Generate CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -keyout ca.key -out ca.crt -subj "/CN=CA" -addext "subjectAltName = DNS:ca"

# Generate server certificate
cat > server.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = kafka

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = kafka
DNS.2 = localhost
EOF

openssl req -newkey rsa:4096 -nodes -keyout server.key -out server.csr -config server.conf
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -extfile server.conf -extensions v3_req

# Generate client certificate
cat > client.conf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = client

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = client
EOF

openssl req -newkey rsa:4096 -nodes -keyout client.key -out client.csr -config client.conf
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -extfile client.conf -extensions v3_req

# Create truststore
keytool -importcert -alias ca -file ca.crt -keystore kafka.truststore.jks -storepass $CERT_PASSWORD -noprompt

# Create keystore
openssl pkcs12 -export -in server.crt -inkey server.key -out kafka.p12 -name kafka -CAfile ca.crt -caname ca -passout pass:$CERT_PASSWORD

keytool -importkeystore -srckeystore kafka.p12 -srcstoretype PKCS12 -destkeystore kafka.keystore.jks -deststorepass $CERT_PASSWORD -srcstorepass $CERT_PASSWORD -noprompt
