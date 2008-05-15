use Test::More tests => 5;
use File::Path;
use IO::Dir;
use strict;
use warnings;

use_ok( 'Net::OAI::Harvester' );

sub xmlFiles {
    my $dir = IO::Dir->new(shift);
    my @xmlFiles;
    while (my $file = $dir->read()) {
        next if $file =~ /^\./;
        push @xmlFiles, $file;
    }
    return @xmlFiles;
}


# this test uses the dumpDir option for keeping xml files in a directory

# clean up dumping ground if necessary
rmtree 't/dump' if -d 't/dump';
mkdir 't/dump';

my $h = Net::OAI::Harvester->new( 
    baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0',
    dumpDir => 't/dump'
);

my $records = $h->listIdentifiers(metadataPrefix => 'oai_dc');

# look for xml files
my @xmlFiles = xmlFiles('t/dump');

# is one still there?
is scalar(@xmlFiles), 1, 'found an xml file';
is $xmlFiles[0], '00000000.xml', 'has the correct format';

# does it look like oai xml?
open XML, "t/dump/$xmlFiles[0]";
my $xml = '';
while (my $line = <XML>) {$xml .= $line};
close XML;

like $xml, qr{<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/}, 
  'looks like an oai-pmh response';

# get another 
$records = $h->listIdentifiers(metadataPrefix => 'oai_dc');

@xmlFiles = xmlFiles('t/dump');
is scalar(@xmlFiles), 2, 'found another xml file';

# final cleanup
rmtree 't/dump' if -d 't/dump';
