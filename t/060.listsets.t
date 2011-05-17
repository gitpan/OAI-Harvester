use Test::More no_plan; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listSets();
isa_ok( $l, 'Net::OAI::ListSets', 'listSets()' );

my @specs = $l->setSpecs();
ok( scalar(@specs) > 1, 'setSpecs() returns a list of specs' ); 

foreach (@specs ) { 
    ok( $l->setName( $_ ), "setName(\"$_\") = " . $l->setName( $_ ) );
}

ok( ! $l->errorCode(), 'errorCode()' );
ok( ! $l->errorString(), 'errorString()' );

