package Net::OAI::Harvester;

use strict;
use warnings;

use URI;
use LWP::UserAgent;
use XML::SAX qw( Namespaces Validation );
use File::Temp qw( tempfile );
use Carp qw( croak );

use Net::OAI::Error;
use Net::OAI::ResumptionToken;
use Net::OAI::Identify;
use Net::OAI::ListMetadataFormats;
use Net::OAI::ListIdentifiers;
use Net::OAI::ListRecords;
use Net::OAI::GetRecord;
use Net::OAI::ListRecords;
use Net::OAI::ListSets;
use Net::OAI::Record::Header;
use Net::OAI::Record::OAI_DC;

our $VERSION = '1.12';
our $DEBUG = 0;

=head1 NAME

Net::OAI::Harvester - A package for harvesting metadata using OAI-PMH

=head1 SYNOPSIS

    ## create a harvester for the Library of Congress
    my $harvester = Net::OAI::Harvester->new( 
	'baseURL' => 'http://memory.loc.gov/cgi-bin/oai2_0'
    );

    ## list all the records in a repository
    my $records = $harvester->listRecords( 
	'metadataPrefix'    => 'oai_dc' 
    );
    while ( my $record = $records->next() ) {
	my $header = $record->header();
	my $metadata = $record->metadata();
	print "identifier: ", $header->identifier(), "\n";
	print "title: ", $metadata->title(), "\n";
    }

    ## find out the name for a repository
    my $identity = $harvester->identify();
    print "name: ",$identity->repositoryName(),"\n";

    ## get a list of identifiers 
    my $identifiers = $harvester->listIdentifiers(
	'metadataPrefix'    => 'oai_dc'
    );
    while ( my $header = $identifiers->next() ) {
	print "identifier: ",$header->identifier(), "\n";
    }

    ## list all the records in a repository
    my $records = $harvester->listRecords( 
	'metadataPrefix'    => 'oai_dc' 
    );
    while ( my $record = $records->next() ) {
	my $header = $record->header();
	my $metadata = $record->metadata();
	print "identifier: ", $header->identifier(), "\n";
	print "title: ", $metadata->title(), "\n";
    }

    ## GetRecord, ListSets, ListMetadataFormats also supported

=head1 DESCRIPTION

Net::OAI::Harvester is a Perl extension for easily querying OAI-PMH 
repositories. OAI-PMH is the Open Archives Initiative Protocol for Metadata 
Harvesting.  OAI-PMH allows data repositories to share metadata about their 
digital assets.  Net::OAI::Harvester is a OAI-PMH client, so it does for 
OAI-PMH what LWP::UserAgent does for HTTP. 

You create a Net::OAI::Harvester object which you can then use to 
retrieve metadata from a selected repository. Net::OAI::Harvester tries to keep 
things simple by providing an API to get at the data you want; but it also has 
a framework which is easy to extend should you need to get more fancy.

The guiding principle behind OAI-PMH is to allow metadata about online 
resources to be shared by data providers, so that the metadata can be harvested
by interested parties. The protocol is essentially XML over HTTP (much like 
XMLRPC or SOAP). Net::OAI::Harvester does XML parsing for you 
(using XML::SAX internally), but you can get at the raw XML if you want to do 
your own XML processing, and you can drop in your own XML::SAX handler if you 
would like to do your own parsing of metadata elements.

A OAI-PMH repository supports 6 verbs: GetRecord, Identify, ListIdentifiers, 
ListMetadataFormats, ListRecords, and ListSets. The verbs translate directly 
into methods that you can call on a Net::OAI::Harvester object. More details 
about these methods are supplied below, however for the real story please 
consult the spec at http://www.openarchives.org.

Net::OAI::Harvester has a few features that are worth mentioning:

=over 4

=item 1

Since the OAI-PMH results can be arbitrarily large, a stream based (XML::SAX) 
parser is used. As the document is parsed corresponding Perl objects are 
created (records, headers, etc), which are then serialized on disk (using 
Storable if you are curious). The serialized objects on disk can then be 
iterated over one at a time. The benefit of this is a lower memory footprint 
when (for example) a ListRecords verb is exercised on a repository that 
returns 100,000 records.

