package Net::OAI::Record::OAI_DC;

use strict;
use base qw( XML::SAX::Base );

our @OAI_DC_ELEMENTS = qw(
    title 
    creator 
    subject 
    description 
    publisher 
    contributor 
    date
    type
    format
    identifier
    source
    language
    relation
    coverage
    rights
);

our $AUTOLOAD;

=head1 NAME

Net::OAI::Record::OAI_DC - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ insideTag } = undef;
    foreach ( @OAI_DC_ELEMENTS ) { $self->{ $_ } = []; }
    return( $self );
}

=head2 title()

=head2 creator()

=head2 subject()

=head2 description()

=head2 publisher()

=head2 contributor()

=head2 date()

=head2 type()

=head2 format()

=head2 identifier()

=head2 source()

=head2 language()

=head2 relation()

=head2 coverage()

=head2 rights()

=cut

## rather than right all the accessors we use AUTOLOAD to catch calls
## valid element names as methods, and return appropriately as a list

sub AUTOLOAD {
    my $self = shift;
    my $sub = lc( $AUTOLOAD );
    $sub =~ s/.*:://;
    if ( grep /$sub/, @OAI_DC_ELEMENTS ) {
	if ( wantarray() ) { 
	    return( @{ $self->{ $sub } } );
	} else { 
	    return( $self->{ $sub }[0] );
	}
    }
}

## generic output method 

sub asString {
    my $self = shift;
    foreach my $element ( @OAI_DC_ELEMENTS ) {
	foreach ( @{ $self->{ $element } } ) {
	    print "$element => $_\n";
	}
    }
}

## SAX handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'metadata' ) {
	$self->{ insideMetadata } = 1;
    }
    $self->{ chars } = '';
    $self->{ insideTag } = $element->{ Name };
}

sub end_element {
    my ( $self, $element ) = @_;
    my $element = $self->{ insideTag };
    $element =~ s/.*://; # strip namespace to get bare element
    if ( $element eq 'metadata' ) { 
	$self->{ insideMetadata } = undef; 
    }
    if ( $self->{ insideMetadata } ) { 
	push( @{ $self->{ $element } }, $self->{ chars } );
    }
    $self->{ insideTag } = undef;
}

sub characters {
    my ( $self, $characters ) = @_;
    $self->{ chars } .= $characters->{ Data };
}

1;

