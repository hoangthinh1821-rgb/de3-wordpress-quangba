# Đề 3 — Website Quảng bá Sản phẩm (WordPress)

Học phần: **Triển khai và Quản trị hệ thống phần mềm**

Website giới thiệu sản phẩm dựng bằng WordPress, chạy hoàn toàn trong Docker Compose,
có Nginx reverse proxy + TLS, giám sát bằng Prometheus/Grafana và quản lý log tập trung
bằng Loki/Promtail.

## 1. Kiến trúc

```
                    ┌──────────────────────────────────────────┐
   Internet ───────►│  Nginx (80 -> 301 -> 443, TLS self-signed)│
                    │   /            -> WordPress              │
                    │   /phpmyadmin/ -> phpMyAdmin             │
                    │   /grafana/    -> Grafana                │
                    └───────────┬──────────────────────────────┘
                                │ frontend network
                    ┌───────────▼──────────┐
                    │  WordPress (php8.2)  │
                    └───────────┬──────────┘
                                │ backend network (internal, không ra Internet)
                    ┌───────────▼──────────┐
                    │  MySQL 8.0           │
                    └──────────────────────┘

    monitoring network: Prometheus, Grafana, Loki, Promtail,
                        node-exporter, mysqld-exporter
```

Ba network tách biệt:

| Network | Thành viên | Mục đích |
|---|---|---|
| `frontend` | nginx, wordpress, phpmyadmin, grafana | Traffic web |
| `backend` (internal) | wordpress, mysql, phpmyadmin, mysqld-exporter | Dữ liệu — không có gateway ra Internet |
| `monitoring` | prometheus, grafana, loki, promtail, node-exporter, mysqld-exporter | Thu thập metrics/log |

## 2. Thành phần

| # | Service | Image | Cổng |
|---|---|---|---|
| 1 | nginx | build từ `nginx/` (nginx:alpine) | 80, 443 |
| 2 | wordpress | `wordpress:php8.2-apache` | nội bộ 80 |
| 3 | mysql | `mysql:8.0` | nội bộ 3306 |
| 4 | phpmyadmin | `phpmyadmin:latest` | nội bộ 80 |
| 5 | prometheus | `prom/prometheus:latest` | 127.0.0.1:9090 |
| 6 | grafana | `grafana/grafana:latest` | nội bộ 3000 |
| 7 | loki | `grafana/loki:latest` | nội bộ 3100 |
| 8 | promtail | `grafana/promtail:latest` | — |
| 9 | node-exporter | `prom/node-exporter:latest` | nội bộ 9100 |
| 10 | mysqld-exporter | `prom/mysqld-exporter:latest` | nội bộ 9104 |

## 3. Triển khai

```bash
git clone <repo-url> de3-wordpress-quangba
cd de3-wordpress-quangba

cp .env.example .env
nano .env          # đổi toàn bộ mật khẩu

chmod +x scripts/*.sh
./scripts/deploy.sh

./scripts/install-wordpress.sh   # cài WordPress qua HTTP, tạo admin trong .env
./scripts/seed-content.sh        # nạp theme, trang giới thiệu, sản phẩm và menu
```

Trỏ tên miền trong file `hosts` của máy khách:

```
192.168.159.128   shop.local
```

Truy cập:

| Dịch vụ | URL |
|---|---|
| Website | https://shop.local |
| Quản trị WordPress | https://shop.local/wp-admin |
| phpMyAdmin | https://shop.local/phpmyadmin/ |
| Grafana | https://shop.local/grafana/ |
| Prometheus | http://127.0.0.1:9090 (qua SSH tunnel) |

### 3.1 Giao diện và nội dung

Website dùng theme riêng **annhien** — classic theme, không cần plugin:

- `wordpress/themes/annhien/` được bind-mount read-only vào `wp-content/themes/annhien`.
  Sửa tệp trên máy thật là có hiệu lực ngay ở lần tải trang kế tiếp (PHP đọc lại mỗi request).
- `wordpress/content/*.html` chứa nội dung 3 trang (Trang chủ, Câu chuyện, Liên hệ) và
  5 sản phẩm. `scripts/seed-content.sh` đọc các tệp này để tạo/cập nhật bài viết, menu và
  cấu hình site; chạy lại nhiều lần vẫn an toàn.
- Sản phẩm là kiểu nội dung tuỳ biến `san_pham` với các trường giá, trọng lượng, độ rang,
  hương vị và ảnh. Ảnh minh hoạ là SVG trong `assets/img/`.
- Favicon `.ico` do Nginx phục vụ trực tiếp từ `nginx/static/`, không đi qua WordPress.

Quy trình sửa nội dung: sửa tệp trong `wordpress/content/` → chạy lại
`./scripts/seed-content.sh` → tải lại trang.

## 4. Bảo mật đã áp dụng

- TLS 1.2/1.3, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- `server_tokens off` — không lộ phiên bản Nginx
- MySQL **không publish cổng** ra host; chỉ nằm trong network `internal`
- Prometheus chỉ bind `127.0.0.1`
- `no-new-privileges` cho mọi container; `mem_limit` chống cạn RAM
- Mật khẩu chỉ nằm trong `.env` (đã `.gitignore`), repo chỉ có `.env.example`
- PoLP ở CSDL: `wpuser` (quyền trên `shop_db`), `report_ro` (chỉ SELECT),
  `exporter` (PROCESS/REPLICATION CLIENT, tối đa 3 kết nối)
- `DISALLOW_FILE_EDIT` — chặn sửa theme/plugin từ wp-admin

## 5. Giám sát & log

Prometheus scrape 4 job: `prometheus`, `node-exporter`, `mysqld-exporter`, `loki`.

Truy vấn PromQL mẫu:

```promql
# % CPU đang dùng
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# % RAM đang dùng
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Số kết nối MySQL hiện tại
mysql_global_status_threads_connected

# Target đang down
up == 0
```

LogQL mẫu (Grafana → Explore → Loki):

```logql
{container="de3-wordpress"} |= "error"
{container="de3-mysql"} |= "Access denied"
{project="de3-wordpress"} |~ " 5[0-9][0-9] "
rate({container="de3-nginx"}[1m])
```

## 6. Sao lưu

```bash
./scripts/backup.sh                    # chạy tay
./scripts/restore.sh backups/db_shop_db_2026-10-25_020000.sql.gz
```

Đặt lịch bằng cron (2:30 sáng hằng ngày):

```cron
30 2 * * * /home/thinh/de3-wordpress-quangba/scripts/backup.sh >> /var/log/de3-backup.log 2>&1
```

## 7. Cấu trúc thư mục

```
.
├── docker-compose.yml
├── .env.example
├── wordpress/        theme annhien + nội dung mẫu (HTML)
├── nginx/            Dockerfile, nginx.conf, template reverse proxy, static/favicon.ico
├── mysql/            my.cnf + script tạo user lúc khởi tạo
├── prometheus/       prometheus.yml + rules/alerts.yml
├── grafana/          provisioning datasource + dashboard
├── loki/             loki-config.yml
├── promtail/         promtail-config.yml
├── scripts/          deploy, certs, install, seed, backup, restore, healthcheck
├── docs/             nguồn báo cáo + tiến độ triển khai
└── .github/workflows/ci.yml
```

## 8. Lệnh thường dùng

```bash
docker compose ps
docker compose logs -f --tail=100 wordpress
docker compose restart nginx
docker compose down            # giữ volume
docker compose down -v         # XOÁ dữ liệu
```
