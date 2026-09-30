#!/bin/bash
# Génère les certificats TLS (CA, Elasticsearch, Kibana) dans /certs.
# Idempotent : ne régénère rien si /certs/ca/ca.crt existe déjà.

set -euo pipefail

echo "=== Preparation des certificats ==="

mkdir -p /certs
chmod 755 /certs

if [ ! -f /certs/ca/ca.crt ]; then

  echo "=== Generation de la CA ==="

  "${CERTUTIL}" ca \
    --silent \
    --pem \
    -out /certs/ca.zip

  unzip -o /certs/ca.zip -d /certs


  echo "=== Generation du certificat Elasticsearch ==="
  # Les --dns / --ip doivent matcher les hostnames clients (ELASTICS, localhost, IP lab…)

  "${CERTUTIL}" cert \
    --silent \
    --pem \
    --ca-cert /certs/ca/ca.crt \
    --ca-key /certs/ca/ca.key \
    --name elasticsearch \
    --dns elasticsearch \
    --dns ELASTICS \
    --dns ELASTIC-SIEM-BT \
    --dns localhost \
    --ip 127.0.0.1 \
    --ip 192.168.10.11 \
    -out /certs/elasticsearch.zip

  unzip -o /certs/elasticsearch.zip -d /certs


  echo "=== Generation du certificat Kibana ==="
  # Inclut le hostname Docker KIBANA (utilise par Filebeat)

  "${CERTUTIL}" cert \
    --silent \
    --pem \
    --ca-cert /certs/ca/ca.crt \
    --ca-key /certs/ca/ca.key \
    --name kibana \
    --dns kibana \
    --dns KIBANA \
    --dns KIBANA-SIEM-BT \
    --dns localhost \
    --ip 127.0.0.1 \
    -out /certs/kibana.zip

  unzip -o /certs/kibana.zip -d /certs


  echo "=== Correction des permissions ==="

  # uid 1000 = user elasticsearch / kibana dans les images officielles
  chown -R 1000:0 /certs
  find /certs -type d -exec chmod 755 {} \;
  find /certs -type f -exec chmod 644 {} \;
  find /certs -name "*.key" -exec chmod 640 {} \;

  echo "=== Certificats generes avec succes ==="

else

  echo "=== Certificats deja presents, rien a faire ==="

fi
