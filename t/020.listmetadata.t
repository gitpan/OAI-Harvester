use Test::More tests => 8;

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listMetadataFormats();
isa_ok( $l, 'Net::OAI::ListMetadataFormats', 'listMetadataFormats()' );

ok( ! $l->errorCode(), 'errorCode()' );
ok( ! $l->errorString(), 'errorString()' );

is( scalar( $l->prefixes() ), 4, 'prefixes() '.join( ';', $l->prefixes() ) );

$l = $h->listMetadataFormats( identifier => 123 );
is( $l->errorCode(), 'idDoesNotExist', 'expected error code' );
is( $l->errorString(), 'id not found', 'expected errorString()' );

