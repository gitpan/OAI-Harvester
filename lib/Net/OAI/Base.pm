package Net::OAI::Base;

use strict;
use Carp qw ( croak );

=head1 NAME

Net::OAI::Base - A base class for all OAI-PMH responses

=head1 SYNOPSIS

    if ( $object->resumptionToken() ) { 
	...
    }

    if ( $object->errorCode() ) { 
	print "verb action resulted in error code:" . $object->errorCode() . 
	    " message:" . $object->errorString() . "\n";
    }

    print "xml response can be found here: " . $obj->file() . "\n";
    print "the response xml is " . $obj->xml(); 

=head1 DESCRIPTION

Net::OAI::Base is the base class for all the OAI-PMH verb responses. It is
used to provide similar methods to all the responses. The following 
classes inherit from Net::OAI::Base.

=over 4

=item * 

Net::OAI::GetRecord

=item *

Net::OAI::Identify

=item * 

Net::OAI::ListIdentifiers

=item *

Net::OAI::ListMetadataFormats

=item *

Net::OAI::ListRecords

=item * 

Net::OAI::ListSets

=back

=head1 METHODS

=head2 errorCode()

Returns an error code associated with the verb result.

=cut

sub errorCode {
    my $self = shift;
    if ( $self->{ error } ) { 
	return( $self->{ error }->errorCode() );
    }
    return( undef );
}

=head2 errorString()

Returns an error message associated with an error code.

=cut

sub errorString {
    my $self = shift;
    if ( $self->{ error } ) {
	return( $self->{ error }->errorString() );
    }
    return( undef );
}

=head2 HTTPRetryAfter()

Returns the HTTP Retry-After header in case of HTTP level errors.

=cut

sub HTTPRetryAfter {
    my ( $self ) = @_;
    return undef unless $self->{ error };
    return $self->{ error }->HTTPRetryAfter();
}


=head2 HTTPError()

Returns the HTTP::Response object in case of HTTP level errors.

=cut

sub HTTPError {
    my ( $self ) = @_;
    return $self->{ error }->HTTPError();
}


=head2 resumptionToken() 

Returns a Net::OAI::ResumptionToken object associated with the call. If 
there was no resumption token returned in the response then you will 
be returned undef.

=cut

sub resumptionToken {
    my $self = shift;
    return( $self->{ token } );
}

=head2 xml()

Returns a reference to a scalar that contains the raw content of the response 
as XML.

=cut 

sub xml {
    my(  $self, %args ) = shift;
    return undef unless $self->{ file };    # not set eg. after HTTP error
    open( XML, $self->{ file } ) or croak "unable to open file ".$self->{ file };
    ## slurp entire file into $xml
    local $/ = undef;
    my $xml = <XML>;
    close(XML);            # prevent tempfile leak on Win32
    return( $xml );
}

=head2 file()

Returns the path to a file that contains the complete XML response.

=cut

sub file {
    my $self = shift;
    return( $self->{ file } );
}

sub handleResumptionToken {
    my ( $self, $method ) = @_;

    my $harvester = exists( $self->{ harvester } ) ? $self->{ harvester } : 0;
    return() unless $harvester && $harvester->isa('Net::OAI::Harvester');

    my $rToken = $self->resumptionToken();
    if ( $rToken ) { 
	my $new = $harvester->$method( resumptionToken => $rToken->token(), 
            metadataHandler => $self->{metadataHandler} );
	$new->{ harvester } = $harvester;
	%$self = %$new; 
	return( $self->next() );
    }

    return();
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

1;
