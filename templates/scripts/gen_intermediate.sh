#!/bin/bash
ROOT_DIR='${ROOT_DIR}'
COUNTRY='${COUNTRY}'
STATE='${STATE}'
CITY='${CITY}'
ORG='${ORG}'
UNIT='${UNIT}'
DOMAIN='${DOMAIN}'
INTERMEDIATE_NAME="$1"


cd $ROOT_DIR
pwd
openssl ecparam -name prime256v1 -genkey \
    -noout -out intermediate/key/$INTERMEDIATE_NAME.key.pem
chmod 400 intermediate/key/$INTERMEDIATE_NAME.key.pem

openssl req -new -sha256 \
    -key intermediate/key/$INTERMEDIATE_NAME.key.pem \
    -out intermediate/csr/$INTERMEDIATE_NAME.csr.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$UNIT/CN=identity.linkerd.$INTERMEDIATE_NAME.$DOMAIN"

openssl ca -batch -config openssl.cnf -notext \
    -cert ca.cert.pem -keyfile ca.key.pem \
    -days 3650 -in intermediate/csr/$INTERMEDIATE_NAME.csr.pem \
    -out intermediate/cert/$INTERMEDIATE_NAME.cert.pem
chmod 444 intermediate/cert/$INTERMEDIATE_NAME.cert.pem
