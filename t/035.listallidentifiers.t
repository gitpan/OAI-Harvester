use Test::More tests => 6; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

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
    skip $HTE, 4 if $HTE;

    my $token = $l->resumptionToken();
    isa_ok( $token, 'Net::OAI::ResumptionToken' );

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $url, 'OAI response element text' );
        is($la{ verb }, 'ListIdentifiers', 'OAI verb' );
        is($la{ set }, 'lcposters', 'OAI set' );
        is($la{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
     };

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

