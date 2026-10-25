# Tiến độ triển khai — Đề 3 (Website Quảng bá Sản phẩm, WordPress)

Cập nhật lần cuối: 25/10/2026

## 1. Trạng thái

| Hạng mục | Trạng thái |
|---|---|
| Stack 10 container trên VM 192.168.159.128 | Đang chạy, `docker compose ps` → 10/10 `Up`, MySQL/WordPress/Nginx `healthy` |
| Kiểm tra sức khoẻ | `./scripts/healthcheck.sh` → `KET QUA: TAT CA DAT` |
| Prometheus | 4/4 target `up`, 8 quy tắc cảnh báo đã nạp (đều `inactive`) |
| Grafana | 13.2.2, dashboard `De 3 - Tong quan he thong` (7 panel) |
| Loki / Promtail | Log Nginx truy vấn được bằng `{container="de3-nginx"}` |
| Sao lưu | `backups/db_shop_db_*.sql.gz` + `wpdata_*.tar.gz`, giữ 7 bản |
| Giao diện website | Theme riêng `annhien`: 3 trang, 5 sản phẩm, menu, favicon; đã kiểm tra ở desktop/tablet/mobile |
| Báo cáo | `BaoCao_De3_WordPress_QuangBa.docx` (30 trang) và `.pdf` |
| Repo GitHub | Đã tạo và đẩy lên: `hoangthinh1821-rgb/de3-wordpress-quangba` (private) |

## 2. Lệnh vận hành nhanh (trên máy ảo)

```bash
cd ~/de3-wordpress-quangba

docker compose ps                 # xem trạng thái
docker compose logs -f nginx      # xem log một dịch vụ
./scripts/healthcheck.sh          # kiểm tra toàn hệ thống
./scripts/verify-observability.sh # minh chứng Prometheus / Grafana / Loki
./scripts/backup.sh               # sao lưu CSDL + wp-content
```

Dựng lại (giữ dữ liệu):

```bash
docker compose down
docker compose up -d --build
./scripts/healthcheck.sh
```

Dựng lại từ đầu (mất dữ liệu): `docker compose down -v` → `./scripts/init-env.sh` →
`./scripts/generate-certs.sh` → `docker compose up -d --build` → `./scripts/install-wordpress.sh` →
`./scripts/seed-content.sh`.

## 3. Truy cập

Thêm vào `C:\Windows\System32\drivers\etc\hosts` (PowerShell Administrator):

```
192.168.159.128   shop.local
```

| Dịch vụ | Địa chỉ |
|---|---|
| Website | https://shop.local/ |
| Quản trị WordPress | https://shop.local/wp-admin/ |
| phpMyAdmin | https://shop.local/phpmyadmin/ |
| Grafana | https://shop.local/grafana/ |
| Prometheus | http://127.0.0.1:9090 (chỉ trên VM, dùng SSH tunnel) |

Chứng chỉ tự ký nên trình duyệt cảnh báo một lần — chọn *Advanced → Proceed*.

Tài khoản và mật khẩu nằm trong `.env` trên máy ảo (không commit lên Git):

```bash
grep -E 'WP_ADMIN|GRAFANA_ADMIN|MYSQL_USER|READONLY' ~/de3-wordpress-quangba/.env
```

## 4. Repo GitHub

Mã nguồn đã đẩy lên: <https://github.com/hoangthinh1821-rgb/de3-wordpress-quangba> (private).

Việc còn lại: mở tab **Actions** trên GitHub, bảo đảm pipeline 6 bước chạy xanh.

## 5. Ghi chú kỹ thuật

- Báo cáo được sinh từ `docs/BaoCao_De3_WordPress.html` bằng `make-docx.ps1`
  (tự sinh OOXML; Word chỉ dùng để cập nhật mục lục và xuất PDF).
- Ba lỗi đã gặp và đã sửa được ghi trong báo cáo, Bảng 2.3 — đọc lại khi cần chẩn đoán.
- `.env`, khoá TLS và `mysqld-exporter/.my.cnf` bị `.gitignore` chặn; không commit tay các tệp này.
- Website dùng theme riêng `annhien` (bind-mount read-only từ `wordpress/themes/annhien`).
  Nội dung mẫu nằm trong `wordpress/content/*.html`; `scripts/seed-content.sh` nạp lại
  trang, sản phẩm, menu và cấu hình — chạy lại nhiều lần vẫn an toàn.
- Permalink `/%postname%/` cần `.htaccess` và Apache `AllowOverride All`; cấu hình này
  được mount từ `wordpress/apache/allowoverride.conf` vì image chính thức đặt
  `AllowOverride None`. Script seed tự ghi `.htaccess` chuẩn của WordPress.
- WP-CLI được cài trong container lúc chạy script seed, nên sau khi tạo lại container
  chỉ cần chạy lại `./scripts/seed-content.sh`.
