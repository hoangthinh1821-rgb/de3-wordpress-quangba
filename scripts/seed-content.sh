#!/usr/bin/env bash
# =====================================================================
# Nạp nội dung cho website: trang giới thiệu, sản phẩm, menu, cấu hình.
# Chạy sau khi WordPress đã được cài đặt:
#   ./scripts/install-wordpress.sh
#   ./scripts/seed-content.sh
# Script chạy lại nhiều lần vẫn an toàn (tạo mới hoặc cập nhật).
# =====================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_DIR="$PROJECT_DIR/wordpress/content"
cd "$PROJECT_DIR"

if [[ ! -d "$CONTENT_DIR" ]]; then
    echo "[seed] Khong tim thay thu muc noi dung: $CONTENT_DIR" >&2
    exit 1
fi

# Gọi WP-CLI trong container WordPress.
wp() {
    docker compose exec -T wordpress wp --allow-root --path=/var/www/html "$@"
}

# ---------------------------------------------------------------------
# 0. Chuẩn bị WP-CLI
# ---------------------------------------------------------------------
echo "[seed] Kiem tra WP-CLI trong container..."
if ! docker compose exec -T wordpress sh -c 'command -v wp >/dev/null 2>&1'; then
    echo "[seed] Cai WP-CLI..."
    docker compose exec -T wordpress sh -c \
        'curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /tmp/wp-cli.phar && mv /tmp/wp-cli.phar /usr/local/bin/wp'
fi

if ! wp core is-installed >/dev/null 2>&1; then
    echo "[seed] WordPress chua duoc cai dat. Hay chay ./scripts/install-wordpress.sh truoc." >&2
    exit 1
fi

# ---------------------------------------------------------------------
# 1. Theme và cấu hình chung
# ---------------------------------------------------------------------
echo "[seed] Kich hoat theme annhien..."
wp theme activate annhien >/dev/null

echo "[seed] Thiet lap thong tin website..."
wp option update blogname "An Nhiên Coffee" >/dev/null
wp option update blogdescription "Cà phê rang mộc" >/dev/null
wp option update timezone_string "Asia/Ho_Chi_Minh" >/dev/null
wp option update date_format "d/m/Y" >/dev/null
wp option update default_comment_status closed >/dev/null
wp option update default_ping_status closed >/dev/null
# Cho phep robots.txt, sitemap va go bo the noindex mac dinh cua ban cai dat
wp option update blog_public 1 >/dev/null

echo "[seed] Bat permalink /%postname%/..."
wp rewrite structure '/%postname%/' --hard >/dev/null

# WP-CLI chay bang PHP CLI nen khong tu sinh duoc .htaccess (thieu
# apache_get_modules). Ghi truc tiep quy tac chuan cua WordPress.
if ! docker compose exec -T wordpress sh -c 'grep -q "RewriteRule . /index.php" /var/www/html/.htaccess 2>/dev/null'; then
    echo "[seed] Ghi quy tac .htaccess cho permalink..."
    docker compose exec -T wordpress sh -c 'cat > /var/www/html/.htaccess <<"HTACCESS"
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
HTACCESS
chown www-data:www-data /var/www/html/.htaccess'
fi

# ---------------------------------------------------------------------
# 2. Trang tĩnh
# ---------------------------------------------------------------------
find_page() {
    wp post list --post_type=page --post_status=any --name="$1" --field=ID --format=ids | head -n 1
}

upsert_page() {
    local slug="$1" title="$2" file="$3" page_id
    page_id="$(find_page "$slug")"
    if [[ -z "$page_id" ]]; then
        page_id="$(wp post create \
            --post_type=page \
            --post_status=publish \
            --post_title="$title" \
            --post_name="$slug" \
            --post_content="$(cat "$file")" \
            --porcelain)"
        echo "[seed] Tao trang: $title (ID $page_id)" >&2
    else
        wp post update "$page_id" \
            --post_title="$title" \
            --post_name="$slug" \
            --post_status=publish \
            --post_content="$(cat "$file")" >/dev/null
        echo "[seed] Cap nhat trang: $title (ID $page_id)" >&2
    fi
    printf '%s' "$page_id"
}

front_id="$(upsert_page trang-chu "Trang chủ" "$CONTENT_DIR/trang-chu.html")"
story_id="$(upsert_page cau-chuyen "Câu chuyện" "$CONTENT_DIR/cau-chuyen.html")"
contact_id="$(upsert_page lien-he "Liên hệ" "$CONTENT_DIR/lien-he.html")"

# ---------------------------------------------------------------------
# 3. Sản phẩm
# ---------------------------------------------------------------------
find_product() {
    wp post list --post_type=san_pham --post_status=any --name="$1" --field=ID --format=ids | head -n 1
}

