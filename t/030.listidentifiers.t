use Test::More no_plan; 

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listIdentifiers( metadataPrefix => 'mods' );
isa_ok( $l, 'Net::OAI::ListIdentifiers', 'listIdentifiers()' );

ok( ! $l->errorCode(), 'errorCode()' );
ok( ! $l->errorString(), 'errorString()' );

while( my $h = $l->next() ) {
    isa_ok( $h, 'Net::OAI::Record::Header' ),
    ok( $h->identifier, "identifier() ".$h->identifier() );
    my @sets = $h->sets();
    ok( @sets >= 1, "sets() ".join( ";", @sets ) );
}

## resumption token

my $r = $l->resumptionToken();
isa_ok( $r, 'Net::OAI::ResumptionToken' );
ok( $r->token(), 'token() '.$r->token() );

## these may not return stuff but we must be able to call the methods
eval { $r->expirationDate() }; 
ok( ! $@, 'expirationDate()' );

eval { $r->completeListSize() };
ok( ! $@, 'completeListSize()' );

eval { $r->cursor() };
ok( ! $@, 'cursor()' );

## using from/until

$l = $h->listIdentifiers( 
    'metadataPrefix'	=> 'mods',
    'from'		=> '0005-01-01',
    'until'		=> '0005-01-02'
);

is( $l->errorCode(), 'noRecordsMatch', 'from/until' );

