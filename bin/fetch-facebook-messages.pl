#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(decode);
use Mojo::File;
use Mojo::Log;
use MongoDB;
use Try::Tiny;
use FindBin qw($Bin);

my $log = Mojo::Log->new;
# load config file
my $config = parse_config("$Bin/../in_touch.conf");

# db stuff
my ($mongo_host, $mongo_port) = $config->{'mongo_host'} =~ m{^([^:]+):(\d+)$};
my $client = MongoDB::Connection->new(host => $mongo_host, port => $mongo_port);
my $db     = $client->get_database( $config->{'mongo_db'} );
my $coll   = $db->get_collection( 'intouch' );

# fetch message list
my $ua = Mojo::UserAgent->new;
my $req_url = "https://graph.facebook.com/v2.8/" . 
    $config->{'facebook'}->{'page_name'} . "/conversations?access_token=" . 
    $config->{'facebook'}->{'token_ref'};
my $tx = $ua->get($req_url);
if (my $res = $tx->success) {
    
    my $body = decode_json $res->body;
    
    # loop through individual messages
    for my $d (@{$body->{'data'}}) {
        my $msg_id = $d->{'id'};
        
        $tx = $ua->get('https://graph.facebook.com/v2.8/' . 
            $msg_id . '?fields=snippet,updated_time,link&access_token=' . 
            $config->{'facebook'}->{'token_ref'});

        if (my $res = $tx->success) {
            my $json = decode_json $res->body;
            next unless $json->{'snippet'};
            next if $json->{'snippet'} =~ m{^http};
            
            my $msg = encode_json({text => $json->{'snippet'}});
            $msg =~ s!'!'\\''!g; # escape single quotes for command line input

            # set creds if exists
            my $creds = '';
            if ($config->{'google_nlp'}->{'creds'}->{'app'}) {
                $creds = "--creds='" . $config->{'google_nlp'}->{'creds'}->{'app'} . "'";
            }

            my $resp = {};
            try {
                # run python script to get NLP data
                # returns a JSON object w/ sentiment & entity info
                $resp = decode_json `python $Bin/../bin/google-nlp.py '$msg' $creds`;
            } catch {
                $log->info("Error gathering NLP data $_");
            };
            
            my $result = $coll->insert({
                medium => "Facebook Inbox",
                msg => $json->{'snippet'},
                msg_id => $msg_id,
                site => $config->{'facebook'}->{'site_name'},
                datetime => $json->{'updated_time'},
                sentiment => $resp->{'sentiment'},
                entities => $resp->{'entities'},
            });
        } else {
            $log->info("Error fetching message: " . $tx->res->code . ' ' . $tx->res->message);
        }
    }
} else {
    $log->info('Error fetching Facebook inbox: ' . $tx->res->code . ' ' . $tx->res->message);
}

sub parse_config {
    my $file = shift;
    my $path = Mojo::File->new($file);
    my $content = decode('UTF-8', $path->slurp);

    my $config
        = eval 'package Mojolicious::Plugin::Config::Sandbox; no warnings;'
            . "use Mojo::Base -strict; $content";
    die qq{Couldn't load configuration from file "$file": $@} if !$config && $@;
    die qq{Config file "$file" did not return a hash reference.\n}
        unless ref $config eq 'HASH';

    return $config;
}