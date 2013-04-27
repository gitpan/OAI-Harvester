use Test::More tests => 19; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $url = 'http://memory.loc.gov/cgi-bin/oai2_0';
my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $url ]);

## get a known ID (this may have to change over time)

my $id = 'oai:lcoa1.loc.gov:loc.gmd/g3764s.pm003250';
my $r = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );

my $HTE;
if ( my $e = $r->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 6 if $HTE;

    ok( ! $r->errorCode(), "errorCode()" );
    ok( ! $r->errorString(), "errorString()" );

    subtest 'OAI request/response' => sub {
        plan tests => 5;
        like($r->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($rt, %ra) = $r->request();
        is($rt, $url, 'OAI response element text' );
        is($ra{ verb }, 'GetRecord', 'OAI verb' );
        is($ra{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
        is($ra{ identifier }, $id, 'OAI identifier' );
     };

    my $header = $r->header();
    is( $header->identifier, $id, 'identifier()' );

## extract metadata and see if a few things are there 

    my $dc = $r->metadata();
    is( 
        $dc->title(), 
        'View of Springfield, Mass. 1875.',
        'got dc:title from record' 
    );

    is( 
        $dc->identifier(),
        'http://hdl.loc.gov/loc.gmd/g3764s.pm003250',
        'got dc:identifier from record' 
    );
}


## test a custom handler
use lib qw( t );

$r = $h->getRecord( 
    identifier		=> $id, 
    metadataPrefix	=> 'oai_dc',
    metadataHandler	=> 'MyHandler',
);

undef $HTE;
if ( my $e = $r->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 2 if $HTE;

    my $metadata = $r->metadata();
    isa_ok( $metadata, 'MyHandler' );
    is( $metadata->title(), 'View of Springfield, Mass. 1875.', 'custom handler works' );
  }

## test another custom handler

$r = $h->getRecord( 
    identifier		=> $id, 
    metadataPrefix	=> 'oai_dc',
    metadataHandler	=> 'YourHandler',
);

undef $HTE;
if ( my $e = $r->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 3 if $HTE;

    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourHandler' );
    isa_ok( $metadata, 'MyHandler' );
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom handler works' );
};

## test based on instance of a custom handler

use_ok( 'YourHandler' );
my $customhandler = new_ok('YourHandler');
isa_ok( $customhandler, 'XML::SAX::Base' );
$r = $h->getRecord( 
    identifier		=> $id, 
    metadataPrefix	=> 'oai_dc',
    metadataHandler	=> $customhandler,
);

undef $HTE;
if ( my $e = $r->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
  }

SKIP: {
    skip $HTE, 3 if $HTE;

    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourHandler' );
    isa_ok( $metadata, 'MyHandler' );
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom handler works' );
}


