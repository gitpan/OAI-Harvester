package Net::OAI::Error;

use strict;
use base qw( XML::SAX::Base Exporter );
our @EXPORT = (
);

=head1 NAME

Net::OAI::Error - OAI-PMH errors.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ tagStack } = [];
    $self->{ insideError } = 0; 
    $self->{ errorCode } = '' if ! exists( $self->{ errorCode } );
    $self->{ errorString }  = '' if ! exists( $self->{ errorString } );
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

sub start_element { 
    my ( $self, $element ) = @_;
    my $tagName = $element->{ Name };
    if ( $tagName eq 'error' ) {
	$self->{ errorCode } = $element->{ Attributes }{ '{}code' }{ Value };
	$self->{ insideError } = 1;
    } else { 
	$self->SUPER::start_element( $element );
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    my $tagName = $element->{ Name };
    if ( $tagName eq 'error' ) {
	$self->{ insideError } = 0;
    } else {
	$self->SUPER::end_element( $element );
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ insideError } ) { 
	$self->{ errorString } .= $characters->{ Data };
    } else { 
	$self->SUPER::characters( $characters );
    }
}

1;
