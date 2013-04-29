package Net::OAI::ListRecords;

use strict;
use base qw( XML::SAX::Base Net::OAI::Base );
use Carp qw ( croak );
use Net::OAI::Record;
use Net::OAI::Record::Header;
use File::Temp qw( tempfile );
use Storable qw( store_fd fd_retrieve );
use IO::File;
use Carp qw( croak );

=head1 NAME

Net::OAI::ListRecords - Results of the ListRecords OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

You probably don't want to be using this method yourself, since 
Net::OAI::Harvester::listRecords() calls it for you.

=cut

sub new {
    my ( $class, %opts ) = @_;

    my $package;
    if ( $package = $opts{ recordHandler } ) {  
        $opts{ metadataHandler } and croak( "you may pass either a recordHandler or a metadataHandler to getRecord()" );
        delete $opts { metadataHandler };
    } elsif ( $package = $opts{ metadataHandler } ) {  
	delete $opts{ recordHandler };
    } else {
        delete $opts{ recordHandler };
	$package = $opts{ metadataHandler } = 'Net::OAI::Record::OAI_DC';
    }
    Net::OAI::Harvester::_verifyMetadataHandler( $package );

    my $self = bless \%opts, ref( $class ) || $class;
    my ( $fh, $tempfile ) = tempfile(UNLINK => 1);
    binmode( $fh, ':utf8' );
    $self->{ recordsFileHandle } = $fh; 
    $self->{ recordsFilename } = $tempfile;

    ## so we can store code refs 
    $Storable::Deparse = 1;
    $Storable::Eval = 1;

    return( $self );
}

=head2 next()

Return the next metadata or record object or undef if there are no more.

=cut

sub next { 
    my $self = shift;

    ## if we haven't opened our object store do it now
    if ( ! $self->{ recordsFileHandle } ) {
	$self->{ recordsFileHandle } = IO::File->new( $self->{ recordsFilename } )
	    or croak "unable to open temp file: ".$self->{ recordsFilename };
	## we assume utf8 encoding (perhaps wrongly) 
        binmode( $self->{ recordsFileHandle }, ':utf8' );
    }

    ## no more data to read back from our object store then return undef
    if ( $self->{ recordsFileHandle }->eof() ) {
	$self->{ recordsFileHandle }->close() or croak "Could not close() ".$self->{ recordsFilename }
                                                      .". File system full?";
	return( $self->handleResumptionToken( 'listRecords' ) );
    }

    ## get an object back from the store, thaw and return it 
    my $record = fd_retrieve( $self->{ recordsFileHandle } );
    return( $record );
}

=head2 metadataHandler()
=head2 recordHandler()

Returns the name of the package being used to represent the individual metadata
records. If unspecified it defaults to L<Net::OAI::Record::OAI_DC> which 
should be ok. 

=cut

sub metadataHandler {
    my $self = shift;
    return( $self->{ metadataHandler } );
}

sub recordHandler {
    my $self = shift;
    return( $self->{ recordHandler } );
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element( $element ) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    ## if we are at the start of a new record then we need an empty 
    ## metadata object to fill up 
    if ( $element->{ LocalName } eq 'record' ) { 
	## we store existing downstream handler so we can replace
	## it after we are done retrieving the metadata record
	$self->{ OLD_Handler } = $self->get_handler();
	my $header = $self->{ recordHandler }
		   ? Net::OAI::Record::Header->new( 
			Handler => (ref($self->{ recordHandler }) ? $self->{ recordHandler } : $self->{ recordHandler }->new()),
			fwdAll => 1,
		     )
		   : Net::OAI::Record::Header->new( 
			Handler => (ref($self->{ metadataHandler }) ? $self->{ metadataHandler } : $self->{ metadataHandler }->new()),
		     );
	$self->set_handler( $header );
    }
    elsif ( $element->{ LocalName } eq 'ListRecords' ) {
    }
    return $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;

    $self->SUPER::end_element( $element );
    return unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    ## if we've got to the end of the record we need to stash
    ## away the object in our object store on disk
    if ( $element->{ LocalName } eq 'record' ) {

	## we need to swap out the existing metadata handler and freeze
	## it on disk
	my $header = $self->get_handler();
	my $data = $header->get_handler();
	$header->set_handler( undef ); ## remove reference to $record

	## set handler to what is was before we started processing
	## the record
	$self->set_handler( $self->{ OLD_Handler } );
        my $record;
        if ( $self->{ recordHandler } ) {
	    $record = Net::OAI::Record->new(header => $header, alldata => $data)
        } else {
	    $record = Net::OAI::Record->new(header => $header, metadata => $data)
	};

	## commit the object to disk
        Net::OAI::Harvester::debug( "committing record to object store" );
	store_fd( $record, $self->{ recordsFileHandle } );
    } 

    ## otherwise if we got to the end of our list we can close
    ## our object stash on disk
    elsif ( $element->{ LocalName } eq 'ListRecords' ) {
	$self->{ recordsFileHandle }->close();
	$self->{ recordsFileHandle } = undef;
    }

}

sub _fatal {
    print STDERR "fatal: ", shift, "\n";
    exit(1);
}

1;

