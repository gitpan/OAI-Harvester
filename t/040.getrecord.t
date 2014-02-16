use Test::More tests => 12; 

use strict;
use warnings;
use lib qw( t );
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';
## get a known ID (this may have to change over time)
my $id = 'oai:lcoa1.loc.gov:loc.gmd/g3764s.pm003250';

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => $repo ]);

my $rr = $h->getRecord( identifier => $id, metadataPrefix => 'oai_dc' );

my $HTE = HTE($rr, $repo);

SKIP: {
    skip $HTE, 4 if $HTE;

    subtest 'OAI request/response' => sub {
        plan tests => 7;

        ok( ! $rr->errorCode(), "errorCode()" );
        ok( ! $rr->errorString(), "errorString()" );
        like($rr->responseDate(), qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, 'OAI responseDate element' );
        my ($rt, %ra) = $rr->request();
        is($rt, $repo, 'OAI response element text' );
        is($ra{ verb }, 'GetRecord', 'OAI verb' );
        is($ra{ metadataPrefix }, 'oai_dc', 'OAI metadata Prefix' );
        is($ra{ identifier }, $id, 'OAI identifier' );
     };

    my $oairecord = $rr->record();
    isa_ok( $oairecord, 'Net::OAI::Record' );

    my $header = $rr->header();
    isa_ok( $header, 'Net::OAI::Record::Header' );
  SKIP: {
    skip 'no sense in exploring further', 1 unless $header;
    is( $header->identifier, $id, 'OAI identifier()' );
    }
};

subtest 'default oai_dc handler' => sub {
    plan tests => 3;
    my $dc = $rr->metadata();
    isa_ok( $dc, 'Net::OAI::Record::OAI_DC' );
  SKIP: {
    skip 'no sense in exploring further', 2 unless $dc;
    is( $dc->title(), 'View of Springfield, Mass. 1875.', 'got dc:title from record' );
    is( $dc->identifier(), 'http://hdl.loc.gov/loc.gmd/g3764s.pm003250', 'got dc:identifier from record' );
   }
};

subtest 'a custom metadata handler' => sub {
    plan tests => 4;

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> 'MyMDHandler',
    );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 4 if $HTE;

    ok( ! defined $r->errorCode(), 'request should not give any error');

    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'MyMDHandler' );

  SKIP: {
    skip 'no sense in exploring further', 1 unless $metadata;
    is( $metadata->title(), 'View of Springfield, Mass. 1875.', 'custom metadata handler works' );
    }
  }
};

subtest 'another custom metadata handler' => sub {
    plan tests => 5;

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> 'YourMDHandler',
    );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 5 if $HTE;

    ok( ! defined $r->errorCode(), 'request should not give any error');
    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourMDHandler' );
    isa_ok( $metadata, 'MyMDHandler' );
  SKIP: {
    skip 'no sense in exploring further', 1 unless $metadata;
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom metadata handler works' );
    }
  }
};

subtest 'custom record handler' => sub {
    plan tests => 5;
    my $r = $h->getRecord( 
    identifier		=> $id, 
    metadataPrefix	=> 'oai_dc',
    recordHandler	=> 'MyRCHandler',
    );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 5 if $HTE;

    ok( ! defined $r->errorCode(), 'request should not give any error');
    ok( ! defined $r->metadata(), 'custom record handler does not deliver metadata' );
    my $record = $r->alldata();
    isa_ok( $record, 'MyRCHandler' );
  SKIP: {
    skip 'no sense in exploring further', 2 unless $record;
    is( $record->title(), 'View of Springfield, Mass. 1875.', 'custom record handler works for metadata' );
    is( $record->OAIdentifier(), $id, 'custom record handler works for header' );
    }
  }
};


subtest 'instance of a custom metadata handler' => sub {
    plan tests => 8;
    use_ok( 'YourMDHandler' );
    my $customMDhandler = new_ok('YourMDHandler');
    isa_ok( $customMDhandler, 'XML::SAX::Base' );

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        metadataHandler	=> $customMDhandler,
    );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 5 if $HTE;

    ok( ! defined $r->errorCode(), 'request should not give any error');

    ok( ! defined $r->alldata(), 'custom metadata handler does not deliver all data' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'YourMDHandler' );
    isa_ok( $metadata, 'MyMDHandler' );
  SKIP: {
    skip 'no sense in exploring further', 1 unless $metadata;
    is( $metadata->result(), 'View of Springfield, Mass. 1875.', 'custom metadata handler instance works' );
    }
  }
};


subtest 'instance of a custom record handler' => sub {
    plan tests => 9;
    use_ok( 'YourRCHandler' );
    my $customRChandler = new_ok('YourRCHandler');
    isa_ok( $customRChandler, 'XML::SAX::Base' );

    my $r = $h->getRecord( 
        identifier	=> $id, 
        metadataPrefix	=> 'oai_dc',
        recordHandler	=> $customRChandler,
    );

SKIP: {
    my $HTE = HTE($r, $repo);
    skip $HTE, 6 if $HTE;

    ok( ! defined $r->errorCode(), 'request should not give any error');
    ok( ! defined $r->metadata(), 'custom record instance does not return metadata flavor of record');
    my $record = $r->alldata();
    isa_ok( $record, 'YourRCHandler' );
    isa_ok( $record, 'MyRCHandler' );
  SKIP: {
    skip 'no sense in exploring further', 2 unless $record;
    is( $record->result_t(), 'View of Springfield, Mass. 1875.', 'custom record handler instance works for metadata' );
    is( $record->result_i(), $id, 'custom record handler instance works for header' );
    }
  }
};


sub HTE {
    my ($r, $url) = @_;
    my $hte;
    if ( my $e = $r->HTTPError() ) {
        $hte = "HTTP Error ".$e->status_line;
	$hte .= " [Retry-After: ".$r->HTTPRetryAfter()."]" if $e->code() == 503;
	diag("LWP condition when accessing $url:\n$hte");
        note explain $e;
      }
   return $hte;
}

