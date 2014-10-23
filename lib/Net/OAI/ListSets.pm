package Net::OAI::ListSets;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );

=head1 NAME

Net::OAI::ListSets - The results of the ListSets OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ insideSet } = 0;
    $self->{ specs } = {};
    return( $self );
}

=head2 setSpecs()

Get back a list of set specification codes.

=cut

sub setSpecs {
    my $self = shift;
    return( sort( keys( %{ $self->{ specs } } ) ) );
}

=head2 setName()

Pass in a setSpec code, and get back it's name...or undef if the set spec does 
not exist for this repository. 

=cut

sub setName {
    my ( $self, $setSpec ) = @_; 
    if ( exists( $self->{ specs }{ $setSpec } ) ) {
	return( $self->{ specs }{ $setSpec } );
    } 
    return( undef );
}

my $xmlns_oai = "http://www.openarchives.org/OAI/2.0/";

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    $self->SUPER::start_element( $element );
    return unless $element->{NamespaceURI} eq $xmlns_oai;
    push( @{ $self->{ tagStack } }, $element->{ LocalName } );
}

sub end_element {
    my ( $self, $element ) = @_;
    $self->SUPER::end_element( $element );
    return unless $element->{NamespaceURI} eq $xmlns_oai;
    if ( $element->{ LocalName } eq 'set' ) { 
	$self->{ specs }{ $self->{ setSpec } } = $self->{ setName };
	$self->{ setSpec } = $self->{ setName } = undef;
    }
    pop( @{ $self->{ tagStack } } );
}

sub characters {
    my ( $self, $characters ) = @_;
    my $insideTag = @{ $self->{ tagStack } }[-1];
    if ( $insideTag =~ /^(setName|setSpec)$/ ) { 
	$self->{ $insideTag } .= $characters->{ Data };
    }
    $self->SUPER::characters( $characters );
}

1;
