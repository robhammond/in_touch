package InTouch::Controller::Core;
use Mojo::Base 'Mojolicious::Controller';

use DateTime;
use Mojo::Log;
use Mojo::JSON qw(decode_json encode_json);
use Data::Random qw(rand_chars);
use Try::Tiny;
use FindBin qw($Bin);

my $log = Mojo::Log->new;

sub home {
	my $self = shift;

	$self->render();
}

sub create {
	my $self = shift;

	$self->render();
}

sub dash {
	my $self = shift;

	my $db = $self->db;
	my $coll = $db->get_collection('intouch');

	my $res = $coll->find()->sort({ datetime => -1});
	my @doc = $res->all;

	$self->render(doc => \@doc);
}

sub save {
	my $self = shift;
	my $params;
	$params->{'medium'} = $self->param('medium');
	$params->{'site'} = $self->param('site');
	$params->{'msg'} = $self->param('msg');
	$params->{'others'} = $self->req->params->to_hash;
	my $dt = DateTime->now(time_zone => 'UTC');
	$params->{'datetime'} = $dt->ymd . 'T' . $dt->hms . '+0000';
	delete $params->{'others'}->{'medium'};
	delete $params->{'others'}->{'msg'};
	delete $params->{'others'}->{'site'};

	my $msg = encode_json({text => $self->param('msg')});
    $msg =~ s!'!'\\''!g;

    my $creds = '';
    if ($self->config->{'google_nlp'}->{'creds'}->{'app'}) {
    	$creds = "--creds='" . $self->config->{'google_nlp'}->{'creds'}->{'app'} . "'";
    }

    $params->{'sentiment'} = {};
    try {
    	my $response = `python $Bin/../bin/google-nlp.py '$msg' $creds`;
    	# $log->info($response);
    	my $json = decode_json $response;
    	$params->{'sentiment'} = $json->{'sentiment'};
    	$params->{'entities'} = $json->{'entities'};
    } catch {
    	$log->info("Error getting nlp: $_");
    };
	
	my $db = $self->db;
	my $coll = $db->get_collection('intouch');
	my $res = $coll->insert($params);

	$self->render(text => 'Form submitted successfully! Go to dashboard to see results');
}

sub save_form {
	my $self = shift;

	my $form = $self->param('form');
	my @key = rand_chars( set => 'alphanumeric', size => 15 );
	my $api_key = join('', @key);

	my $path = Mojo::File->new("$Bin/../public/forms/$api_key.html");
	$path->spurt($form);

	$self->render(text => $self->config->{'host'} . '/forms/' . $api_key . '.html');
}

1;