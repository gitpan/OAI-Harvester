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
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ insideHeader } = $self->{ insideSet } = 0;
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

my $xmlns_oai = "http://www.openarchives.org/OAI/2.0/";

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
die "GetRecord start_element";
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'header' ) { 
	$self->{ insideHeader } = 1;
	if ( exists( $element->{ Attributes }{ '{}status' } ) ) {
	    $self->{ headerStatus } = $element->{ Attributes }{ '{}status' };
	} else {
	    $self->{ headerStatus } = '';
	}
    }
    elsif ( $tagName eq 'setSpec' ) {
	$self->{ insideSet } = 1;
    }
    else {
	$self->SUPER::start_element( $element );
        }
    push( @{ $self->{ tagStack } }, $element->{ LocalName } );
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'header' ) {
	Net:OAI::Harvester::debug( "found header" );
	my $header = Net::OAI::Record::Header->new();
	$header->status( $self->{ headerStatus } );
	$header->identifier( $self->{ identifier } );
	$header->datestamp( $self->{ datestamp } );
	$header->sets( @{ $self->{ setSpecs } } );
	push( @{ $self->{ headers } }, $header );
	$self->{ insideHeader } = 0;
	$self->{ status } = $self->{ identifier } = $self->{ datestamp } = $self->{ setSpec } = '';
	$self->{ setSpecs } = [];
    }
    elsif ( $tagName eq 'setSpec' ) { 
	Net::OAI::Harvester::debug( "found setSpec" );
	push( @{ $self->{ setSpecs } }, $self->{ setSpec } );
	$self->{ insideSet } = 0;
    }
    else { 
        $self->SUPER::end_element( $element );
    }
    pop( @{ $self->{ tagStack } } );
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ insideHeader } ) { 
	$self->{ $self->{ tagStack }[-1] } .= $characters->{ Data };
    } else {
	$self->SUPER::characters( $characters );
    }
}

1;

