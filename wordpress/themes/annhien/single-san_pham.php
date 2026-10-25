<?php
/**
 * Chi tiết một sản phẩm.
 *
 * @package annhien
 */

get_header();

while ( have_posts() ) :
	the_post();

	$price   = annhien_meta( get_the_ID(), 'gia', 'Liên hệ' );
	$weight  = annhien_meta( get_the_ID(), 'trong_luong' );
	$roast   = annhien_meta( get_the_ID(), 'do_rang' );
	$flavor  = annhien_meta( get_the_ID(), 'huong_vi' );
	$subject = rawurlencode( 'Đặt hàng: ' . get_the_title() );
	?>
	<article class="single-product">
		<div class="container single-product__grid">
			<div class="single-product__media">
				<img src="<?php echo esc_url( annhien_product_image( get_the_ID() ) ); ?>"
					alt="<?php echo esc_attr( get_the_title() ); ?>" width="600" height="600">
			</div>

			<div>
				<span class="tag">Rang mộc</span>
				<h1><?php the_title(); ?></h1>
				<p class="single-product__price"><?php echo esc_html( $price ); ?></p>

				<dl class="spec-list">
					<?php if ( $weight ) : ?>
						<div><dt>Trọng lượng</dt><dd><?php echo esc_html( $weight ); ?></dd></div>
					<?php endif; ?>
					<?php if ( $roast ) : ?>
						<div><dt>Độ rang</dt><dd><?php echo esc_html( $roast ); ?></dd></div>
					<?php endif; ?>
					<?php if ( $flavor ) : ?>
						<div><dt>Hương vị</dt><dd><?php echo esc_html( $flavor ); ?></dd></div>
					<?php endif; ?>
					<div><dt>Xuất xứ</dt><dd>Đắk Lắk, Việt Nam</dd></div>
				</dl>

				<div class="single-product__actions">
					<a class="btn" href="tel:+84901234567">Gọi đặt hàng</a>
					<a class="btn btn--ghost" href="mailto:hello@annhien.vn?subject=<?php echo esc_attr( $subject ); ?>">
						Đặt qua email
					</a>
				</div>

				<div class="single-product__content">
					<?php the_content(); ?>
				</div>
			</div>
		</div>

		<?php
		$related = new WP_Query(
			array(
				'post_type'      => 'san_pham',
				'posts_per_page' => 3,
				'post__not_in'   => array( get_the_ID() ),
				'orderby'        => 'rand',
				'no_found_rows'  => true,
			)
		);

		if ( $related->have_posts() ) :
			?>
			<div class="container related">
				<h2>Có thể bạn cũng thích</h2>
				<div class="product-grid product-grid--three">
					<?php
					while ( $related->have_posts() ) :
						$related->the_post();
						annhien_product_card( get_the_ID() );
					endwhile;
					wp_reset_postdata();
					?>
				</div>
			</div>
		<?php endif; ?>
	</article>
	<?php
endwhile;

get_footer();