=item 2

XML::SAX filters are used which will allow interested developers to write 
their own metadata parsing packages, and drop them into place. This is useful
because OAI-PMH is itself metadata schema agnostic, so you can use OAI-PMH 
to distribute all kinds of metadata (Dublin Core, MARC, EAD, or your favorite metadata schema). OAI-PMH does require that a repository at least provides 
Dublin Core metadata as a baseline. Net::OAI::Harvester has built in support for 
unqualified Dublin Core, and has a framework for dropping in your own parser 
for other kinds of metadata. If you create a XML::Handler that you would like 
to contribute back into the Net::OAI::Harvester project please get in touch! 

=back

=head1 METHODS

All the Net::OAI::Harvester methods return other objects. As you would expect 
new() returns an Net::OAI::Harvester object; similarly getRecord() returns an 
Net::OAI::Record object, listIdentifiers() returns a Net::OAI::ListIdentifiers 
object, identify() returns an Net::OAI::Identify object, and so on. So when 
you use one of these methods you'll probably want to check out the docs for 
the object that gets returned so you can see what to do with it. Many 
of these classes inherit from Net::OAI::Base which provides some base 
functionality for retrieving errors, getting the raw XML, and the 
temporary file where the XML is stored (see Net::OAI::Base documentation for
more details).

=head2 new()

The constructor which returns an Net::OAI::Harvester object. You must supply the
baseURL parameter, to tell Net::OAI::Harvester what data repository you are 
going to be harvesting. For a list of data providers check out the directory 
available on the Open Archives Initiative homepage.  

    my $harvester = Net::OAI::Harvester->new(
	baseURL => 'http://memory.loc.gov/cgi-bin/oai2_0'
    );

If you want to pull down all the XML files and keep them in a directory, rather
than having the stored as transient temp files pass in the dumpDir parameter.

    my $harvester = Net::OAI::Harvester->new(
        baseUrl => 'http://memory.loc.gov/cgi-bin/oai2_0',
        dumpDir => 'american-memory'
    );

Also if you would like to fine tune the HTTP client used by Net::OAI::Harvester
you can pass in a configured object. For example this can be handy if you 
want to adjust the client timeout:

    my $ua = LWP::UserAgent->new();
    $ua->timeout(20); ## set timeout to 20 seconds
    my $harvester = Net::OAI::Harvester->new(
        baseURL     => 'http://memory.loc.gov/cgi-bin/oai2_0',
        userAgent   => $ua 
    );

=cut

sub new {
    my ( $class, %opts ) = @_;

    ## uppercase options
    my %normalOpts = map { ( uc($_), $opts{$_} ) } keys( %opts );
    
    ## we must be told a baseURL
    croak( "new() needs the baseUrl parameter" ) if !$normalOpts{ BASEURL };
    my $baseURL = URI->new( $normalOpts{ BASEURL } ); 

    my $self = bless( { baseURL => $baseURL }, ref( $class ) || $class );

    ## set the user agent
    if ( $normalOpts{ USERAGENT } ) { 
	$self->userAgent( $normalOpts{ USERAGENT } ); 
    } else {
	my $ua = LWP::UserAgent->new();
	$ua->agent( $class );
	$self->userAgent( $ua );
    }

    # set up some stuff if we are dumping xml to a directory
    if ($normalOpts{ DUMPDIR }) {
      my $dir = $normalOpts{ DUMPDIR };
      croak "no such directory '$dir'" unless -d $dir;
      $self->{ dumpDir } = $dir;
      $self->{ lastDump } = 0;
    }

    return( $self );
}

=head2 identify()

identify() is the OAI verb that tells a metadata repository to provide a 
description of itself. A call to identify() returns a Net::OAI::Identify object 
which you can then call methods on to retrieve the information you are 
intersted in. For example: 

    my $identity = $harvester->identify();
    print "repository name: ",$identity->repositoryName(),"\n";
    print "protocol version: ",$identity->protocolVersion(),"\n";
    print "earliest date stamp: ",$identity->earliestDatestamp(),"\n";
    print "admin email(s): ", join( ", ", $identity->adminEmail() ), "\n";
    ...

