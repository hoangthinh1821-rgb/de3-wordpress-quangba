<?php
/**
 * An Nhiên Coffee - hàm của theme.
 *
 * @package annhien
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Thiết lập theme: menu, ảnh đại diện, tiêu đề tự động.
 */
function annhien_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'post-thumbnails' );
	add_theme_support( 'automatic-feed-links' );
	add_theme_support( 'responsive-embeds' );
	add_theme_support( 'align-wide' );
	add_theme_support(
		'html5',
		array( 'search-form', 'comment-form', 'comment-list', 'gallery', 'caption', 'style', 'script' )
	);

	register_nav_menus(
		array(
			'primary' => 'Menu chính',
			'footer'  => 'Menu chân trang',
		)
	);
}
add_action( 'after_setup_theme', 'annhien_setup' );

/**
 * Nạp CSS và JS của theme.
 */
function annhien_assets() {
	$style_ver  = filemtime( get_stylesheet_directory() . '/style.css' );
	$script_ver = filemtime( get_stylesheet_directory() . '/assets/js/site.js' );

	wp_enqueue_style( 'annhien-style', get_stylesheet_uri(), array(), $style_ver );
	wp_enqueue_script(
		'annhien-site',
		get_theme_file_uri( 'assets/js/site.js' ),
		array(),
		$script_ver,
		true
	);
}
add_action( 'wp_enqueue_scripts', 'annhien_assets' );

/**
 * Khai báo kiểu nội dung tuỳ biến "Sản phẩm".
 */
function annhien_register_product() {
	register_post_type(
		'san_pham',
		array(
			'labels'       => array(
				'name'          => 'Sản phẩm',
				'singular_name' => 'Sản phẩm',
				'add_new'       => 'Thêm sản phẩm',
				'add_new_item'  => 'Thêm sản phẩm mới',
				'edit_item'     => 'Sửa sản phẩm',
				'new_item'      => 'Sản phẩm mới',
				'view_item'     => 'Xem sản phẩm',
				'search_items'  => 'Tìm sản phẩm',
				'not_found'     => 'Chưa có sản phẩm nào',
				'menu_name'     => 'Sản phẩm',
			),
			'public'       => true,
			'has_archive'  => 'san-pham',
			'rewrite'      => array( 'slug' => 'san-pham' ),
			'menu_icon'    => 'dashicons-coffee',
			'menu_position' => 20,
			'supports'     => array( 'title', 'editor', 'excerpt', 'thumbnail', 'revisions' ),
			'show_in_rest' => true,
		)
	);
}
add_action( 'init', 'annhien_register_product' );

/**
 * Sắp xếp kho sản phẩm theo thứ tự đã đặt trong admin (menu_order).
 */
function annhien_product_archive_order( $query ) {
	if ( is_admin() || ! $query->is_main_query() ) {
		return;
	}

	if ( $query->is_post_type_archive( 'san_pham' ) ) {
		$query->set( 'orderby', array( 'menu_order' => 'ASC', 'date' => 'ASC' ) );
		$query->set( 'posts_per_page', 12 );
	}
}
add_action( 'pre_get_posts', 'annhien_product_archive_order' );

/**
 * Không trả 404 cho các URL sitemap của WordPress.
 *
 * Truy vấn sitemap không khớp bài viết nào nên WordPress đặt 404 trước khi
 * bộ sinh sitemap kịp ghi XML. Bỏ qua bước đoán 404 cho các route này.
 */
function annhien_allow_sitemap_routes( $preempt ) {
	if ( 'index' === get_query_var( 'sitemap' ) || get_query_var( 'sitemap-stylesheet' ) ) {
		return true;
	}

	$sitemap = get_query_var( 'sitemap' );
	if ( $sitemap ) {
		$providers = wp_get_sitemap_providers();
		if ( isset( $providers[ $sitemap ] ) ) {
			return true;
		}
	}

	return $preempt;
}
add_filter( 'pre_handle_404', 'annhien_allow_sitemap_routes' );

/**
 * Đọc một trường thông tin sản phẩm.
 *
 * @param int    $post_id ID sản phẩm.
 * @param string $key     Tên trường (không gồm tiền tố).
 * @param string $default Giá trị mặc định.
 * @return string
 */
