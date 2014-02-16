use Test::More tests => 8;
use File::Path;
use IO::Dir;
use strict;
use warnings;
$XML::SAX::ParserPackage = $XML::SAX::ParserPackage ||= $ENV{'NOH_ParserPackage'};

use_ok( 'Net::OAI::Harvester' );
use_ok( 'Net::OAI::Record::NamespaceFilter' );

my $repo = 'http://memory.loc.gov/cgi-bin/oai2_0';

my $plug = new_ok('Net::OAI::Record::NamespaceFilter');

my $h = new_ok('Net::OAI::Harvester' => [
    baseURL => $repo,
]);

my $list = $h->listRecords(
    metadataPrefix => 'oai_dc',
    recordHandler => $plug,
);

SKIP: {
    my $HTE = HTE($list, $repo);
    skip $HTE, 9 if $HTE;

    ok( ! $list->errorCode(), 'errorCode()' );
    ok( ! $list->errorString(), 'errorString()' );

    subtest 'Collect Whatever' => sub {
        my $count = 0;
        while( my $r = $list->next() ) {
            $count ++;
            isa_ok( $r, 'Net::OAI::Record' );

            my $header = $r->header();
            isa_ok( $header, 'Net::OAI::Record::Header' );
            ok( $header->identifier(), 
        	'header identifier defined: '.$header->identifier() );
            unless ( $header -> identifier() ) {
                diag explain $header;
                diag "----";
              };

            ok( ! defined $r->metadata(), 'custom handler does not deliver metadata' );

            my $record = $r->alldata();
            isa_ok( $record, 'Net::OAI::Record::NamespaceFilter' );
#           diag explain $record;
#           diag "====";
          }
        note "collected $count records from $repo";
        done_testing();
      };

## resumption token

    my $r = $list->resumptionToken();
    subtest 'Resumption Token' => sub {
        plan tests => 5;
        isa_ok( $r, 'Net::OAI::ResumptionToken' );
        ok( $r->token(), 'token() '.$r->token() );

## these may not return stuff but we must be able to call the methods
        eval { $r->expirationDate() };
        ok( ! $@, 'expirationDate()' );

        eval { $r->completeListSize() };
        ok( ! $@, 'completeListSize()' );

        eval { $r->cursor() };
        ok( ! $@, 'cursor()' );
      };

  }

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

