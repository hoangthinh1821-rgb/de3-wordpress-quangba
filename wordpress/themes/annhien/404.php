<?php
/**
 * Trang không tìm thấy.
 *
 * @package annhien
 */

get_header();
?>

<div class="container error-page">
	<span class="eyebrow">Lỗi 404</span>
	<h1>Không tìm thấy trang này</h1>
	<p>
		Có thể đường dẫn đã thay đổi, hoặc túi cà phê bạn tìm đã hết mẻ.
		Hãy quay về trang chủ hoặc xem các sản phẩm hiện có.
	</p>
	<div class="hero__actions">
		<a class="btn" href="<?php echo esc_url( home_url( '/' ) ); ?>">Về trang chủ</a>
		<a class="btn btn--ghost" href="<?php echo esc_url( get_post_type_archive_link( 'san_pham' ) ); ?>">Xem sản phẩm</a>
	</div>
</div>

<?php
get_footer();