upsert_product() {
    local slug="$1" title="$2" order="$3" price="$4" weight="$5"
    local roast="$6" flavor="$7" art="$8" file="$9" product_id
    product_id="$(find_product "$slug")"
    if [[ -z "$product_id" ]]; then
        product_id="$(wp post create \
            --post_type=san_pham \
            --post_status=publish \
            --post_title="$title" \
            --post_name="$slug" \
            --menu_order="$order" \
            --post_content="$(cat "$file")" \
            --porcelain)"
        echo "[seed] Tao san pham: $title (ID $product_id)" >&2
    else
        wp post update "$product_id" \
            --post_title="$title" \
            --post_name="$slug" \
            --menu_order="$order" \
            --post_status=publish \
            --post_content="$(cat "$file")" >/dev/null
        echo "[seed] Cap nhat san pham: $title (ID $product_id)" >&2
    fi

    wp post meta update "$product_id" _annhien_gia "$price" >/dev/null
    wp post meta update "$product_id" _annhien_trong_luong "$weight" >/dev/null
    wp post meta update "$product_id" _annhien_do_rang "$roast" >/dev/null
    wp post meta update "$product_id" _annhien_huong_vi "$flavor" >/dev/null
    wp post meta update "$product_id" _annhien_anh "$art" >/dev/null
    printf '%s' "$product_id"
}

upsert_product rang-co-dien "Rang Cổ Điển" 1 \
    "145.000đ" "250g" "Rang đậm" "Chocolate đen, hạt dẻ, đường mía" \
    "co-dien" "$CONTENT_DIR/san-pham-rang-co-dien.html" >/dev/null

upsert_product sang-tinh-khoi "Sáng Tinh Khôi" 2 \
    "185.000đ" "250g" "Rang vừa" "Cam chanh, hoa nhài, mật ong" \
    "tinh-khoi" "$CONTENT_DIR/san-pham-sang-tinh-khoi.html" >/dev/null

upsert_product hat-phin-dam "Hạt Phin Đậm" 3 \
    "245.000đ" "500g" "Rang đậm" "Ca cao, caramel, khói nhẹ" \
    "phin-dam" "$CONTENT_DIR/san-pham-hat-phin-dam.html" >/dev/null

upsert_product hoa-quyen "Hòa Quyện" 4 \
    "165.000đ" "250g" "Rang vừa" "Hạt dẻ, mật ong, trái cây khô" \
    "hoa-quyen" "$CONTENT_DIR/san-pham-hoa-quyen.html" >/dev/null

upsert_product qua-tang-an-nhien "Quà Tặng An Nhiên" 5 \
    "355.000đ" "Bộ 2 túi 250g" "Rang vừa" "Nhiều hương vị" \
    "qua-tang" "$CONTENT_DIR/san-pham-qua-tang.html" >/dev/null

# ---------------------------------------------------------------------
# 4. Trang chủ tĩnh
# ---------------------------------------------------------------------
echo "[seed] Dat trang chu tinh..."
wp option update show_on_front page >/dev/null
wp option update page_on_front "$front_id" >/dev/null
wp option update page_for_posts 0 >/dev/null

# ---------------------------------------------------------------------
# 5. Menu
# ---------------------------------------------------------------------
echo "[seed] Dung lai menu..."
existing_menu="$(wp menu list --fields=term_id,slug --format=csv | awk -F, '$2=="chinh" {print $1; exit}')"
if [[ -n "$existing_menu" ]]; then
    wp menu delete "$existing_menu" >/dev/null
fi

menu_id="$(wp menu create "Chính" --porcelain)"
wp menu item add-post "$menu_id" "$front_id" --title="Trang chủ" >/dev/null
wp menu item add-custom "$menu_id" "Sản phẩm" "$(wp option get home)/san-pham/" >/dev/null
wp menu item add-post "$menu_id" "$story_id" --title="Câu chuyện" >/dev/null
wp menu item add-post "$menu_id" "$contact_id" --title="Liên hệ" >/dev/null
wp menu location assign "$menu_id" primary >/dev/null
wp menu location assign "$menu_id" footer >/dev/null

# ---------------------------------------------------------------------
# 6. Dọn nội dung mặc định
# ---------------------------------------------------------------------
for slug in hello-world sample-page privacy-policy; do
    default_id="$(wp post list --post_type=post,page --post_status=any --name="$slug" --field=ID --format=ids | head -n 1)"
    if [[ -n "$default_id" ]]; then
        wp post delete "$default_id" --force >/dev/null
        echo "[seed] Da xoa noi dung mac dinh: $slug" >&2
    fi
done

# ---------------------------------------------------------------------
# 7. Hoàn tất
# ---------------------------------------------------------------------
wp rewrite flush --hard >/dev/null
wp cache flush >/dev/null

echo
echo "[seed] Xong. Kiem tra nhanh:"
printf '  Trang chu : %s\n' "$(wp option get home)/"
printf '  San pham  : %s\n' "$(wp option get home)/san-pham/"
printf '  Theme     : %s\n' "$(wp theme list --status=active --field=name)"
printf '  Menu      : %s\n' "$(wp menu list --fields=name,locations --format=csv | tail -n +2)"
