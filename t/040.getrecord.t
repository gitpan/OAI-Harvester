use Test::More tests => 7; 

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

## get a known ID (this may have to change over time)

my $id = 'oai:lcoa1.loc.gov:loc.gmd/g3764s.pm003250';
my $r = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );
ok( ! $r->errorCode(), "errorCode()" );
ok( ! $r->errorString(), "errorString()" );

my $header = $r->header();
is( $header->identifier, $id, 'identifier()' );

## extract metadata and see if a few things are there 

my $dc = $r->metadata();
is( 
    $dc->title(), 
    'View of Springfield, Mass. 1875.',
    'got dc:title from record' 
);

is( 
    $dc->identifier(),
    'http://hdl.loc.gov/loc.gmd/g3764s.pm003250',
    'got dc:identifier from record' 
);


