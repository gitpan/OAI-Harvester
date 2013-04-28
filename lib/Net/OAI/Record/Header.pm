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
    $self->{ _insideHeader } = $self->{ _insideMetadata } = $self->{ _insideAbout } = 0;
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

    my $tagName = $element->{ LocalName };
    push( @{$self->{ tagStack }}, $tagName );
    if ( $tagName eq 'record' ) { 
	$self->{ _insideHeader } = $self->{ _insideMetadata } = $self->{ _insideAbout } = 0}
    elsif ( $tagName eq 'header' ) { 
	$self->{ _insideHeader } = 1;
        $self->{ headerStatus } = ( exists $element->{ Attributes }{ '{}status' } )
                                ? $element->{ Attributes }{ '{}status' }{ Value }
                                : "";
    }
    elsif ( $self->{ _insideHeader } ) {
    }
    elsif ( $tagName eq 'metadata' ) {
	$self->{ _insideMetadata } = 1;
    }
    elsif ( $tagName eq 'about' ) {
	$self->{ _insideAbout } = 1;
    }
    else {
        return $self->SUPER::start_element($element);
    };
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;

    pop( @{$self->{ tagStack }} );
    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'header' ) {
	$self->{ _insideHeader } = 0;
        (defined $self->{header}) && ($self->{header} =~ /\S/) && carp "Excess content in record header: ".$self->{ header };
    }
    elsif ( $tagName eq 'setSpec' ) { 
	push( @{ $self->{ sets } }, $self->{ setSpec } );
    }
    elsif ( $tagName eq 'metadata' ) {
	$self->{ _insideMetadata } = 0;
    }
    elsif ( $tagName eq 'about' ) {
#	push( @{ $self->{ sets } }, $self->{ setSpec } );
	$self->{ _insideAbout } = 0;
    }
    elsif ( $self->{ _insideHeader } ) {
    }
    else {
        return $self->SUPER::end_element( $element );
    };
}


sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ _insideHeader } ) { 
	$self->{ $self->{ tagStack }[-1] } .= $characters->{ Data }}
    elsif ( $self->{ _insideMetadata } ) { 
        $self->SUPER::characters( $characters )}
#   elsif ( $self->{ _insideAbout } ) { 
#       $self->SUPER::characters( $characters )}
}

1;

