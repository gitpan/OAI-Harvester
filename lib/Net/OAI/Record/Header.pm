package Net::OAI::Record::Header;

use strict;
use base qw( XML::SAX::Base );

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
    $self->{ status } = '';
    $self->{ identifier	} = '';
    $self->{ datestamp } = '';
    $self->{ sets } = [];
    $self->{ insideHeader } = 0;
    $self->{ insideSet } = 0;
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

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'header' ) { 
	$self->{ insideHeader } = 1;
	if ( exists( $element->{ Attributes }{ '{}status' } ) ) {
	    $self->{ headerStatus } = 
                $element->{ Attributes }{ '{}status' }{ Value };
	} else {
	    $self->{ headerStatus } = '';
	}
    }
    elsif ( $element->{ Name } eq 'setSpec' ) {
	$self->{ insideSet } = 1;
    }
    else {
	$self->SUPER::start_element( $element );
    }
    push( @{ $self->{ tagStack } }, $element->{ Name } );
}

sub end_element {
    my ( $self, $element ) = @_;
    my $tagName = $element->{ Name };
    if ( $tagName eq 'header' ) {
	$self->{ insideHeader } = 0;
    }
    elsif ( $tagName eq 'setSpec' ) { 
	push( @{ $self->{ sets } }, $self->{ setSpec } );
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

