#!/bin/bash
# Attend Elasticsearch puis fixe le mot de passe du user kibana_system
# a la valeur de KIBANA_PASSWORD (injectee via .env / compose).

set -euo pipefail

echo "=== Attente d Elasticsearch ==="

until curl -s --cacert /certs/ca/ca.crt \
  -u "elastic:${ELASTIC_PASSWORD}" \
  https://ELASTICS:9200 | grep -q "cluster_name"; do
  sleep 5
done

echo "=== Definition du mot de passe kibana_system ==="

until curl -s -X POST \
  --cacert /certs/ca/ca.crt \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -H "Content-Type: application/json" \
  https://ELASTICS:9200/_security/user/kibana_system/_password \
  -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do
  sleep 5
done

echo "=== Mot de passe kibana_system configure ==="
