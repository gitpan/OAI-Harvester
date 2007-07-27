use Test::More tests => 6;

use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

## XML Parsing Error

my $h = Net::OAI::Harvester->new( 'baseURL' => 'http://www.yahoo.com' );
isa_ok( $h, 'Net::OAI::Harvester' );

my $i = $h->identify();
isa_ok( $i, 'Net::OAI::Identify' );

# XML::LibXML::SAX does not return error codes properly
SKIP: {
    skip( 'XML::LibXML::SAX does not return errors', 1 )
	if ref( XML::SAX::ParserFactory->parser() ) eq 'XML::LibXML::SAX';
    is( $i->errorCode(), 'xmlParseError', 'caught XML parse error' );
}

## Missing parameter

$h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0' 
);
my $r = $h->listRecords( 'metadataPrefix' => 'argh' );
is( 
    $r->errorCode(), 
    'cannotDisseminateFormat', 
    'parsed OAI error code from server' 
);


## Bad URL

$h = Net::OAI::Harvester->new(
    baseURL => 'http://memory.loc.gov/cgi-bin/nonexistant_oai_handler'
);
$r = $h->identify();
is( $r->errorString(), 'HTTP Level Error: Not Found', 'Caught HTTP error' );

