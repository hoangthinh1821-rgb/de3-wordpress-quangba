#!/usr/bin/env bash
# =====================================================================
# Kiem tra suc khoe toan bo stack - dung cho cron hoac kiem thu
# Dung --resolve de khong can sua /etc/hosts tren may chu
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR" || exit 1

if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

SERVER_NAME="${SERVER_NAME:-shop.local}"
HTTPS_PORT="${NGINX_HTTPS_PORT:-443}"
PROM_PORT="${PROMETHEUS_PORT:-9090}"

if [[ "$HTTPS_PORT" == "443" ]]; then
    BASE="https://${SERVER_NAME}"
else
    BASE="https://${SERVER_NAME}:${HTTPS_PORT}"
fi

FAIL=0
# Kiem tra tren cong HTTP (phai tra 301)
check_http() {
    local label="$1" path="$2" expect="$3" code http_base
    http_base="http://${SERVER_NAME}"
    [[ "${NGINX_HTTP_PORT:-80}" == "80" ]] || http_base="${http_base}:${NGINX_HTTP_PORT}"
    code="$(curl -s --resolve "${SERVER_NAME}:${NGINX_HTTP_PORT:-80}:127.0.0.1" \
        -o /dev/null -w '%{http_code}' --max-time 10 "${http_base}${path}" || echo 000)"
    if [[ "$code" == "$expect" ]]; then
        printf "  [OK]   %-24s %-32s -> %s\n" "$label" "$path" "$code"
    else
        printf "  [FAIL] %-24s %-32s -> %s (mong doi %s)\n" "$label" "$path" "$code" "$expect"
        FAIL=$((FAIL + 1))
    fi
}

check() {
    local label="$1" path="$2" expect="$3"
    local code
    code="$(curl -sk --resolve "${SERVER_NAME}:${HTTPS_PORT}:127.0.0.1" \
        -o /dev/null -w '%{http_code}' --max-time 10 "${BASE}${path}" || echo 000)"
    if [[ "$code" == "$expect" ]]; then
        printf "  [OK]   %-24s %-32s -> %s\n" "$label" "$path" "$code"
    else
        printf "  [FAIL] %-24s %-32s -> %s (mong doi %s)\n" "$label" "$path" "$code" "$expect"
        FAIL=$((FAIL + 1))
    fi
}

echo "== Trang thai container =="
docker compose ps --format 'table {{.Name}}\t{{.Status}}'

echo
echo "== Endpoint qua Nginx (Host: ${SERVER_NAME}) =="
check_http "HTTP -> HTTPS" "/"               301
check "Website"           "/"                200
check "wp-admin"          "/wp-admin/"       302
check "Health endpoint"   "/healthz"         200
check "phpMyAdmin"        "/phpmyadmin/"     200
check "Grafana"           "/grafana/login"   200

echo
echo "== Prometheus (localhost) =="
PCODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:${PROM_PORT}/-/healthy" || echo 000)"
if [[ "$PCODE" == "200" ]]; then
    echo "  [OK]   Prometheus healthy -> 200"
else
    echo "  [FAIL] Prometheus healthy -> $PCODE"
    FAIL=$((FAIL + 1))
fi

echo
echo "== Prometheus targets =="
curl -s --max-time 10 "http://127.0.0.1:${PROM_PORT}/api/v1/targets?state=active" \
    | grep -o '"health":"[a-z]*"' | sort | uniq -c || echo "  (khong doc duoc API)"

echo
if [[ "$FAIL" -eq 0 ]]; then
    echo "KET QUA: TAT CA DAT"
    exit 0
else
    echo "KET QUA: ${FAIL} muc loi"
    exit 1
fi
