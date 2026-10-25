#!/usr/bin/env bash
# =====================================================================
# Phuc hoi CSDL tu file .sql.gz
#   Cach dung: ./scripts/restore.sh backups/db_shop_db_2026-10-25_020000.sql.gz
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ $# -lt 1 ]]; then
    echo "Cach dung: $0 <file.sql.gz>" >&2
    exit 1
fi

BACKUP_FILE="$1"
[[ -f "$BACKUP_FILE" ]] || { echo "Khong tim thay: $BACKUP_FILE" >&2; exit 1; }

set -a
# shellcheck disable=SC1091
. ./.env
set +a

echo "[restore] CANH BAO: se GHI DE du lieu trong CSDL ${MYSQL_DATABASE}."
read -r -p "Nhap 'YES' de tiep tuc: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Da huy."; exit 1; }

echo "[restore] Dang phuc hoi tu $BACKUP_FILE ..."
gunzip -c "$BACKUP_FILE" | docker exec -i de3-mysql sh -c \
    'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'

echo "[restore] Kiem tra so bang:"
docker exec de3-mysql sh -c \
    'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e \
     "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=\"$MYSQL_DATABASE\";"'

echo "[restore] Hoan tat."
