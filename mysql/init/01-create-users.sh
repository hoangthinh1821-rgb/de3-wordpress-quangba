#!/bin/bash
# =====================================================================
# Chay 1 lan khi khoi tao volume mysql_data.
# Ap dung nguyen tac Privilege of Least Privilege (Chuong 6):
#   - wpuser    : chi quyen tren shop_db (entrypoint tao san)
#   - report_ro : CHI DOC, danh cho bao cao / kiem toan
#   - exporter  : tai khoan hep cho mysqld-exporter
# =====================================================================
set -e

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- 1. Tai khoan chi doc phuc vu bao cao
    CREATE USER IF NOT EXISTS 'report_ro'@'%' IDENTIFIED BY '${READONLY_PASSWORD}';
    GRANT SELECT, SHOW VIEW ON \`${MYSQL_DATABASE}\`.* TO 'report_ro'@'%';

    -- 2. Tai khoan cho mysqld-exporter (toi thieu quyen can thiet)
    CREATE USER IF NOT EXISTS '${MYSQL_EXPORTER_USER}'@'%'
        IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}'
        WITH MAX_USER_CONNECTIONS 3;
    GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MYSQL_EXPORTER_USER}'@'%';

    FLUSH PRIVILEGES;
EOSQL

echo "[init] Da tao tai khoan report_ro va ${MYSQL_EXPORTER_USER}."
