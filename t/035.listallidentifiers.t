use Test::More no_plan; 

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0'
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listAllIdentifiers(
    'metadataPrefix'	=> 'oai_dc',
    'set'		=> 'lcposters'
);

my $token = $l->resumptionToken();

my $count = 0;
my %seen = ();
while ( my $i = $l->next() ) {
    isa_ok( $i, "Net::OAI::Record::Header" );
    my $id = $i->identifier();
    ok( ! exists( $seen{ $id } ), "$id not seen before" );
    $seen{ $id } = 1;
    $count++;
}

ok( $count > 2000, 'listAllIdentifiers() submitted resumption tokens' );
