use Test::More tests => 15;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## a good call

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

my $i = $h->identify();
isa_ok( $i, 'Net::OAI::Identify', 'identity()' );

my $HTE;
if ( my $e = $i->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$i->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 10 if $HTE;

    ok( ! $i->errorCode(), 'errorCode()' );
    ok( ! $i->errorString(), 'errorString()' );

    subtest 'OAI request/response' => sub {
        plan tests => 3;
        like($i->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($it, %ia) = $i->request();
        is($it, $url, 'OAI response element text' );
        is($ia{ verb }, 'Identify', 'OAI verb' );
      };

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
}

## make sure we don't get stuff from sub descriptions
$h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://oaigateway.grainger.uiuc.edu/oai.asp' ]);
$i = $h->identify();
undef $HTE;
if ( my $e = $i->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$i->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 1 if $HTE;

    is( $i->repositoryName(), 
        'University of Illinois Library at Urbana-Champaign, OAI Gateway',
        'do not extract sub descriptions and run them together'
    );
}


