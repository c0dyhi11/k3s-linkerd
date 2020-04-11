#!/bin/bash
ROOT_DIR='${ROOT_DIR}'
COUNTRY='${COUNTRY}'
STATE='${STATE}'
CITY='${CITY}'
ORG='${ORG}'
UNIT='${UNIT}'
DOMAIN='${DOMAIN}'

cd $ROOT_DIR
touch index.txt
echo 1000 > serial

openssl ecparam -name prime256v1 -genkey -noout -out ca.key.pem
chmod 400 ca.key.pem

openssl req -x509 -new -nodes -key ca.key.pem \
    -sha256 -days 7300 -out ca.cert.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$UNIT/CN=$DOMAIN"

chmod 444 ca.cert.pem

mkdir -p intermediate/cert intermediate/csr intermediate/key
