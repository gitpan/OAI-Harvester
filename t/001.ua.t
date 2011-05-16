use Test::More tests => 4;
use strict;
use warnings;

use_ok( 'LWP::UserAgent' );
use_ok( 'Net::OAI::Harvester' );

my $ua1 = LWP::UserAgent->new();
$ua1->agent( 'FooBar' );

my $h = Net::OAI::Harvester->new( 
    baseUrl	=> 'http://www.yahoo.com', 
    userAgent	=> $ua1 
);

my $ua2 = $h->userAgent();

isa_ok( $ua2, 'LWP::UserAgent' );
is( $ua2->agent(), 'FooBar', 'get/set ua' );
