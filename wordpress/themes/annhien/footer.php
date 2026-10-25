<?php
/**
 * Phần chân trang.
 *
 * @package annhien
 */
?>
</main>

<footer class="site-footer">
	<div class="container">
		<div class="footer-grid">
			<div>
				<span class="brand__name"><?php bloginfo( 'name' ); ?></span>
				<span class="brand__tagline"><?php bloginfo( 'description' ); ?></span>
				<p class="footer-about">
					Cà phê rang mộc từ hạt Robusta và Arabica trồng tại Đắk Lắk,
					rang mới mỗi tuần và ghi ngày rang trên từng túi.
				</p>
			</div>

			<div class="footer-col">
				<h3>Khám phá</h3>
				<?php
				wp_nav_menu(
					array(
						'theme_location' => 'footer',
						'container'      => false,
						'menu_class'     => '',
						'menu_id'        => 'menu-chan-trang',
						'depth'          => 1,
						'fallback_cb'    => 'annhien_menu_fallback',
					)
				);
				?>
			</div>

			<div class="footer-col">
				<h3>Liên hệ</h3>
				<ul>
					<li><a href="tel:+84901234567">0901 234 567</a></li>
					<li><a href="mailto:hello@annhien.vn">hello@annhien.vn</a></li>
					<li><p>Buôn Ma Thuột, Đắk Lắk</p></li>
					<li><p>Thứ 2 – Thứ 7, 8:00 – 18:00</p></li>
				</ul>
			</div>
		</div>

		<div class="footer-bottom">
			<span>© <?php echo esc_html( gmdate( 'Y' ) ); ?> <?php bloginfo( 'name' ); ?>. Rang mộc tại Việt Nam.</span>
			<span>Website quảng bá sản phẩm — Đề 3, Triển khai &amp; Quản trị hệ thống phần mềm.</span>
		</div>
	</div>
</footer>

<?php wp_footer(); ?>
</body>
</html>
