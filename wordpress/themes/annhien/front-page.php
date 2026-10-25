<?php
/**
 * Trang chủ: giới thiệu thương hiệu và sản phẩm nổi bật.
 *
 * @package annhien
 */

get_header();
?>

<section class="hero">
	<div class="container hero__grid">
		<div>
			<span class="eyebrow">Cà phê rang mộc · Đắk Lắk</span>
			<h1>Hạt cà phê Việt, <em>rang mới</em> mỗi tuần.</h1>
			<p class="hero__text">
				An Nhiên chọn hạt Robusta và Arabica từ những vườn nhỏ ở Buôn Ma Thuột,
				rang mộc theo từng mẻ để giữ trọn hương vị nguyên bản.
			</p>
			<div class="hero__actions">
				<a class="btn" href="<?php echo esc_url( get_post_type_archive_link( 'san_pham' ) ); ?>">
					Xem sản phẩm
				</a>
				<a class="btn btn--ghost" href="<?php echo esc_url( home_url( '/cau-chuyen/' ) ); ?>">
					Câu chuyện của chúng tôi
				</a>
			</div>
			<div class="hero__stats">
				<div class="hero__stat">
					<strong>7 ngày</strong>
					<span>Rang mới mỗi mẻ</span>
				</div>
				<div class="hero__stat">
					<strong>100%</strong>
					<span>Hạt trồng tại Việt Nam</span>
				</div>
				<div class="hero__stat">
					<strong>24 giờ</strong>
					<span>Đóng gói sau rang</span>
				</div>
			</div>
		</div>

		<div class="hero__art">
			<img src="<?php echo esc_url( get_theme_file_uri( 'assets/img/hero.svg' ) ); ?>"
				alt="Ly cà phê rang mộc An Nhiên" width="560" height="560" fetchpriority="high">
			<div class="hero__badge">
				<strong>Mẻ rang tuần này</strong>
				Vừa rang xong — ghi ngày trên nhãn
			</div>
		</div>
	</div>
</section>

<div class="strip">
	<div class="container strip__grid">
		<div class="strip__item">
			<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
				<path d="M12 21c0-6 3-10 9-12-1 7-4 11-9 12Z"/>
				<path d="M12 21C12 15 9 11 3 9c1 7 4 11 9 12Z"/>
				<path d="M12 21v-6"/>
			</svg>
			<div><strong>Rang mộc nguyên chất</strong><span>Không phụ gia, không tẩm hương</span></div>
		</div>
		<div class="strip__item">
			<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
				<path d="M12 3c2.5 3 4 5.2 4 7.5a4 4 0 0 1-8 0C8 8.2 9.5 6 12 3Z"/>
				<path d="M12 11v10"/>
			</svg>
			<div><strong>Rang theo từng mẻ nhỏ</strong><span>Đóng gói trong 24 giờ sau rang</span></div>
		</div>
		<div class="strip__item">
			<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
				<path d="M4 9h12v6a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V9Z"/>
				<path d="M16 10h2a3 3 0 0 1 0 6h-2"/>
				<path d="M8 3v2M12 3v2"/>
			</svg>
			<div><strong>Ghé xưởng nếm thử</strong><span>Thứ 7 hằng tuần, 9:00 – 11:00</span></div>
		</div>
	</div>
</div>

<section class="section" id="san-pham">
	<div class="container">
		<div class="section-head">
			<span class="eyebrow">Sản phẩm</span>
			<h2>Chọn vị cà phê của bạn</h2>
			<p class="lead">Bốn gu rang quen thuộc, đóng túi 250g và 500g. Mỗi túi đều ghi ngày rang trên nhãn.</p>
		</div>

		<div class="product-grid">
			<?php
			$products = new WP_Query(
				array(
					'post_type'      => 'san_pham',
					'posts_per_page' => 4,
					'orderby'        => array(
						'menu_order' => 'ASC',
						'date'       => 'ASC',
					),
					'no_found_rows'  => true,
				)
			);

			if ( $products->have_posts() ) :
				while ( $products->have_posts() ) :
					$products->the_post();
					annhien_product_card( get_the_ID() );
				endwhile;
				wp_reset_postdata();
			else :
				?>
				<p class="lead">Sản phẩm đang được cập nhật. Vui lòng quay lại sau.</p>
			<?php endif; ?>
		</div>

		<div class="section-footer">
			<a class="btn btn--ghost" href="<?php echo esc_url( get_post_type_archive_link( 'san_pham' ) ); ?>">
				Xem tất cả sản phẩm
			</a>
		</div>
	</div>
</section>

<section class="section section--flush-top">
	<div class="container story">
		<div class="story__art">
			<img src="<?php echo esc_url( get_theme_file_uri( 'assets/img/story.svg' ) ); ?>"
				alt="Cành cà phê chín mọng" width="560" height="480" loading="lazy">
		</div>
		<div>
			<span class="eyebrow">Câu chuyện</span>
			<h2>Từ vườn nhỏ đến tách cà phê của bạn</h2>
			<p>
				Chúng tôi làm việc trực tiếp với các hộ trồng cà phê quanh Buôn Ma Thuột.
				Hạt chín được hái tay, sơ chế và rang tại xưởng nhỏ, không qua trung gian.
			</p>
			<ul class="checklist">
				<li>
					<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 13 4 4 10-10"/></svg>
					Thu mua trực tiếp, giá ổn định cho người trồng
				</li>
				<li>
					<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 13 4 4 10-10"/></svg>
					Rang mộc, ghi ngày rang trên từng túi
				</li>
				<li>
					<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 13 4 4 10-10"/></svg>
					Đóng gói trong 24 giờ sau khi rang
				</li>
			</ul>
		</div>
	</div>
</section>

<section class="quote">
	<div class="container">
		<blockquote>
			“Một túi cà phê tốt không cần quá nhiều chữ nghĩa — chỉ cần đúng hạt, đúng lửa và đúng ngày rang.”
			<cite>An Nhiên · Xưởng rang Buôn Ma Thuột</cite>
		</blockquote>
	</div>
</section>

<?php
get_footer();
