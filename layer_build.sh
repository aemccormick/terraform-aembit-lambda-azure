#! /bin/bash

rm -rf build
mkdir build

# Get Python Requests package certificates
CERTIFI_URL="https://raw.githubusercontent.com/certifi/python-certifi/master/certifi/cacert.pem"
curl -fsSL "$CERTIFI_URL" -o build/cacert.pem

# Get Tenant Root CA
curl "https://${AEMBIT_TENANT_ID}.aembit.io/api/v1/root-ca" >> build/cacert.pem

mkdir -p artifacts

# Zip up trust bundle
(cd build && zip ../artifacts/trustbundle.zip cacert.pem)

# Remove build artifacts
rm build/cacert.pem
