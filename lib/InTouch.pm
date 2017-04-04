package InTouch;
use Mojo::Base 'Mojolicious';
use MongoDB;

# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');
	# load config file
	my $config = $self->plugin('Config');

	# MongoDB connection
	$self->attr(db => sub { 
	MongoDB::MongoClient
		->new( timeout => 300000, query_timeout => 300000 )
		->get_database($config->{'mongo_db'});
	});
	$self->helper('db' => sub { shift->app->db });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get('/')->to('core#home');

	$r->post('/save-form')->to( 'core#save_form' );
	$r->any('/create')->to( 'core#create' );
	$r->any('/dashboard')->to( 'core#dash' );
	$r->any('/save')->to( 'core#save' );
}

1;
