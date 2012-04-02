package YourHandler; 

# custom handler for testing that we can drop in our own metadata
# handler in t/03.getrecord.t and t/50.listrecords.t

use base qw( MyHandler );

sub result { 
    my $self = shift;
    return( $self->{ title } );
}

1;
