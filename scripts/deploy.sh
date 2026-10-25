#!/usr/bin/env bash
# =====================================================================
# Trien khai toan bo he thong (idempotent)
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ ! -f .env ]]; then
    echo "[deploy] Chua co .env - tao tu .env.example"
    cp .env.example .env
    echo "[deploy] HAY SUA MAT KHAU trong .env roi chay lai."
    exit 1
fi

echo "[deploy] 1/4 Kiem tra cu phap cau hinh"
docker compose config -q

echo "[deploy] 2/4 Sinh chung chi TLS"
./scripts/generate-certs.sh

echo "[deploy] 3/4 Build image nginx"
docker compose build nginx

echo "[deploy] 4/4 Khoi dong stack"
docker compose up -d

echo
echo "[deploy] Cho cac healthcheck..."
sleep 20
docker compose ps

echo
echo "[deploy] Kiem tra endpoint"
./scripts/healthcheck.sh || true
