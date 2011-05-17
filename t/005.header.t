use Test::More tests=>14;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Record::Header' );

my $header1 = Net::OAI::Record::Header->new();
isa_ok( $header1, 'Net::OAI::Record::Header' );

# basic attributes

$header1->status( 'deleted' );
is( $header1->status(), 'deleted', 'status()' );

$header1->identifier( 'xxx' );
is( $header1->identifier(), 'xxx', 'identifier()' );

$header1->datestamp( 'May-28-1969' );
is( $header1->datestamp(), 'May-28-1969', 'datestatmp()' );

$header1->sets( 'foo', 'bar' );
my @sets1 = $header1->sets();
is( scalar(@sets1), 2, 'sets() 1' );
is( $sets1[0], 'foo', 'sets() 2' );
is( $sets1[1], 'bar', 'sets() 3' );

## fetch a record and see what the status is
## this may need to be changed over time

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://eprints.dcs.warwick.ac.uk/cgi/oai2' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $id = 'oai:generic.eprints.org:399';
my $r = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );
ok( ! $r->errorCode(), "errorCode()" );
ok( ! $r->errorString(), "errorString()" );

my $header = $r->header();
is( $header->identifier, $id, 'identifier()' );
is( $header->status(), 'deleted', 'status' );


