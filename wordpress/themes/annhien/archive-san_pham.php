<?php
/**
 * Kho sản phẩm.
 *
 * @package annhien
 */

get_header();
?>

<div class="container">
	<div class="archive-head">
		<span class="eyebrow">Sản phẩm</span>
		<h1><?php post_type_archive_title(); ?></h1>
		<p class="lead">Tất cả các mẻ rang hiện có. Mỗi túi 250g hoặc 500g, ghi rõ ngày rang trên nhãn.</p>
	</div>
</div>

<div class="container section section--flush-top">
	<?php if ( have_posts() ) : ?>
		<div class="product-grid product-grid--three">
			<?php
			while ( have_posts() ) :
				the_post();
				annhien_product_card( get_the_ID() );
			endwhile;
			?>
		</div>
		<div class="section-footer">
			<?php the_posts_pagination( array( 'mid_size' => 1 ) ); ?>
		</div>
	<?php else : ?>
		<p class="lead">Sản phẩm đang được cập nhật. Vui lòng quay lại sau.</p>
	<?php endif; ?>
</div>

<div class="cta">
	<div class="container">
		<div class="cta__panel">
			<div>
				<h2>Cần chọn giúp một gu?</h2>
				<p>Gọi 0901 234 567 hoặc ghé xưởng rang ở Buôn Ma Thuột để nếm thử trước khi mua.</p>
			</div>
			<div class="cta__actions">
				<a class="btn" href="tel:+84901234567">0901 234 567</a>
				<a class="btn btn--light" href="<?php echo esc_url( home_url( '/lien-he/' ) ); ?>">Liên hệ</a>
			</div>
		</div>
	</div>
</div>

<?php
get_footer();
