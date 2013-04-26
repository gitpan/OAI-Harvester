use Test::More tests => 7;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## HTTP Error

subtest 'Bad host' => sub {
    plan tests => 8;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.domain.invalid' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    like( $i->errorCode(), qr/^50[03]$/, 'Caught HTTP error ('.$i->errorCode().')' );
    like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Caught HTTP error ('.$i->errorString().')' );

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate DNS error?", 4 unless defined $e;

        isa_ok( $e, 'HTTP::Response' );

        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^50[03] \S/, 'HTTP status line' );
      }
};

subtest 'Cannot connect' => sub {
    plan tests => 8;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.google.com:54321/' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    like( $i->errorCode(), qr/^(404|50[034])/, 'Caught HTTP error ('.$i->errorCode().')' );
    like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Caught HTTP error ('.$i->errorString().')' );

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate no connection error?", 4 unless defined $e;

        isa_ok( $e, 'HTTP::Response' );
        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^(404|50[034]) \S/, 'HTTP status line' );
      }
};

subtest 'Bad URL path' => sub {
    plan tests => 8;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://memory.loc.gov/cgi-bin/nonexistant_oai_handler' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

    is( $i->errorCode(), '404', 'Caught HTTP error ('.$i->errorCode().')' );
    like( $i->errorString(), qr/^HTTP Level Error: \S/, 'Caught HTTP error ('.$i->errorString().')' );

    my $e = $i->HTTPError();
    SKIP: {
        skip "LWP did not propagate bad error?", 4 unless defined $e;

        isa_ok( $e, 'HTTP::Response' );
        is( $e->code, $i->errorCode(), 'HTTP error code' );
        is( ($e->message ? 'exists' : 'absent'), 'exists', 'HTTP error text' );
        like( $e->status_line, qr/^404 \S/, 'HTTP status line' );
      }
};

## XML Content or Parsing Error

subtest 'content parsing error' => sub {
    plan tests => 3;
    my $h = new_ok('Net::OAI::Harvester' => [ 'baseURL' => 'http://www.yahoo.com' ]);

    my $i = $h->identify();
    isa_ok( $i, 'Net::OAI::Identify' );

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

