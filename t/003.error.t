use Test::More tests => 6;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## HTTP Error

subtest 'Bad host' => sub {
    plan tests => 8;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://xxx.yahoo.com' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    my $e = $i->HTTPError();
    isa_ok ($e, 'HTTP::Response');
    is ($e->code, 404, 'HTTP error code');
    is( ($e->message ? "exists" : "absent"), 'exists', 'HTTP error text');
    like( $e->status_line, qr/^404 \S/, 'HTTP status line');
    
    is( $i->errorCode(), '404', 'Caught HTTP error ('.$i->errorCode().')' );
    like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Caught HTTP error ('.$i->errorString().')' );
};

subtest 'Bad URL path' => sub {
    plan tests => 8;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://memory.loc.gov/cgi-bin/nonexistant_oai_handler' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    my $e = $i->HTTPError();
    isa_ok ($e, 'HTTP::Response');
    is ($e->code, 404, 'HTTP error code');
    is( ($e->message ? "exists" : "absent"), 'exists', 'HTTP error text');
    like( $e->status_line, qr/^404 \S/, 'HTTP status line');
    
    is( $i->errorCode(), '404', 'Caught HTTP error ('.$i->errorCode().')' );
    like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Caught HTTP error ('.$i->errorString().')' );
};

## XML Content or Parsing Error

subtest 'content error' => sub {
    plan tests => 4;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.yahoo.com' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    is( ($i->HTTPError ? "exists" : "absent"), 'absent', 'No HTTP error response');

# XML::LibXML::SAX does not return error codes properly
#SKIP: {
#   skip( 'XML::LibXML::SAX does not return errors', 1 )
#	if ref( XML::SAX::ParserFactory->parser() ) eq 'XML::LibXML::SAX';
    is( $i->errorCode(), 'xmlContentError', 'caught XML content error' );
#}
};

## Missing parameter

subtest 'missing parameter' => sub {
    plan tests => 3;

    my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);
    my $l = $h->listRecords( 'metadataPrefix' => undef );
    isa_ok( $l, 'Net::OAI::ListRecords' );

    my $HTE;
    if ( my $e = $l->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
      }
    SKIP: {
        skip $HTE, 1 if $HTE;

        is($l->errorCode(), 'badArgument', 'parsed OAI error code from server');
    }
};

subtest 'unsuitable parameter' => sub {
    plan tests => 3;

    my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);
    my $r = $h->listRecords( 'metadataPrefix' => 'argh' );
    isa_ok( $r, 'Net::OAI::ListRecords' );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }
    SKIP: {
        skip $HTE, 1 if $HTE;

        is($r->errorCode(), 'cannotDisseminateFormat', 'parsed OAI error code from server');
    }
};

