package Net::OAI::Base;

use strict;

=head1 NAME

Net::OAI::Base - A base class for all OAI-PMH responses

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 errorCode()

=cut

sub errorCode {
    my $self = shift;
    if ( $self->{ error } ) { 
	return( $self->{ error }->errorCode() );
    }
    return( undef );
}

=head2 errorString()

=cut

sub errorString {
    my $self = shift;
    if ( $self->{ error } ) {
	return( $self->{ error }->errorString() );
    }
    return( undef );
}

=head2 resumptionToken() 

Returns the resumption token object.

=cut

sub resumptionToken {
    my $self = shift;
    return( $self->{ token } );
}

=head2 xml()

Returns the raw content of the response as XML.

=cut 

sub xml {
    my(  $self, %args ) = shift;
    open( XML, $self->{ file } ) || die "unable to open $self->{ file }";
    while( <XML> ) { print; }
    close( XML );
}

=head2 file()

Returns the file location of the XML response.

=cut

sub file {
    my $self = shift;
    return( $self->{ file } );
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

# remove any temp files, when object is destroyed

sub DESTROY {
    my $self = shift;
    if ( $self->{ file } ) { 
	unlink( $self->{ file } );
    }
}

1;
