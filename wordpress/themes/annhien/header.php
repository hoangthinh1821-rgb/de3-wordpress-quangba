<?php
/**
 * Phần đầu trang.
 *
 * @package annhien
 */
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<a class="skip-link" href="#noi-dung">Bỏ qua điều hướng</a>

<div class="site-topbar">
	Rang mộc mỗi tuần · Miễn phí giao hàng nội thành Buôn Ma Thuột cho đơn từ 300.000đ
</div>

<header class="site-header">
	<div class="container header-inner">
		<a class="brand" href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home">
			<span class="brand__name"><?php bloginfo( 'name' ); ?></span>
			<span class="brand__tagline"><?php bloginfo( 'description' ); ?></span>
		</a>

		<nav class="primary-nav" id="menu-chinh" aria-label="Điều hướng chính">
			<?php
			wp_nav_menu(
				array(
					'theme_location' => 'primary',
					'container'      => false,
					'menu_class'     => 'nav-list',
					'menu_id'        => 'menu-chinh-list',
					'depth'          => 1,
					'fallback_cb'    => 'annhien_menu_fallback',
				)
			);
			?>
		</nav>

		<a class="btn header-cta" href="<?php echo esc_url( home_url( '/lien-he/' ) ); ?>">Đặt hàng</a>

		<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="menu-chinh">
			<span class="screen-reader-text">Mở menu</span>
			<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
				<path d="M4 7h16M4 12h16M4 17h16"/>
			</svg>
		</button>
	</div>
</header>

<main id="noi-dung">
