use Test::More no_plan; 

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0'
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listAllRecords(
    'metadataPrefix'	=> 'oai_dc',
    'set'		=> 'lcposters'
);

my $count = 0;
my %seen = ();

while ( my $r = $l->next() ) {
    isa_ok( $r, "Net::OAI::Record" );
    my $id = $r->header()->identifier();
    ok( ! exists( $seen{ $id } ), "$id not seen before" );
    $seen{ $id } = 1;
    $count++;
    last if $count > 200;
}

ok( $count > 200, 'listAllRecords() submitted resumption tokens' );

