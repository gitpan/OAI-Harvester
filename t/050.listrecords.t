use Test::More no_plan; 

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://alcme.oclc.org/xtcat/servlet/OAIHandler' 
);
isa_ok( $h, 'Net::OAI::Harvester', 'new()' );

my $l = $h->listRecords( metadataPrefix => 'oai_dc' );
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
	'meteadata title defined: '.$metadata->title() );
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

