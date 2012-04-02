use Test::More tests => 13;

use strict;
use warnings;

$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

my $h = new_ok('Net::OAI::Harvester' => [ baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' ]);

my $l = $h->listRecords( metadataPrefix => 'oai_dc', set => 'papr' );
isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords()' );

my $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
    diag("with ", $l->BaseURL, ": ", $HTE);
  }

SKIP: {
    skip $HTE, 8 if $HTE;

    ok( ! $l->errorCode(), 'errorCode()' );
    ok( ! $l->errorString(), 'errorString()' );

    subtest 'Collect Result' => sub {

# per recipe in Test::More documentation: Get rid of "wide character in print" diagnostics
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

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

use lib qw( t ); ## so harvester will be able to locate our handler

$l = $h->listRecords( 
    metadataPrefix  => 'oai_dc', 
    metadataHandler => 'MyHandler',
    set		    => 'papr' 
);

isa_ok( $l, 'Net::OAI::ListRecords', 'listRecords() with metadataHandler' );

undef $HTE;
if ( my $e = $l->HTTPError() ) {
    $HTE = "HTTP Error ".$e->status_line;
    $HTE .= " [Retry-After: ".$l->HTTPRetryAfter()."]" if $e->code() == 503;
    diag("with ", $l->BaseURL, ": ", $HTE);
  }

SKIP: {
    skip $HTE, 1 if $HTE;

    subtest 'Collect Custom Result' => sub {
        while ( my $r = $l->next() ) {
            isa_ok( $r, 'Net::OAI::Record' );
            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            my $metadata = $r->metadata();
            isa_ok( $metadata, 'MyHandler' );
          };
      };
}

