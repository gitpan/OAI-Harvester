use Test::More tests => 7;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## HTTP Error

subtest 'Bad host' => sub {
    plan tests => 9;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.domain.invalid' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );
    is( $i->is_error(), -1, 'is_error == -1 for no valid OAI response');

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate DNS resolution issue?", 6 unless defined $e;

        like( $i->errorCode(), qr/^50[03]$/, 'Catch HTTP error code ('.$i->errorCode().')' );
        like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Catch HTTP error string ('.$i->errorString().')' );

        isa_ok( $e, 'HTTP::Response' );

        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^50[03] \S/, 'HTTP status line' );
      }
};

subtest 'Cannot connect' => sub {
    plan tests => 9;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.google.com:54321/' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );
    is( $i->is_error(), -1, 'is_error == -1 for no valid OAI response');

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate no connection error?", 6 unless defined $e;

        like( $i->errorCode(), qr/^(404|50[034])/, 'Catch HTTP error code ('.$i->errorCode().')' );
        like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Catch HTTP error string ('.$i->errorString().')' );

        isa_ok( $e, 'HTTP::Response' );
        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^(404|50[034]) \S/, 'HTTP status line' );
      }
};

subtest 'Bad URL path' => sub {
    plan tests => 9;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://memory.loc.gov/cgi-bin/nonexistant_oai_handler' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );
    is( $i->is_error(), -1, 'is_error == -1 for no valid OAI response');

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate HTTP path error?", 6 unless defined $e;

        is( $i->errorCode(), '404', 'Catch HTTP error code ('.$i->errorCode().')' );
        like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Catch HTTP error string ('.$i->errorString().')' );

        isa_ok( $e, 'HTTP::Response' );
        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^404 \S/, 'HTTP status line' );
      }
};

## XML Content or Parsing Error

subtest 'content parsing error' => sub {
    plan tests => 4;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.yahoo.com' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );
    is( $i->is_error(), -1, 'is_error == -1 for no valid OAI response');

    my $HTE;
    if ( my $e = $i->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: " . $i->HTTPRetryAfter() . "]" if $e->code() == 503;
      }
    SKIP: {
        skip $HTE, 1 if $HTE;

        like( $i->errorCode(), qr/^xml(Content|Parse)Error$/, 'caught XML content error' );
      }
};

## Missing parameter

subtest 'missing parameter' => sub {
    plan tests => 5;

    my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);
    my $l = $h->listRecords( 'metadataPrefix' => undef );
    isa_ok( $l, 'Net::OAI::ListRecords' );

    my $HTE;
    if ( my $e = $l->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
      }
    SKIP: {
        skip $HTE, 3 if $HTE;

        is($l->is_error(), 1, 'is_error == 1 for OAI error response');
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        is($l->errorCode(), 'badArgument', 'parsed OAI error code from server');
    }
};

subtest 'unsuitable parameter' => sub {
    plan tests => 5;

    my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);
    my $r = $h->listRecords( 'metadataPrefix' => 'argh' );
    isa_ok( $r, 'Net::OAI::ListRecords' );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }
    SKIP: {
        skip $HTE, 3 if $HTE;

        is($r->is_error(), 1, 'is_error == 1 for OAI error response');
        like($r->responseDate(), qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'OAI responseDate element' );
        is($r->errorCode(), 'cannotDisseminateFormat', 'parsed OAI error code from server');
    }
};