For more details see the Net::OAI::Identify documentation.

=cut 

sub identify {
    my $self = shift;
    my $uri = $self->{ baseURL };
    $uri->query_form( 'verb' => 'Identify' );

    my $identity = Net::OAI::Identify->new( $self->_get( $uri ) );
    return $identity if $identity->errorCode();

    my $token = Net::OAI::ResumptionToken->new( Handler => $identity );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error ); 
    debug( "parsing Identify response " .  $identity->file() );
    eval { $parser->parse_uri( $identity->file() ) };
    if ( $@ ) {_xmlError( $error ); } 
    $identity->{ token } = $token->token() ? $token : undef;
    $identity->{ error } = $error;
    return( $identity );
}

=head2 listMetadataFormats()

listMetadataFormats() asks the repository to return a list of metadata formats 
that it supports. A call to listMetadataFormats() returns an 
Net::OAI::ListMetadataFormats object.

    my $list = $harvester->listMetadataFormats();
    print "archive supports metadata prefixes: ", 
	join( ',', $list->prefixes() ),"\n";

If you are interested in the metadata formats available for 
a particular resource identifier then you can pass in that identifier. 
    
    my $list = $harvester->listMetadataFormats( identifier => '1234567' );
    print "record identifier 1234567 can be retrieved as ",
	join( ',', $list->prefixes() ),"\n";

See documentation for Net::OAI::ListMetadataFormats for more details.

=cut

sub listMetadataFormats {
    my ( $self, %opts ) = @_;
    my $uri = $self->{ baseURL };
    my %pairs = ( verb => 'ListMetadataFormats' );
    if ( $opts{ identifier } ) { 
	$pairs{ identifier } = $opts{ identifier }; 
    }
    $uri->query_form( %pairs );

    my $list = Net::OAI::ListMetadataFormats->new( $self->_get( $uri ) );
    return $list if $list->errorCode();

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error );
    debug( "parsing ListMetadataFormats response: ".$list->file() );
    eval{ $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 
    $list->{ token } = $token->token() ? $token : undef;
    $list->{ error } = $error;
    return( $list );
}

=head2 getRecord()

getRecord() is used to retrieve a single record from a repository. You must pass
in the C<identifier> and an optional C<metadataPrefix> parameters to identify 
the record, and the flavor of metadata you would like. Net::OAI::Harvester 
includes a parser for OAI DublinCore, so if you do not specifiy a 
metadataPrefix 'oai_dc' will be assumed. If you would like to drop in you own 
XML::Handler for another type of metadata use the C<metadataHandler> parameter.

    my $record = $harvester->getRecord( 
	identifier	=> 'abc123',
    );

    ## get the Net::OAI::Record::Header object
    my $header = $record->header();

    ## get the metadata object 
    my $metadata = $record->metadata();

    ## or if you would rather use your own XML::Handler 
    ## pass in the package name for the object you would like to create
    my $record = $harvester->getRecord(
	identifier		=> 'abc123',
	metadataHandler		=> 'MyHandler'	    
    );
    my $metadata = $record->metadata();
    
=cut 

sub getRecord {
    my ( $self, %opts ) = @_;

    croak( "you must pass the identifier parameter to getRecord()" )
	if ( ! exists( $opts{ 'identifier' } ) );
    croak( "you must pass the metadataPrefix parameter to getRecord()" )
	if ( ! exists( $opts{ 'metadataPrefix' } ) );

    my $metadataHandler;
    if ( exists( $opts{ metadataHandler } ) ) {  
	my $package = $opts{ metadataHandler };
	_verifyMetadataHandler( $package );
	$metadataHandler = $package->new();
    } else {
	$metadataHandler = Net::OAI::Record::OAI_DC->new();
    }

    my $uri = $self->{ baseURL };
    $uri->query_form(
	verb		=> 'GetRecord',
	identifier	=> $opts{ 'identifier' },
	metadataPrefix	=> $opts{ 'metadataPrefix' }
    );

    my $record = Net::OAI::GetRecord->new( $self->_get( $uri ) );
    return $record if $record->errorCode();

    my $header = Net::OAI::Record::Header->new( Handler => $metadataHandler );
    my $error = Net::OAI::Error->new( Handler => $header );
    my $parser = _parser( $error ); 
    debug( "parsing GetRecord response " . $record->file() );
    $parser->parse_uri( $record->file() );
    if ( $@ ) { _xmlError( $error ); } 

    $record->{ error } = $error;
    $record->{ metadata } = $metadataHandler;
    $record->{ header } = $header;
    return( $record );

}


