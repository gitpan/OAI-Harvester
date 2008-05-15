use 5.8.0; # for utf8
use Module::Build;

my $build = Module::Build->new(
    dist_name => 'OAI-Harvester',
    module_name => 'Net::OAI::Harvester',
    license  => 'perl',
    requires => {
        'perl'                  => '5.8.0',
        'LWP::UserAgent'	=> '2.0',
        'Storable'		=> '2.0',
        'URI'		        => '1.3',
        'XML::SAX'		=> '0.1',
        'Carp'                  => 0,
        'File::Temp'            => 0,
        'IO::File'              => 0,
      },
    recommends => {
        'XML::SAX::ExpatXS'     => 0,
      },
    script_files => [
         'bin/oai-listsets',
         'bin/oai-listrecords',
         'bin/oai-dump'
      ],
    sign => 0,
  );
## if they don't have XML::SAX::Expat tell them they might want to get it
## for performance boost.

eval( 'use XML::SAX::Expat' );
if ( !$@ ) { 
    my $found = 0;
    eval( 'use XML::SAX' );
    foreach my $parser ( @{ XML::SAX->parsers() } ) { 
	$found = 1 if ( $parser->{ Name } eq 'XML::SAX::Expat' );
    }

    if ( !$found ) { 
	print <<MESSAGE;

Note: It looks like you don't have XML::SAX::Expat installed. This is ok 
since we have XML::SAX::PurePerl to fall back to. You might want to 
consider installing XML::SAX::Expat if you want to boost Net::OAI::Harvester's
performance and reliability.

MESSAGE
    }
}


## a general message about needing to be connected to the net for tests

print <<MESSAGE;

Note: for 'make test' to work you must be connected to the Internet. The
tests use the OAI-PMH repositories at the Library of Congress and OCLC.

MESSAGE


$build->create_build_script;
