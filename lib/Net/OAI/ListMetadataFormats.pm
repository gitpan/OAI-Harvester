package Net::OAI::ListMetadataFormats;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );

=head1 NAME

Net::OAI::ListMetadataFormats - Results of the ListMetadataFormats OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ insideList } = 0;
    $self->{ metadataPrefixes } = [];
    return( $self );
}

sub prefixes() {
    my $self = shift;
    return( @{ $self->{ metadataPrefixes } } );
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'ListMetadataFormats' ) { 
	$self->{ insideList } = 1;
    } else {
	$self->SUPER::start_element( $element );
    }
    push( @{ $self->{ tagStack } }, $element->{ Name } );
}

sub end_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'ListMetadataFormats' ) {
	$self->{ insideList } = 0;
    } elsif ( $element->{ Name } eq 'metadataPrefix' ) {
	push( @{ $self->{ metadataPrefixes } }, $self->{ metadataPrefix } );
	$self->{ metadataPrefix } = '';
    } else {
	$self->SUPER::end_element( $element );
    }
    pop( @{ $self->{ tagStack } } );
}

sub characters {
    my ( $self, $characters ) = @_;
    $self->SUPER::characters( $characters );
    $self->{ $self->{ tagStack }[-1] } .= $characters->{ Data };
}

1;