=head2 listRecords()

listRecords() allows you to retrieve all the records in a data repository. 
You must supply the C<metadataPrefix> parameter to tell your Net::OAI::Harvester
which type of records you are interested in. listRecords() returns an 
Net::OAI::ListRecords object. There are four other optional parameters C<from>, 
C<until>, C<set>, and C<resumptionToken> which are better described in the 
OAI-PMH spec. 

    my $records = $harvester->listRecords( 
	metadataPrefix	=> 'oai_dc'
    );

    ## iterate through the results with next()
    while ( my $record = $records->next() ) { 
	my $metadata = $record->metadata();
	...
    }

If you would like to use your own metadata handler then you can specify 
the package name of the handler. 

    my $records = $harvester->listRecords(
	metadataPrefix	=> 'mods',
	metadataHandler	=> 'MODS::Handler'
    );

    while ( my $record = $records->next() ) { 
	my $metadata = $record->metadata();
	# $metadata will be a MODS::Handler object
    }

If you want to automatically handle resumption tokens you can with 
the listAllRecords() method.

If you prefer you can handle resumption tokens yourself with a 
loop, and the resumptionToken() method. You might want to do this
if you are working with a repository that wants you to wait between
requests.

    my $records = $harvester->listRecords( metadataPrefix => 'oai_dc' );
    my $finished = 0;

    while ( ! $finished ) {

	while ( my $record = $records->next() ) {
	    my $metadata = $record->metadata();
	    # do interesting stuff here 
	}

	my $rToken = $records->resumptionToken();
	if ( $rToken ) { 
	    $records = $harvester->listRecords( 
		resumptionToken => $rToken->token()
	    );
	} else { 
	    $finished = 1;
	}

    }

=cut

sub listRecords {
    my ( $self, %opts ) = @_;

    croak( "you must pass the metadataPrefix parameter to listRecords()" )
	if ( ! exists( $opts{ 'metadataPrefix' } )
	    and ! exists( $opts{ 'resumptionToken' } ) );
    my %pairs = ( 
	verb		  => 'ListRecords', 
    );

    foreach ( qw( metadataPrefix from until set resumptionToken ) ) {
	if ( exists( $opts{ $_ } ) ) {
	    $pairs{ $_ } = $opts{ $_ };
	}
    }
    my $uri = $self->{ baseURL };
    $uri->query_form( %pairs );

    my $list = Net::OAI::ListRecords->new( $self->_get( $uri ), 
	metadataHandler => $opts{ metadataHandler } );
    return $list if $list->errorCode();

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error ); 
    debug( "parsing ListRecords response " . $list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 

    $list->{ error } = $error;
    $list->{ token } = $token->token() ? $token : undef;
    return( $list );
}

=head2 listAllRecords() 

Does exactly what listRecords() does except it will automatically
submit resumption tokens as needed.

=cut

sub listAllRecords {
    my $self = shift;
    debug( "calling listRecords() as part of listAllRecords request" );
    my $list = listRecords( $self, @_ );
    $list->{ harvester } = $self;
    return( $list );
}

=head2 listIdentifiers()

listIdentifiers() takes the same parameters that listRecords() takes, but it 
returns only the record headers, allowing you to quickly retrieve all the 
record identifiers for a particular repository. The object returned is a 
Net::OAI::ListIdentifiers object.

    my $headers = $harvester->listIdentifiers( 
	metadataPrefix	=> 'oai_dc'
    );

    ## iterate through the results with next()
    while ( my $header = $identifiers->next() ) { 
	print "identifier: ", $header->identifier(), "\n";
    }

If you want to automtically handle resumption tokens use listAllIdentifiers().
If you are working with a repository that encourages pauses between requests
you can handle the tokens yourself using the technique described above
in listRecords().

