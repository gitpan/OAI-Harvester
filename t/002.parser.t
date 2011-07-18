
use Test::More tests => 5;

use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );

## will we get a usable parser?

my $h = Net::OAI::Harvester->new( 'baseURL' => 'http://www.yahoo.com' );
isa_ok( $h, 'Net::OAI::Harvester' );

my $e = Net::OAI::Error->new();
isa_ok( $e, 'Net::OAI::Error' );

my $parser;
eval { $parser = Net::OAI::Harvester::_parser($e) };
ok($parser, "get decent parser from XML::SAX::ParserFactory: $@");
if ( $@ ) {
    diag("!!! This is fatal:\n!!! All subseqent tests will simply die at early stages");
    diag("Possible reasons include: No parsers installed, ParserDetails.ini does not exist");
    diag(<<"XxX");
You may force a specific parser *for the tests* by providing the environment variable NOH_ParserPackage:

NOH_ParserPackage=XML::SAX::PurePerl ./Build test

XxX
  }
else {
    no strict 'refs';
    diag("\nNote: tests will use ".ref($parser)." ".($parser->VERSION() || '???')." assigned by XML::SAX::ParserFactory")}

## force XML::SAX::PurePerl
$XML::SAX::ParserPackage = "XML::SAX::PurePerl";
eval { $parser = Net::OAI::Harvester::_parser($e) };
isa_ok($parser, "XML::SAX::PurePerl", "forced use of XML::SAX::PurePerl parser: $@");