function annhien_meta( $post_id, $key, $default = '' ) {
	$value = get_post_meta( $post_id, '_annhien_' . $key, true );
	return ( '' === $value ) ? $default : $value;
}

/**
 * Danh sách hình minh hoạ đóng gói sẵn trong theme.
 *
 * @return array<string, string>
 */
function annhien_illustrations() {
	return array(
		'chung'     => 'Túi cà phê (mặc định)',
		'co-dien'   => 'Rang Cổ Điển - túi nâu đậm',
		'tinh-khoi' => 'Sáng Tinh Khôi - túi kem',
		'phin-dam'  => 'Hạt Phin Đậm - túi gạch',
		'hoa-quyen' => 'Hòa Quyện - túi xanh rêu',
		'qua-tang'  => 'Hộp quà tặng',
	);
}

/**
 * Ảnh sản phẩm: ưu tiên ảnh đại diện, sau đó tới hình minh hoạ của theme.
 *
 * @param int $post_id ID sản phẩm.
 * @return string URL ảnh.
 */
function annhien_product_image( $post_id ) {
	$thumb = get_the_post_thumbnail_url( $post_id, 'large' );
	if ( $thumb ) {
		return $thumb;
	}

	$key  = annhien_meta( $post_id, 'anh', 'chung' );
	$file = 'assets/img/sp-' . sanitize_file_name( $key ) . '.svg';
	if ( ! file_exists( get_theme_file_path( $file ) ) ) {
		$file = 'assets/img/sp-chung.svg';
	}

	return get_theme_file_uri( $file );
}

/**
 * Hộp thông tin sản phẩm trong trang quản trị.
 */
function annhien_add_meta_box() {
	add_meta_box(
		'annhien-product-info',
		'Thông tin quảng bá',
		'annhien_meta_box_html',
		'san_pham',
		'normal',
		'high'
	);
}
add_action( 'add_meta_boxes', 'annhien_add_meta_box' );

/**
 * Giao diện hộp thông tin sản phẩm.
 *
 * @param WP_Post $post Bài đang sửa.
 */
function annhien_meta_box_html( $post ) {
	wp_nonce_field( 'annhien_save_meta', 'annhien_meta_nonce' );

	$fields = array(
		'gia'         => array( 'Giá bán', '145.000đ' ),
		'trong_luong' => array( 'Trọng lượng', '250g' ),
		'do_rang'     => array( 'Độ rang', 'Rang vừa' ),
		'huong_vi'    => array( 'Hương vị', 'Chocolate, hạt dẻ, mật ong' ),
	);

	echo '<table class="form-table" role="presentation"><tbody>';
	foreach ( $fields as $key => $field ) {
		printf(
			'<tr><th scope="row"><label for="annhien-%1$s">%2$s</label></th><td><input type="text" class="regular-text" id="annhien-%1$s" name="annhien_%1$s" value="%3$s" placeholder="%4$s"></td></tr>',
			esc_attr( $key ),
			esc_html( $field[0] ),
			esc_attr( annhien_meta( $post->ID, $key ) ),
			esc_attr( $field[1] )
		);
	}

	echo '<tr><th scope="row"><label for="annhien-anh">Hình minh hoạ</label></th><td><select id="annhien-anh" name="annhien_anh">';
	$current = annhien_meta( $post->ID, 'anh', 'chung' );
	foreach ( annhien_illustrations() as $value => $label ) {
		printf(
			'<option value="%1$s" %2$s>%3$s</option>',
			esc_attr( $value ),
			selected( $current, $value, false ),
			esc_html( $label )
		);
	}
	echo '</select><p class="description">Chỉ dùng khi sản phẩm chưa có ảnh đại diện.</p></td></tr>';
	echo '</tbody></table>';
}

/**
 * Lưu thông tin sản phẩm.
 *
 * @param int $post_id ID bài.
 */
