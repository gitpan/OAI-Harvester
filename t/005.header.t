use Test::More tests => 14;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Record::Header' );

my $header1 = new_ok('Net::OAI::Record::Header');

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

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://eprints.dcs.warwick.ac.uk/cgi/oai2' ]);

my $id = 'oai:eprints.dcs.warwick.ac.uk:399';
# this will fetch < http://eprints.dcs.warwick.ac.uk/cgi/oai2?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:eprints.dcs.warwick.ac.uk:399 >
# which hopefully exists and is an deleted record
my $r = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );

my $HTE;
if ( my $e = $r->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 4 if $HTE;

    ok( ! $r->errorCode(), "errorCode()" );
    ok( ! $r->errorString(), "errorString()" );

    my $header = $r->header();
    is( $header->identifier, $id, 'identifier()' );
    is( $header->status(), 'deleted', 'status' );
}

