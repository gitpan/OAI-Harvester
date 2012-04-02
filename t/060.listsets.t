use Test::More tests => 7; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);

my $l = $h->listSets();
isa_ok( $l, 'Net::OAI::ListSets', 'listSets()' );

my $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 4 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    my @specs = $l->setSpecs();
    ok( scalar(@specs) > 1, 'setSpecs() returns a list of specs' ); 

    subtest 'Enumerate SetSpecs' => sub {
        foreach (@specs ) { 
            ok( $l->setName( $_ ), "setName(\"$_\") = " . $l->setName( $_ ) );
          }
      };
}