function annhien_save_meta( $post_id ) {
	if ( ! isset( $_POST['annhien_meta_nonce'] ) ) {
		return;
	}
	if ( ! wp_verify_nonce( sanitize_key( $_POST['annhien_meta_nonce'] ), 'annhien_save_meta' ) ) {
		return;
	}
	if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
		return;
	}
	if ( ! current_user_can( 'edit_post', $post_id ) ) {
		return;
	}

	$text_fields = array( 'gia', 'trong_luong', 'do_rang', 'huong_vi' );
	foreach ( $text_fields as $key ) {
		$name = 'annhien_' . $key;
		if ( isset( $_POST[ $name ] ) ) {
			update_post_meta( $post_id, '_annhien_' . $key, sanitize_text_field( wp_unslash( $_POST[ $name ] ) ) );
		}
	}

	if ( isset( $_POST['annhien_anh'] ) ) {
		$anh = sanitize_key( wp_unslash( $_POST['annhien_anh'] ) );
		if ( array_key_exists( $anh, annhien_illustrations() ) ) {
			update_post_meta( $post_id, '_annhien_anh', $anh );
		}
	}
}
add_action( 'save_post_san_pham', 'annhien_save_meta' );

/**
 * Biểu tượng favicon (SVG + ICO dự phòng do Nginx phục vụ).
 */
function annhien_favicon() {
	printf(
		'<link rel="icon" type="image/svg+xml" href="%s">' . "\n",
		esc_url( get_theme_file_uri( 'assets/img/favicon.svg' ) )
	);
	echo '<link rel="alternate icon" type="image/x-icon" href="/favicon.ico">' . "\n";
}
add_action( 'wp_head', 'annhien_favicon' );

/**
 * Độ dài đoạn trích ngắn gọn cho thẻ sản phẩm.
 *
 * @param int $length Số từ mặc định.
 * @return int
 */
function annhien_excerpt_length( $length ) {
	return 24;
}
add_filter( 'excerpt_length', 'annhien_excerpt_length' );

/**
 * Menu dự phòng khi chưa gán menu trong trang quản trị.
 */
function annhien_menu_fallback() {
	echo '<ul class="nav-list">';
	printf( '<li><a href="%s">Trang chủ</a></li>', esc_url( home_url( '/' ) ) );
	$archive = get_post_type_archive_link( 'san_pham' );
	if ( $archive ) {
		printf( '<li><a href="%s">Sản phẩm</a></li>', esc_url( $archive ) );
	}
	foreach ( array( 'cau-chuyen' => 'Câu chuyện', 'lien-he' => 'Liên hệ' ) as $slug => $label ) {
		$page = get_page_by_path( $slug );
		if ( $page ) {
			printf( '<li><a href="%s">%s</a></li>', esc_url( get_permalink( $page ) ), esc_html( $label ) );
		}
	}
	echo '</ul>';
}

/**
 * Một thẻ sản phẩm dùng chung cho trang chủ và kho sản phẩm.
 *
 * @param int $post_id ID sản phẩm.
 */
function annhien_product_card( $post_id ) {
	$price  = annhien_meta( $post_id, 'gia' );
	$weight = annhien_meta( $post_id, 'trong_luong' );
	$roast  = annhien_meta( $post_id, 'do_rang' );
	$meta   = array_filter( array( $weight, $roast ) );
	?>
	<a class="product-card" href="<?php echo esc_url( get_permalink( $post_id ) ); ?>">
		<span class="product-card__media">
			<img src="<?php echo esc_url( annhien_product_image( $post_id ) ); ?>"
				alt="<?php echo esc_attr( get_the_title( $post_id ) ); ?>" loading="lazy" width="320" height="320">
		</span>
		<span class="product-card__body">
			<span class="product-card__title"><?php echo esc_html( get_the_title( $post_id ) ); ?></span>
			<?php if ( $meta ) : ?>
				<span class="product-card__meta"><?php echo esc_html( implode( ' · ', $meta ) ); ?></span>
			<?php endif; ?>
			<span class="product-card__footer">
				<span class="product-card__price"><?php echo esc_html( $price ? $price : 'Liên hệ' ); ?></span>
				<span class="product-card__link">Xem chi tiết →</span>
			</span>
		</span>
	</a>
	<?php
}
