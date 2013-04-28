package Net::OAI::GetRecord;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );
use Net::OAI::Record::Header;

=head1 NAME

Net::OAI::GetRecord - The results of a GetRecord OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;

    ## default metadata handler
    $opts{ metadataHandler } = 'Net::OAI::Record::OAI_DC' unless $opts{ metadataHandler };
    Net::OAI::Harvester::_verifyMetadataHandler( $opts{ metadataHandler } );

    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ header } = undef;
    $self->{ setSpecs } = [];
    return( $self );
}

=head2 header()

=cut

sub header {
    my $self = shift;
    return( $self->{ header } );
}

=head2 metadata()

=cut

sub metadata {
    my $self = shift;
    return( $self->{ metadata } );
}


=head2 record()

=cut

sub record {
    my $self = shift;
    return Net::OAI::Record->new( 
	header   => $self->{ header },
	metadata => $self->{ metadata },
    );
}

my $xmlns_oai = "http://www.openarchives.org/OAI/2.0/";

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    ## if we are at the start of a new record then we need an empty 
    ## metadata object to fill up 
    if ( ($element->{ LocalName } eq 'record') ) { 
	## we store existing downstream handler so we can replace
	## it after we are done retrieving the metadata record
	$self->{ OLD_Handler } = $self->get_handler();
	my $header = Net::OAI::Record::Header->new( 
	    Handler => $self->{ metadataHandler }->new() 
	);
	$self->set_handler( $header );
    }
    return $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;

    $self->SUPER::end_element( $element );
    return unless $element->{NamespaceURI} eq $xmlns_oai;

    ## if we've got to the end of the record we need finish up
    ## the object
    if ( $element->{ LocalName } eq 'record' ) {
	my $header = $self->get_handler();
	$self->{ metadata } = $header->get_handler();
	$header->set_handler( undef ); ## remove reference to $metadata
        $self->{ header } = $header;
	## set handler to what is was before we started processing
	## the record
	$self->set_handler( $self->{ OLD_Handler } );
      }
}

1;

