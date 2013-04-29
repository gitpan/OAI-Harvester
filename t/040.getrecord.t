use Test::More tests => 16; 

use strict;
use warnings;
use lib qw( t );
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

    my $oairecord = $r->record();
    isa_ok( $oairecord, 'Net::OAI::Record' );

    my $header = $r->header();
    isa_ok( $header, 'Net::OAI::Record::Header' );
    is( $header->identifier, $id, 'OAI identifier()' );

## extract metadata and see if a few things are there 

    my $dc = $r->metadata();
    isa_ok( $dc, 'Net::OAI::Record::OAI_DC' );
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


subtest 'a custom metadata handler' => sub {
    plan tests => 3;

    $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> 'MyMDHandler',
    );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }

SKIP: {
    skip $HTE, 3 if $HTE;

    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'MyMDHandler' );
    is( $metadata->title(), 'View of Springfield, Mass. 1875.', 'custom metadata handler works' );
  }
};

subtest 'another custom metadata handler' => sub {
    plan tests => 4;

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> 'YourMDHandler',
    );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }

SKIP: {
    skip $HTE, 4 if $HTE;

    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourMDHandler' );
    isa_ok( $metadata, 'MyMDHandler' );
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom metadata handler works' );
  }
};

subtest 'custom record handler' => sub {
    plan tests => 4;
    my $r = $h->getRecord( 
    identifier		=> $id, 
    metadataPrefix	=> 'oai_dc',
    recordHandler	=> 'MyRCHandler',
    );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }

SKIP: {
    skip $HTE, 4 if $HTE;

    ok( ! defined $r->metadata(), 'custom record handler does not deliver metadata' );
    my $record = $r->alldata();
    isa_ok( $record, 'MyRCHandler' );
    is( $record->title(), 'View of Springfield, Mass. 1875.', 'custom record handler works for metadata' );
    is( $record->OAIdentifier(), $id, 'custom record handler works for header' );
  }
};


subtest 'instance of a custom metadata handler' => sub {
    plan tests => 7;
    use_ok( 'YourMDHandler' );
    my $customMDhandler = new_ok('YourMDHandler');
    isa_ok( $customMDhandler, 'XML::SAX::Base' );

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> $customMDhandler,
    );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }

SKIP: {
    skip $HTE, 4 if $HTE;

    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourMDHandler' );
    isa_ok( $metadata, 'MyMDHandler' );
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom metadata handler instance works' );
  }
};


subtest 'instance of a custom record handler' => sub {
    plan tests => 8;
    use_ok( 'YourRCHandler' );
    my $customRChandler = new_ok('YourRCHandler');
    isa_ok( $customRChandler, 'XML::SAX::Base' );

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        recordHandler	=> $customRChandler,
    );

    my $HTE;
    if ( my $e = $r->HTTPError() ) {
        $HTE = "HTTP Error ".$e->status_line;
        $HTE .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
      }

SKIP: {
    skip $HTE, 5 if $HTE;

    ok( ! defined $r->metadata(), 'custom record instance does not return metadata flavor of record');
    my $record = $r->alldata();
    isa_ok( $record, 'YourRCHandler' );
    isa_ok( $record, 'MyRCHandler' );
    is( $record->result_t(), 'View of Springfield, Mass. 1875.', 'custom record handler instance works for metadata' );
    is( $record->result_i(), $id, 'custom record handler instance works for header' );
  }
};