=cut

sub listIdentifiers {
    my ( $self, %opts ) = @_;
    croak( "listIdentifiers(): metadataPrefix is a required parameter" ) 
	if ( ! exists( $opts{ metadataPrefix } )
	    and ! exists( $opts{ resumptionToken } ) );
    my $uri = $self->{ baseURL };
    my %pairs = (
	verb		=> 'ListIdentifiers', 
    );
    foreach ( qw( metadataPrefix from until set resumptionToken ) ) {
	if ( exists( $opts{ $_ } ) ) {
	    $pairs{ $_ } = $opts{ $_ };
	}
    }
    $uri->query_form( %pairs );

    my $list = Net::OAI::ListIdentifiers->new( $self->_get( $uri ) );
    return( $list ) if $list->errorCode();

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error );
    debug( "parsing ListIdentifiers response " . $list->file() );
    eval { $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 
    $list->{ token } = $token->token() ? $token : undef; 
    $list->{ error } = $error;
    return( $list );
}

=head2 listAllIdentifiers()

Does exactly what listIdentifiers() does except it will automatically 
submit resumption tokens as needed.

=cut

sub listAllIdentifiers {
    my $self = shift;
    debug( "calling listIdentifiers() as part of listAllIdentifiers() call" );
    my $list = listIdentifiers( $self, @_ );
    $list->{ harvester } = $self;
    return( $list );
}

=head2 listSets()

listSets() takes an optional C<resumptionToken> parameter, and returns a 
Net::OAI::ListSets object. listSets() allows you to harvest a subset of a 
particular repository with listRecords(). For more information see the OAI-PMH 
spec and the Net::OAI::ListSets docs.

    my $sets = $harvester->listSets();
    foreach ( $sets->setSpecs() ) { 
	print "set spec: $_ ; set name: ", $sets->setName( $_ ), "\n";
    }

=cut

sub listSets {
    my ( $self, %opts ) = @_;
    my %pairs = ( verb => 'ListSets' );
    if ( exists( $opts{ resumptionToken } ) ) {
	$pairs{ resumptionToken } = $opts{ resumptionToken };
    }
    my $uri = $self->{ baseURL };
    $uri->query_form( %pairs );

    my $list = Net::OAI::ListSets->new( $self->_get( $uri ) );
    return( $list ) if $list->errorCode();

    my $token = Net::OAI::ResumptionToken->new( Handler => $list );
    my $error = Net::OAI::Error->new( Handler => $token );
    my $parser = _parser( $error );
    debug( "parsing ListSets response " . $list->file() );
    eval{ $parser->parse_uri( $list->file() ) };
    if ( $@ ) { _xmlError( $error ); } 
    $list->{ error } = $error;
    $list->{ token } = $token->token() ? $token : undef;
    return( $list );
}

=head2 baseURL()

Gets or sets the base URL for the repository being harvested.

    $harvester->baseURL( 'http://memory.loc.gov/cgi-bin/oai2_0' );

Or if you want to know what the current baseURL is

    $baseURL = $harvester->baseURL();

=cut

sub baseURL {
    my ( $self, $url ) = @_;
    if ( $url ) { $self->{ baseURL } = URI->new( $url ); } 
    return( $self->{ baseURL }->as_string() );
}

=head2 userAgent()

Gets or sets the LWP::UserAgent object being used to perform the HTTP
transactions. This method could be useful if you wanted to change the 
agent string, timeout, or some other feature.

=cut

sub userAgent {
    my ( $self, $ua ) = @_;
    if ( $ua ) { 
	croak( "userAgent() needs a valid LWP::UserAgent" ) 
	    if ref( $ua ) ne 'LWP::UserAgent';
	$self->{ userAgent } = $ua;
    }
    return( $self->{ userAgent } );
}

## internal stuff

