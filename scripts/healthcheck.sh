#!/usr/bin/env bash
# =====================================================================
# Kiem tra suc khoe toan bo stack - dung cho cron hoac kiem thu
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

SERVER_NAME="${SERVER_NAME:-shop.local}"
SCHEME="https"
[[ "${NGINX_HTTPS_PORT:-443}" == "443" ]] && PORT="" || PORT=":${NGINX_HTTPS_PORT}"
BASE="${SCHEME}://${SERVER_NAME}${PORT}"

FAIL=0
check() {
    local label="$1" url="$2" expect="$3"
    local code
    code="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$url" || echo 000)"
    if [[ "$code" == "$expect" ]]; then
        printf "  [OK]   %-28s %s -> %s\n" "$label" "$url" "$code"
    else
        printf "  [FAIL] %-28s %s -> %s (mong doi %s)\n" "$label" "$url" "$code" "$expect"
        FAIL=$((FAIL + 1))
    fi
}

echo "== Trang thai container =="
docker compose ps --format 'table {{.Name}}\t{{.Status}}'

echo
echo "== Endpoint qua Nginx (Host: ${SERVER_NAME}) =="
check "Website (HTTPS)"   "${BASE}/"                      200
check "Health endpoint"   "${BASE}/healthz"               200
check "phpMyAdmin"        "${BASE}/phpmyadmin/"           200
check "Grafana"           "${BASE}/grafana/login"         200
check "Prometheus (no)"   "http://127.0.0.1:${PROMETHEUS_PORT:-9090}/-/healthy"  200

echo
echo "== Prometheus targets =="
curl -sk --max-time 10 "http://127.0.0.1:${PROMETHEUS_PORT:-9090}/api/v1/targets?state=active" \
    | grep -o '"health":"[a-z]*"' | sort | uniq -c || true

echo
if [[ "$FAIL" -eq 0 ]]; then
    echo "KET QUA: TAT CA DAT"
    exit 0
else
    echo "KET QUA: ${FAIL} endpoint loi"
    exit 1
fi
