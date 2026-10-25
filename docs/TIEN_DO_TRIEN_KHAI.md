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
| Báo cáo | `BaoCao_De3_WordPress_QuangBa.docx` (30 trang) và `.pdf` |
| Repo GitHub | **Chưa tạo** — việc còn lại của người thực hiện |

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
`./scripts/generate-certs.sh` → `docker compose up -d --build` → `./scripts/install-wordpress.sh`.

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

## 4. Việc còn lại

1. Tạo repo trên GitHub (ví dụ `de3-wordpress-quangba`, để **private** vì đây là bài học phần).
2. Đẩy mã nguồn lên:

   ```bash
   cd "/c/Users/hoang/OneDrive/Máy tính/TK&QTHT/De3_WordPress_QuangBa"
   git remote add origin https://github.com/<tài-khoản>/de3-wordpress-quangba.git
   git branch -M main
   git push -u origin main
   ```

3. Kiểm tra tab **Actions** trên GitHub — pipeline 6 bước phải chạy xanh.

## 5. Ghi chú kỹ thuật

- Báo cáo được sinh từ `docs/BaoCao_De3_WordPress.html` bằng `make-docx.ps1`
  (tự sinh OOXML; Word chỉ dùng để cập nhật mục lục và xuất PDF).
- Ba lỗi đã gặp và đã sửa được ghi trong báo cáo, Bảng 2.3 — đọc lại khi cần chẩn đoán.
- `.env`, khoá TLS và `mysqld-exporter/.my.cnf` bị `.gitignore` chặn; không commit tay các tệp này.
