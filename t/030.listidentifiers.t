use Test::More tests => 13;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

my $l = $h->listIdentifiers( metadataPrefix => 'mods' );
isa_ok( $l, 'Net::OAI::ListIdentifiers', 'listIdentifiers()' );

my $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 9 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    subtest 'OAI request/response' => sub {
        plan tests => 4;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $url, 'OAI response element text' );
        is($la{ verb }, 'ListIdentifiers', 'OAI verb' );
        is($la{ metadataPrefix }, 'mods', 'OAI metadata Prefix' );
      };

    subtest 'Collect Headers' => sub {
        while( my $h = $l->next() ) {
            isa_ok( $h, 'Net::OAI::Record::Header' ),
            ok( $h->identifier, "identifier() ".$h->identifier() );
            my @sets = $h->sets();
            ok( @sets >= 1, "sets() ".join( ";", @sets ) );
          }
        done_testing;
      };

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

  }

## using from/until

$l = $h->listIdentifiers( 
    'metadataPrefix'	=> 'mods',
    'from'		=> '1905-01-01',
    'until'		=> '1905-01-02'
);

undef $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 1 if $HTE;

    is( $l->errorCode(), 'noRecordsMatch', 'from/until' )
  };

