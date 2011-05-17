use Test::More no_plan; 

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listRecords( metadataPrefix => 'oai_dc', set => 'papr' );
isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords()' );

ok( ! $l->errorCode(), 'errorCode()' );
ok( ! $l->errorString(), 'errorString()' );

while ( my $r = $l->next() ) { 
    isa_ok( $r, 'Net::OAI::Record' );
    my $header = $r->header();
    isa_ok( $header, 'Net::OAI::Record::Header' );
    ok( $header->identifier(), 
	'header identifier defined: '.$header->identifier() );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'Net::OAI::Record::OAI_DC' );
    ok( $metadata->title(), 
	'metadata title defined: '.$metadata->title() );
}

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

use lib qw( t ); ## so harvester will be able to locate our handler

$l = $h->listRecords( 
    metadataPrefix  => 'oai_dc', 
    metadataHandler => 'MyHandler',
    set		    => 'papr' 
);

isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords() with metadataHandler' );

while ( my $r = $l->next() ) {
    isa_ok( $r, 'Net::OAI::Record' );
    my $header = $r->header();
    isa_ok( $header, 'Net::OAI::Record::Header' );
    my $metadata = $r->metadata();
    isa_ok( $metadata, 'MyHandler' );
}

