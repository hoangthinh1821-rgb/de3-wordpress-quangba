#!/usr/bin/env bash
# =====================================================================
# Kiem chung Prometheus / Grafana / Loki  - dung lam minh chung bao cao
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

RESOLVE=(--resolve "${SERVER_NAME}:${NGINX_HTTPS_PORT:-443}:127.0.0.1")
BASE="https://${SERVER_NAME}"
[[ "${NGINX_HTTPS_PORT:-443}" == "443" ]] || BASE="https://${SERVER_NAME}:${NGINX_HTTPS_PORT}"
GF_AUTH=(-u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}")
PROM="http://127.0.0.1:${PROMETHEUS_PORT:-9090}"

echo "===== 1. Grafana /api/health ====="
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" "${BASE}/grafana/api/health"
echo

echo
echo "===== 2. Data source da nap ====="
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" "${BASE}/grafana/api/datasources" \
    | grep -oE '"uid":"[^"]+","name":"[^"]+","type":"[^"]+"' || echo "(khong doc duoc)"

echo
echo "===== 2b. Dashboard da nap ====="
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" "${BASE}/grafana/api/search?type=dash-db" \
    | grep -oE '"title":"[^"]+"' || echo "(khong co dashboard)"

echo
echo "===== 3. Loki qua proxy cua Grafana ====="
LOKI_UID="$(curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" \
    "${BASE}/grafana/api/datasources/name/Loki" \
    | grep -oE '"uid":"[^"]+"' | cut -d'"' -f4)"
echo "  (datasource uid = ${LOKI_UID:-khong tim thay})"
PROXY="${BASE}/grafana/api/datasources/proxy/uid/${LOKI_UID}"

echo
echo "  -> /ready:"
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" "${PROXY}/ready"
echo

echo
echo "===== 4. Loki - cac label dang co ====="
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" "${PROXY}/loki/api/v1/labels"
echo

echo
echo "===== 5. LogQL: 3 dong log nginx gan nhat ====="
curl -sk "${RESOLVE[@]}" "${GF_AUTH[@]}" -G "${PROXY}/loki/api/v1/query_range" \
    --data-urlencode 'query={container="de3-nginx"}' \
    --data-urlencode 'limit=3' | head -c 1200

echo
echo
echo "===== 6. PromQL: phan tram CPU ====="
curl -s -G "${PROM}/api/v1/query" \
    --data-urlencode 'query=100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)' \
    | head -c 400

echo
echo
echo "===== 7. PromQL: phan tram RAM ====="
curl -s -G "${PROM}/api/v1/query" \
    --data-urlencode 'query=(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100' \
    | head -c 400

echo
echo
echo "===== 8. PromQL: ket noi MySQL ====="
curl -s -G "${PROM}/api/v1/query" \
    --data-urlencode 'query=mysql_global_status_threads_connected' \
    | head -c 400
echo
