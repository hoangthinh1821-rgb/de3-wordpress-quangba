<?php
/**
 * Trang tĩnh (Câu chuyện, Liên hệ...).
 *
 * @package annhien
 */

get_header();

while ( have_posts() ) :
	the_post();
	?>
	<div class="page-head">
		<div class="container">
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
