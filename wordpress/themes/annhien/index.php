<?php
/**
 * Danh sách bài viết mặc định.
 *
 * @package annhien
 */

get_header();
?>

<div class="page-head">
	<div class="container">
		<h1>
			<?php
			if ( is_search() ) {
				printf( 'Kết quả cho “%s”', esc_html( get_search_query() ) );
			} elseif ( is_archive() ) {
				the_archive_title();
			} else {
				bloginfo( 'name' );
			}
			?>
		</h1>
	</div>
</div>

<div class="container section section--snug">
	<?php if ( have_posts() ) : ?>
		<div class="product-grid">
			<?php
			while ( have_posts() ) :
				the_post();
				?>
				<a class="product-card" href="<?php the_permalink(); ?>">
					<span class="product-card__body">
						<span class="product-card__title"><?php the_title(); ?></span>
						<span class="product-card__meta"><?php echo esc_html( get_the_date( 'd/m/Y' ) ); ?></span>
						<span class="product-card__footer">
							<span class="product-card__link">Đọc tiếp →</span>
						</span>
					</span>
				</a>
			<?php endwhile; ?>
		</div>
		<div class="section-footer">
			<?php the_posts_pagination( array( 'mid_size' => 1 ) ); ?>
		</div>
	<?php else : ?>
		<p class="lead">Không tìm thấy nội dung phù hợp.</p>
	<?php endif; ?>
</div>

<?php
get_footer();
