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

<?php
get_footer();
