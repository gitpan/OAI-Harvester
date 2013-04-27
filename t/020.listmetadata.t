use Test::More tests => 14;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

my $l = $h->listMetadataFormats();
isa_ok( $l, 'Net::OAI::ListMetadataFormats', 'listMetadataFormats()' );

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
        plan tests => 3;
        like($l->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($lt, %la) = $l->request();
        is($lt, $url, 'OAI response element text' );
        is($la{ verb }, 'ListMetadataFormats', 'OAI verb' );
     };

    my @prefixes = $l->prefixes();
    is( @prefixes, 4, 'prefixes()' );
    my @hasoai_dc = grep /^oai_dc$/, @prefixes;
    is( @hasoai_dc, 1, 'standard prefix oai_dc is supplied' );

    my @namespaces = $l->namespaces();
    is( @namespaces, 4, 'namespaces()' );

    is( $l->namespaces_byprefix('oai_dc'), 'http://www.openarchives.org/OAI/2.0/oai_dc/', 'correct namespace for oai_dc');

    my @schemas = $l->schemas();
    is( @schemas, 4, 'schemas()' );

    is( $l->schemas_byprefix('oai_dc'), 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd', 'correct schema location for oai_dc');
}

$l = $h->listMetadataFormats( identifier => 123 );
undef $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 2 if $HTE;

    is( $l->errorCode(), 'idDoesNotExist', 'expected error code' );
    is( $l->errorString(), 'id not found', 'expected errorString()' );
}

