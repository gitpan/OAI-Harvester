use Test::More tests => 5; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);

my $l = $h->listAllIdentifiers(
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

    subtest 'Collect identifiers' => sub {
        my $count = 0;
        my %seen = ();
        while ( my $i = $l->next() ) {
            isa_ok( $i, "Net::OAI::Record::Header" );
            my $id = $i->identifier();
            ok( ! exists( $seen{ $id } ), "$id not seen before" );
            $seen{ $id } = 1;
            $count++;
            last if $token ne $l->resumptionToken();
          };
    };

    ok( $l->resumptionToken(), 'listAllIdentifiers grabbed resumption token' );
}

