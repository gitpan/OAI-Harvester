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
			    'YAML'		=> 0,
			    },
    EXE_FILES		=> [ 
			    'bin/oai-listsets',
			    'bin/oai-listrecords'
			   ],
);

print 

<<MESSAGE;

Note: for 'make test' to work you must be connected to the Internet. The
tests use the OAI-PMH repositories at the Library of Congress and OCLC.

MESSAGE


