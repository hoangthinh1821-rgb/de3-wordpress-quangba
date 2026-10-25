#!/usr/bin/env bash
# =====================================================================
# Chan doan nhanh khi co service loi
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

echo "===== 1. Log mysqld-exporter ====="
docker logs de3-mysqld-exporter --tail 30 2>&1

echo
echo "===== 2. Bien moi truong exporter ====="
docker inspect de3-mysqld-exporter \
    --format '{{range .Config.Env}}{{println .}}{{end}}' \
    | sed 's/PASSWORD=.*/PASSWORD=***/'

echo
echo "===== 3. Tai khoan trong MySQL ====="
docker exec de3-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -N -e \
    "SELECT user, host, plugin FROM mysql.user;" 2>&1 | grep -v "Warning"

echo
echo "===== 4. Quyen cua exporter ====="
docker exec de3-mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e \
    "SHOW GRANTS FOR '${MYSQL_EXPORTER_USER}'@'%';" 2>&1 | grep -v "Warning"

echo
echo "===== 5. Ket noi thu bang tai khoan exporter ====="
docker exec de3-mysql mysql -u"${MYSQL_EXPORTER_USER}" -p"${MYSQL_EXPORTER_PASSWORD}" -N -e \
    "SELECT 'ket noi OK';" 2>&1 | grep -v "Warning"

echo
echo "===== 6. Log nginx (20 dong cuoi) ====="
docker logs de3-nginx --tail 20 2>&1

echo
echo "===== 7. Log wordpress (20 dong cuoi) ====="
docker logs de3-wordpress --tail 20 2>&1
