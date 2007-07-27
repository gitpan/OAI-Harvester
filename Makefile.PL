use 5.8.0; # for utf8
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'OAI-Harvester',
    'DISTNAME'		=> 'OAI-Harvester',
    'ABSTRACT'		=> 'A package for harvesting metadata using OAI-PMH',
    'VERSION_FROM'	=> 'lib/Net/OAI/Harvester.pm', 
    'PMLIBDIRS'		=> [ qw( lib/ ) ],
    'AUTHOR'		=> 'Ed Summers <ehs@pobox.com>',
    'PREREQ_PM'		=> { 
			    'LWP::UserAgent'	=> 0,
			    'XML::SAX'		=> 0,
			    'URI'		=> 0,
			    'Storable'		=> 0,
			    },
    EXE_FILES		=> [ 
                            'bin/oai-listmetadata',
			    'bin/oai-listsets',
			    'bin/oai-listrecords',
                            'bin/oai-dump'
			   ],
);

## if they don't have XML::SAX::Expat tell them they might want to get it
## for performance boost.

eval( 'use XML::SAX::Expat' );
if ( !$@ ) { 
    my $found = 0;
    foreach my $parser ( @{ XML::SAX->parsers() } ) { 
	$found = 1 if ( $parser->{ Name } eq 'XML::SAX::Expat' );
    }
    if ( !$found ) { 

	print 

<<MESSAGE;

Note: It looks like you don't have XML::SAX::Expat installed. This is ok 
since we have XML::SAX::PurePerl to fall back to. You might want to 
consider installing XML::SAX::Expat if you want to boost Net::OAI::Harvester's
performance and reliability.

MESSAGE

    }
}


## a general message about needing to be connected to the net for tests

print 

<<MESSAGE;

Note: for 'make test' to work you must be connected to the Internet. The
tests use the OAI-PMH repositories at the Library of Congress and OCLC.

MESSAGE


