package Net::OAI::Record::OAI_DC;

use strict;
use base qw( XML::SAX::Base );
our $VERSION = 'v1.00.0';

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

Net::OAI::Record::OAI_DC - class for baseline Dublin Core support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The accessor methods are aware of their calling context (list,scalar) and
will respond appropriately. For example an item may have multiple creators,
so a call to creator() in a scalar context returns only the first creator;
and in a list context all creators are returned.

    # scalar context
    my $creator = $metadata->creator();
    
    # list context
    my @creators = $metadata->creator();

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
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
    my @result;
    foreach my $element ( @OAI_DC_ELEMENTS ) {
        next unless $self->{ $element };
	foreach ( @{ $self->{ $element } } ) {
	    push(@result, "$element => $_");
	}
    }
    return join("\n", @result);
}

## SAX handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'metadata' ) {
	$self->{ insideMetadata } = 1;
    }
    $self->{ chars } = '';
}

sub end_element {
    my ( $self, $element ) = @_;
    ## strip namespace from element name
    my ( $elementName ) = ( $element->{ Name } =~ /^(?:.*:)?(.*)$/ );
    if ( $elementName eq 'metadata' ) { 
	$self->{ insideMetadata } = undef; 
    }
    if ( $self->{ insideMetadata } ) { 
	push( @{ $self->{ $elementName } }, $self->{ chars } );
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    $self->{ chars } .= $characters->{ Data };
}

1;

