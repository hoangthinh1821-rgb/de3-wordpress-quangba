#!/usr/bin/env bash
# =====================================================================
# Hoan tat cai dat WordPress qua HTTP (khong can giao dien)
# Tao tai khoan admin trong .env (WP_ADMIN_USER / WP_ADMIN_PASSWORD)
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

# Sinh mat khau admin neu chua co
if ! grep -q '^WP_ADMIN_PASSWORD=' .env; then
    {
        echo "WP_ADMIN_USER=admin"
        echo "WP_ADMIN_PASSWORD=$(openssl rand -hex 12)"
    } >> .env
    echo "[install] Da them tai khoan admin vao .env"
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

RESOLVE=(--resolve "${SERVER_NAME}:${NGINX_HTTPS_PORT:-443}:127.0.0.1")
BASE="https://${SERVER_NAME}"
[[ "${NGINX_HTTPS_PORT:-443}" == "443" ]] || BASE="https://${SERVER_NAME}:${NGINX_HTTPS_PORT}"

# Da cai dat chua? (/wp-admin/install.php tra 302 khi da cai)
CODE="$(curl -sk "${RESOLVE[@]}" -o /dev/null -w '%{http_code}' "${BASE}/wp-admin/install.php" || echo 000)"
if [[ "$CODE" == "302" ]]; then
    echo "[install] WordPress da duoc cai dat truoc do."
else
    echo "[install] Dang cai dat WordPress (HTTP $CODE) ..."
    curl -sk "${RESOLVE[@]}" -X POST "${BASE}/wp-admin/install.php?step=2" \
        --data-urlencode "weblog_title=Shop Quang Ba San Pham" \
        --data-urlencode "user_name=${WP_ADMIN_USER}" \
        --data-urlencode "admin_password=${WP_ADMIN_PASSWORD}" \
        --data-urlencode "admin_password2=${WP_ADMIN_PASSWORD}" \
        --data-urlencode "admin_email=admin@shop.local" \
        --data-urlencode "blog_public=0" \
        --data-urlencode "pw_weak=1" \
        --data-urlencode "Submit=Install WordPress" \
        -o /tmp/wp-install.html -w '[install] HTTP %{http_code}\n'

    if grep -qi "success" /tmp/wp-install.html; then
        echo "[install] Cai dat THANH CONG."
    else
        echo "[install] Khong thay chuoi 'Success' - kiem tra /tmp/wp-install.html"
    fi
fi

echo
echo "[install] Tai khoan quan tri (luu trong .env):"
grep -E '^WP_ADMIN_(USER|PASSWORD)=' .env | sed 's/\(PASSWORD=\).*/\1***/'
echo
echo "[install] Kiem tra lai:"
curl -sk "${RESOLVE[@]}" -o /dev/null -w '  Trang chu: %{http_code}\n' "${BASE}/"
curl -sk "${RESOLVE[@]}" -o /dev/null -w '  wp-login : %{http_code}\n' "${BASE}/wp-login.php"