sub _get {
    my ($self,$uri) = @_;
    my $ua = $self->{ userAgent };

    my ($fh, $file);

    if ( $self->{ dumpDir } ) {
        my $filePrefix = $self->{lastDump}++;
        $file = sprintf("%s/%08d.xml", $self->{dumpDir}, $filePrefix);
        $fh = IO::File->new($file, 'w');
    }

    else {
        ( $fh, $file ) = tempfile();
    }

    debug( "fetching ".$uri->as_string() );
    debug( "writing to file: $file" );
    my $request = HTTP::Request->new( GET => $uri->as_string() );
    my $response = $ua->request( $request, sub { print $fh shift; }, 4096 );
    close( $fh );

    if ( $response->is_error() ) { 
        debug( "caught HTTP level error" . $response->message() );
        my $error = Net::OAI::Error->new(
            errorString     => 'HTTP Level Error: ' . $response->message(),
            errorCode       => $response->code()
        );
	return( 
	    file	    => $file, 
            error           => $error
	);
    }

    return( 
	    file	    => $file,
    );

}

sub _parser {
    my $handler = shift;
    my $factory = XML::SAX::ParserFactory->new();
    return( $factory->parser( Handler => $handler ) );
}

sub _xmlError {
    my $e = shift;
    warn "caught xml parsing error: $@";
    $e->errorString( "XML parsing error: $@" );
    $e->errorCode( 'xmlParseError' );
}


sub _verifyMetadataHandler {
    my $package = shift;
    eval( "use $package" );
    _fatal( "unable to locate metadataHandler $package in: " . 
	join( "\n\t", @INC ) ) if $@; 
    _fatal( "metadataHandler $package must inherit from XML::SAX::Base\n" )
	if ( ! grep { 'XML::SAX::Base' } eval( '@' . $package . '::ISA' ) );
    return( 1 );
}


sub debug {
    my $msg = shift; 
    if ( $Net::OAI::Harvester::DEBUG ) { 
	print STDERR "oai-harvester: " . localtime() . ": $msg\n";
    }
}

sub _fatal {
    my $msg = shift;
    print STDERR "fatal: $msg\n\n";
    exit( 1 );
}

=head1 DIAGNOSTICS

If you would like to see diagnostic information when harvesting is running 
then set Net::OAI::Harvester::DEBUG to a true value.

    $Net::OAI::Harvester::DEBUG = 1;

=head1 PERFORMANCE 

XML::SAX is used for parsing, but it presents a generalized interface to many 
parsers. It comes with XML::Parser::PurePerl by default, which is nice since
you don't have to worry about getting the right libraries installed. However
XML::Parser::PurePerl is rather slow compared to XML::LibXML. If you 
are a speed freak install XML::LibXML from CPAN today.

If you have a particular parser you want to use you can set the
$XML::SAX::ParserPackage variable appropriately. See XML::SAX::ParserFactory
documentation for details.

=head1 TODO

=over 4 

=item *

Allow Net::OAI::ListMetadataFormats to store more than just the metadata
prefixes.

=item *

Implement Net::OAI::Set for iterator access to Net::OAI::ListSets.

=item *

Implement Net::OAI::Harvester::listAllSets().

=item * 

More documentation of other classes.

=item * 

Document custom XML::Handler creation.

=item * 

Handle optional compression.

=item * 

Create common handlers for other metadata formats (MARC, qualified DC, etc).

=item *

Selectively load Net::OAI::* classes as needed, rather than getting all of them 
at once at the beginning of Net::OAI::Harvester.

=back

=head1 SEE ALSO

=over 4

=item *

OAI-PMH Specification at L<http://www.openarchives.org>

=item *

L<Net::OAI::Base>

=item *

L<Net::OAI::Error>

=item *

L<Net::OAI::GetRecord>

=item *

L<Net::OAI::Identify>

=item *

L<Net::OAI::ListIdentifiers>

=item *

L<Net::OAI::ListMetadataFormats>

=item *

L<Net::OAI::ListRecords>

=item *

L<Net::OAI::ListSets>

=item *

L<Net::OAI::Record>

=item *

L<Net::OAI::Record::Header>

=item *

L<Net::OAI::Record::Metadata>

=item *

L<Net::OAI::ResumptionToken>

=item *

L<Storable>

=back

=head1 AUTHORS

=over 4

=item * 

Ed Summers <ehs@pobox.com>

=item *

Martin Emmerich <Martin.Emmerich@oew.de>

=back

=cut

1;
