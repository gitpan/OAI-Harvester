use Test::More tests => 13;

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

## a good call

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $i = $h->identify();
isa_ok( $i, 'Net::OAI::Identify', 'identity()' );

ok( ! $i->errorCode(), 'errorCode()' );
ok( ! $i->errorString(), 'errorString()' );

like( $i->repositoryName(), qr/Library of Congress/, 'repositoryName()');
like( $i->protocolVersion(), qr/^2\.0$/, 'protocolVersion()' );
like( $i->earliestDatestamp(), qr/^\d{4}-\d{2}-\d{2}/, 'earliestDatestamp()' );
like( $i->deletedRecord(), qr/yes|no/, 'deletedRecord()' );
like( $i->granularity(), qr/^YYYY/, 'granularity()' );

my $email = $i->adminEmail();
my @emails = $i->adminEmail();
like( $email, qr/@/, 'adminEmail() scalar context' );
like( $emails[0], qr/@/, 'adminEmail() list context' ); 

## make sure we can call them, even though they are optional
my $compression = $i->compression();
my @compressions = $i->compression();

## make sure we don't get stuff from sub descriptions
$h = Net::OAI::Harvester->new( 
    baseURL => 'http://oaigateway.grainger.uiuc.edu/oai.asp' 
);
$i = $h->identify();
is( 
    $i->repositoryName(), 
    'University of Illinois Library at Urbana-Champaign, OAI Gateway',
    'do not extract sub descriptions and run them together'
);

