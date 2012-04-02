package MyHandler; 

# custom handler for testing that we can drop in our own metadata
# handler in t/03.getrecord.t and t/50.listrecords.t

use base qw( XML::SAX::Base );

my $xmlns_dc = "http://purl.org/dc/elements/1.1/";

sub title { 
    my $self = shift;
    return( $self->{ title } );
}

sub start_element {
    my ( $self, $element ) = @_; 
    if ( ($element->{ NamespaceURI } eq $xmlns_dc)
      && ($element->{ LocalName } eq 'title') ) { 
	$self->{ foundTitle } = 1;
	$self->{ title } = "";
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    if ( ($element->{ NamespaceURI } eq $xmlns_dc)
      && ($element->{ LocalName } eq 'title') ) {
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
