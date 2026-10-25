#!/usr/bin/env bash
# =====================================================================
# Sinh .env (mat khau ngau nhien) + mysqld-exporter/.my.cnf
# Chay 1 lan tren may chu. An toan khi chay lai (khong ghi de .env).
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

gen() { openssl rand -hex 16; }

if [[ -f .env ]]; then
    echo "[init-env] .env da ton tai - giu nguyen."
else
    cat > .env <<EOF
SERVER_NAME=shop.local
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
PROMETHEUS_PORT=9090

MYSQL_ROOT_PASSWORD=$(gen)
MYSQL_DATABASE=shop_db
MYSQL_USER=wpuser
MYSQL_PASSWORD=$(gen)
READONLY_PASSWORD=$(gen)

MYSQL_EXPORTER_USER=exporter
MYSQL_EXPORTER_PASSWORD=$(gen)

GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$(gen)
EOF
    chmod 600 .env
    echo "[init-env] Da tao .env (quyen 600)."
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

# --- File cau hinh cho mysqld-exporter (0.16+) ---
mkdir -p mysqld-exporter
cat > mysqld-exporter/.my.cnf <<EOF
[client]
user=${MYSQL_EXPORTER_USER}
password=${MYSQL_EXPORTER_PASSWORD}
host=mysql
port=3306
EOF
chmod 600 mysqld-exporter/.my.cnf
echo "[init-env] Da tao mysqld-exporter/.my.cnf (quyen 600)."

echo
echo "Cac bien trong .env:"
grep -E '^[A-Z_]+=' .env | sed 's/PASSWORD=.*/PASSWORD=***/'
