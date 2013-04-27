package Net::OAI::Error;

use strict;
use base qw( XML::SAX::Base Exporter );
our @EXPORT = (
);

=head1 NAME

Net::OAI::Error - OAI-PMH errors.

=head1 SYNOPSIS

=head1 DESCRIPTION

Note: Actually this is a filter which actually processes all top-level
OAI-PMH elements.

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ tagStack } = [];
    $self->{ errorCode } = '' if ! exists( $self->{ errorCode } );
    $self->{ errorString }  = '' if ! exists( $self->{ errorString } );
# do not initialize $self->{ HTTPError } and $self->{ HTTPRetryAfter }
    return( $self );
}

=head2 errorCode()

Returns an OAI error if one was encountered, or the empty string if no errors 
were associated with the OAI request.

=over 4

=item 

badArgument

=item 

badResumptionToken

=item 

badVerb

=item 

cannotDisseminateFormat

=item 

idDoesNotExist

=item 

noRecordsMatch

=item 

noMetadataFormats

=item 

noSetHierarchy

=item 

xmlParseError

=item 

xmlContentError

=item 

numerical HTTP status code

=back

For more information about these error codes see:
L<http://www.openarchives.org/OAI/openarchivesprotocol.html#ErrorConditions>.

=cut

sub errorCode {
    my ( $self, $code ) = @_;
    if ( $code ) { $self->{ errorCode } = $code; }
    return( $self->{ errorCode } );
}

=head2 errorString()

Returns a textual description of the error that was encountered, or an empty
string if there was no error associated with the OAI request.

=cut

sub errorString {
    my ( $self, $str ) = @_;
    if ( $str ) { $self->{ errorString } = $str; }
    return( $self->{ errorString } );
}

=head2 HTTPError()

In case of HTTP level errors, returns the associated HTTP::Response object.
Otherwise C<undef>.


=cut

sub HTTPError {
    my ( $self ) = @_;
    return exists $self->{ HTTPError } ? $self->{ HTTPError } : undef;
}


=head2 HTTPRetryAfter()

In case of HTTP level errors, returns the Retry-After header of the HTTP Response object,
or the empty string if no such header is persent. Otherwise C<undef>.


=cut

sub HTTPRetryAfter {
    my ( $self ) = @_;
    return exists $self->{ HTTPRetryAfter } ? $self->{ HTTPRetryAfter } : undef;
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
my $xmlns_oai = "http://www.openarchives.org/OAI/2.0/";

sub start_element { 
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;  # should be error?

    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'request' ) {
        Net::OAI::Harvester::debug( "caught request" );
	$self->{ _requestAttrs } = {};
        foreach ( values %{$element->{ Attributes }} ) {
            next if $_->{ Prefix };
            $self->{ _requestAttrs }->{ $_->{ Name } } = $_->{ Value };
          }
	$self->{ _insideError } = "";
      }
    elsif ( $tagName eq 'responseDate' ) {
        Net::OAI::Harvester::debug( "caught responseDate" );
	$self->{ _insideError } = "";
      }
    elsif ( $tagName eq 'error' ) {
        Net::OAI::Harvester::debug( "caught error" );
	$self->{ errorCode } = $element->{ Attributes }{ '{}code' }{ Value };
	$self->{ _insideError } = "";
    } else { 
	$self->SUPER::start_element( $element );
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element($element) unless $element->{NamespaceURI} eq $xmlns_oai;  # should be error?
    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'request' ) {
	$self->{ _requestContent } = $self->{ _insideError };
	delete $self->{ _insideError };
      }
    elsif ( $tagName eq 'responseDate' ) {
	$self->{ _responseDate } = $self->{ _insideError };
	delete $self->{ _insideError };
      }
    elsif ( $tagName eq 'error' ) {
	$self->{ errorString } = $self->{ _insideError };
	delete $self->{ _insideError };
    } else {
	$self->SUPER::end_element( $element );
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( exists $self->{ _insideError } ) { 
	$self->{ _insideError } .= $characters->{ Data };
    } else { 
	$self->SUPER::characters( $characters );
    }
}

1;
