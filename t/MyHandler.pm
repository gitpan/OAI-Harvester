package MyHandler; 

# custom handler for testing that we can drop in our own metadata
# handler in t/03.getrecord.t and t/50.listrecords.t

use base qw( XML::SAX::Base );

sub title { 
    my $self = shift;
    return( $self->{ title } );
}

sub start_element {
    my ( $self, $element ) = @_; 
    if ( $element->{ Name } eq 'dc:title' ) { 
	$self->{ foundTitle } = 1; 
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'dc:title' ) {
	$self->{ foundTitle } = 0;
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ foundTitle } ) {
	$self->{ title } .= $characters->{ Data };
    }
}

1;
