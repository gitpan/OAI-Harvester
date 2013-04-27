use Test::More tests => 8; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

my $l = $h->listSets();
isa_ok( $l, 'Net::OAI::ListSets', 'listSets()' );

my $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 5 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    subtest 'OAI request/response' => sub {
        plan tests => 3;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $url, 'OAI response element text' );
        is($la{ verb }, 'ListSets', 'OAI verb' );
      };

    my @specs = $l->setSpecs();
    ok( scalar(@specs) > 1, 'setSpecs() returns a list of specs' ); 

    subtest 'Enumerate SetSpecs' => sub {
        foreach (@specs ) { 
            ok( $l->setName( $_ ), "setName(\"$_\") = " . $l->setName( $_ ) );
          }
      };
}
