package Net::OAI::ResumptionToken;

use strict;
use base qw ( XML::SAX::Base );

=head1 NAME

Net::OAI::ResumptionToken - An OAI-PMH resumption token.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ tagStack } = [];
    $self->{ insideResumptionToken } = 0;
    $self->{ token } = '';
    $self->{ expirationDate } = '';
    $self->{ completeListSize } = '';
    $self->{ cursor } = '';
    return( $self );
}

=head2 token()

=cut

sub token {
    my ( $self, $token ) = @_;
    if ( $token ) { $self->{ token } = $token; }
    return( $self->{ resumptionTokenText } );
}

=head2 expirationDate()

=cut

sub expirationDate {
    my ( $self, $date ) = @_;
    if ( $date ) { $self->{ expirationDate } = $date; }
    return( $self->{ expirationDate } );
}

=head2 completeListSize()

=cut

sub completeListSize {
    my ( $self, $size ) = @_;
    if ( $size ) { $self->{ completeListSize } = $size; }
    return( $self->{ completeListSize } );
}

=head2 cursor()

=cut 

sub cursor {
    my ( $self, $cursor ) = @_;
    if ( $cursor ) { $self->{ cursor } = $cursor; }
    return( $self->{ cursor } );
}

=head1 TODO

=head1 SEE ALSO

=over 4

=back

=head1 AUTHORS

=over 4 

=item * Ed Summers <ehs@pobox.com>

=back

=cut

## internal stuff

## all children of Net::OAI::Base should call this to make sure
## certain object properties are set

sub start_element { 
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'resumptionToken' ) {
	my $attr = $element->{ Attributes };
	$self->{ expirationDate } = $attr->{ '{}expirationDate' }{ Value };
	$self->{ completeListSize } = $attr->{ '{}completeListSize' }{ Value };
	$self->{ cursor } = $attr->{ '{}cursor' }{ Value };
	$self->{ insideResumptionToken } = 1;
    } else { 
	$self->SUPER::start_element( $element );
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'resumptionToken' ) {
        Net::OAI::Harvester::debug( "caught resumption token" );
	$self->{ insideResumptionToken } = 0;
    } else { 
	$self->SUPER::end_element( $element );
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ insideResumptionToken } ) {
	$self->{ resumptionTokenText } .= $characters->{ Data };
    } else { 
	$self->SUPER::characters( $characters );
    }
}

1;

