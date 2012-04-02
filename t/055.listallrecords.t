use Test::More tests => 5; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);

my $l = $h->listAllRecords(
    'metadataPrefix'	=> 'oai_dc',
    'set'		=> 'lcposters'
);

my $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 3 if $HTE;

    my $token = $l->resumptionToken();
    isa_ok( $token, 'Net::OAI::ResumptionToken' );

    subtest 'Collect result' => sub {
        my $count = 0;
        my (%oai_seen, %meta_seen);
        while ( my $r = $l->next() ) {
            isa_ok( $r, "Net::OAI::Record" );
            my $oid = $r->header()->identifier();
            ok( ! exists( $oai_seen{ $oid } ), "$oid not seen before" );
            $oai_seen{ $oid } = 1;
            my $mid = $r->metadata()->identifier();
            ok( $mid , "metadata contains dc:identifier" );
            ok( ! exists( $meta_seen{ $mid } ), "$mid not seen before" );
            $meta_seen{ $mid } = 1;

            $count++;
            last if $token ne $l->resumptionToken();
        }
    };

    ok( $l->resumptionToken(), 'listAllIdentifiers grabbed resumption token' );
}


