#!/usr/bin/env bash
# =====================================================================
# Sinh chung chi TLS self-signed cho Nginx
# Tuong thich OpenSSL 1.1.0 (Ubuntu 18.04) - dung file cau hinh SAN
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

SERVER_NAME="${SERVER_NAME:-shop.local}"
CERT_DIR="nginx/certs"
mkdir -p "$CERT_DIR"

if [[ -f "$CERT_DIR/server.crt" && -f "$CERT_DIR/server.key" ]]; then
    echo "[certs] Da co chung chi trong $CERT_DIR - bo qua."
    echo "        Xoa 2 file server.crt/server.key neu muon tao lai."
    exit 0
fi

TMP_CNF="$(mktemp)"
trap 'rm -f "$TMP_CNF"' EXIT

cat > "$TMP_CNF" <<EOF
[req]
distinguished_name = dn
x509_extensions    = v3
prompt             = no

[dn]
C  = VN
ST = Ha Noi
L  = Ha Noi
O  = De 3 WordPress Quang Ba
CN = ${SERVER_NAME}

[v3]
subjectAltName     = DNS:${SERVER_NAME}, DNS:localhost, IP:127.0.0.1
basicConstraints   = CA:FALSE
keyUsage           = digitalSignature, keyEncipherment
extendedKeyUsage   = serverAuth
EOF

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$CERT_DIR/server.key" \
    -out    "$CERT_DIR/server.crt" \
    -config "$TMP_CNF" 2>/dev/null

chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo "[certs] Da tao chung chi cho ${SERVER_NAME}:"
openssl x509 -in "$CERT_DIR/server.crt" -noout -subject -dates -ext subjectAltName
