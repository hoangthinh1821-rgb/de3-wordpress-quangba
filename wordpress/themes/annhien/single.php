<?php
/**
 * Bài viết thường (blog).
 *
 * @package annhien
 */

get_header();

while ( have_posts() ) :
	the_post();
	?>
	<div class="page-head">
		<div class="container">
			<span class="eyebrow"><?php echo esc_html( get_the_date( 'd/m/Y' ) ); ?></span>
			<h1><?php the_title(); ?></h1>
		</div>
	</div>

	<article class="container">
		<div class="prose">
			<?php the_content(); ?>
		</div>
	</article>
	<?php
endwhile;

get_footer();
