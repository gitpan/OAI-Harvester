package Net::OAI::Record::Header;

use strict;
use base qw( XML::SAX::Base );
use Carp qw( carp );
our $VERSION = 'v1.00.0';

=head1 NAME

Net::OAI::Record::Header - class for record header representation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ status } = $self->{ identifier } = $self->{ datestamp } = '';
    $self->{ sets } = [];
    $self->{ insideHeader } = $self->{ insideSet } = $self->{ insideMetadata } = 0;
    return( $self );
}

=head2 status()

=cut 

sub status {
    my ( $self, $status ) = @_;
    if ( $status ) { $self->{ headerStatus } = $status; }
    return( $self->{ headerStatus } );
}

=head2 identifier()

=cut

sub identifier {
    my ( $self, $id ) = @_;
    if ( $id ) { $self->{ identifier } = $id; }
    return( $self->{ identifier } );
}

=head2 datestamp()

=cut

sub datestamp {
    my ( $self, $datestamp ) = @_;
    if ( $datestamp ) { $self->{ datestamp } = $datestamp; }
    return( $self->{ datestamp } );
}

=head2 sets()

=cut

sub sets {
    my ( $self, @sets ) = @_;
    if ( @sets ) { $self->{ sets } = \@sets; }
    return( @{ $self->{ sets } } );
}

my $xmlns_oai = "http://www.openarchives.org/OAI/2.0/";

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    if ( $element->{ LocalName } eq 'record' ) { 
	$self->{ insideHeader } = $self->{ insideSet } = $self->{ insideMetadata } = 0}
    elsif ( $element->{ LocalName } eq 'header' ) { 
	$self->{ insideHeader } = 1;
	if ( exists( $element->{ Attributes }{ '{}status' } ) ) {
	    $self->{ headerStatus } = 
                $element->{ Attributes }{ '{}status' }{ Value };
	} else {
	    $self->{ headerStatus } = '';
	}
    }
    elsif ( $element->{ LocalName } eq 'setSpec' ) {
	$self->{ insideSet } = 1;
    }
    elsif ( $element->{ LocalName } eq 'metadata' ) {
	$self->{ insideMetadata } = 1;
    }
#    elsif ( $self->{ insideMetadata } ) {
#	$self->SUPER::start_element( $element );
#    }
    push( @{ $self->{ tagStack } }, $element->{ LocalName } );
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    my $tagName = $element->{ LocalName };

    if ( $tagName eq 'header' ) {
	$self->{ insideHeader } = 0;
        ($self->{header} =~ /\S/) && carp "Excess content in record header: ".$self->{ header };
    }
    elsif ( $tagName eq 'setSpec' ) { 
	push( @{ $self->{ sets } }, $self->{ setSpec } );
	$self->{ insideSet } = 0;
    }
    elsif ( $element->{ LocalName } eq 'metadata' ) {
	$self->{ insideMetadata } = 0;
    }
#    elsif ( $self->{ insideMetadata } ) {
#	$self->SUPER::end_element( $element );
#   }
    pop( @{ $self->{ tagStack } } );
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ insideHeader } ) { 
	$self->{ $self->{ tagStack }[-1] } .= $characters->{ Data }}
    elsif ( $self->{ insideMetadata } ) { 
	$self->SUPER::characters( $characters )}
}

1;

