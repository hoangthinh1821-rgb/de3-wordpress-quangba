#!/usr/bin/env bash
# =====================================================================
# Sao luu CSDL + thu muc upload cua WordPress
#   - mysqldump --single-transaction  (khong khoa bang khi sao luu)
#   - giu 7 ban gan nhat
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"
RETENTION="${BACKUP_RETENTION:-7}"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

DB_FILE="$BACKUP_DIR/db_${MYSQL_DATABASE}_${STAMP}.sql.gz"
WP_FILE="$BACKUP_DIR/wpdata_${STAMP}.tar.gz"

echo "[backup] ($(date '+%F %T')) Bat dau."

# --- 1. Co so du lieu ---
docker exec de3-mysql sh -c \
    'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction --quick --routines --triggers --events \
        "$MYSQL_DATABASE"' | gzip -9 > "$DB_FILE"
chmod 600 "$DB_FILE"

# --- 2. Thu muc wp-content (anh san pham, plugin, theme) ---
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v de3-wordpress_wordpress_data:/data:ro \
    -v "$BACKUP_DIR":/backup \
    nginx:alpine \
    tar czf "/backup/$(basename "$WP_FILE")" -C /data wp-content 2>/dev/null || true

[[ -f "$WP_FILE" ]] && chmod 600 "$WP_FILE"

# --- 3. Xoa ban cu, giu $RETENTION ban moi nhat ---
for pattern in "db_${MYSQL_DATABASE}_*.sql.gz" "wpdata_*.tar.gz"; do
    # shellcheck disable=SC2012,SC2086
    ls -1t "$BACKUP_DIR"/$pattern 2>/dev/null | tail -n +"$((RETENTION + 1))" | xargs -r rm -f
done

echo "[backup] CSDL : $DB_FILE ($(du -h "$DB_FILE" | cut -f1))"
[[ -f "$WP_FILE" ]] && echo "[backup] Upload: $WP_FILE ($(du -h "$WP_FILE" | cut -f1))"
echo "[backup] Hoan tat."
