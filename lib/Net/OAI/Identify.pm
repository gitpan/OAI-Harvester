package Net::OAI::Identify;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );

=head1 NAME

Net::OAI::Indentity - Results of the Indentify OAI-PMH verb. 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ repositorName } = '';
    $self->{ baseUrl } = '';
    $self->{ protocolVersion } = '';
    $self->{ earliestDatestamp } = '';
    $self->{ deletedRecord } = '';
    $self->{ granularity } = '';
    $self->{ adminEmail } = '';
    $self->{ adminEmails } = [];
    $self->{ compression } = '';
    $self->{ compressions } = [];
    $self->{ insideDescription } = 0;
    return( $self );
}

sub repositoryName {
    my $self = shift;
    return( $self->{ repositoryName } );
}

sub baseURL {
    my $self = shift;
    return( $self->{ baseURL } );
}

sub protocolVersion {
    my $self = shift;
    return( $self->{ protocolVersion } );
}

sub earliestDatestamp {
    my $self = shift;
    return( $self->{ earliestDatestamp } );
}

sub deletedRecord {
    my $self = shift;
    return( $self->{ deletedRecord } );
}

sub granularity {
    my $self = shift;
    return( $self->{ granularity } );
}

=head1 adminEmail()

Returns the administrative email address for the repository. Since the 
adminEmail elelemnt is allowed to repeat you will get all the emails (if more 
than one are specified) by using adminEmail in a list context.

    $email = $identity->adminEmail();
    @emails = $identity->adminEmails();

=cut

sub adminEmail {
    my $self = shift;
    if ( wantarray() ) { return( @{ $self->{ adminEmails } } ); }
    return( $self->{ adminEmails }[ 0 ] );
}

=head1 compression() {

Returns the types of compression that the archive supports. Since the 
compression element may repeat you may get all the values by using 
compression() in a list context.

    $compression = $identity->compression();
    @compressions = $identity->compressions();

=cut

sub compression {
    my $self = shift;
    if ( wantarray() ) { return( @{ $self->{ compressions } } ); }
    return( $self->{ compressions }[ 0 ] );
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    push( @{ $self->{ tagStack } }, $element->{ Name } );
}

sub end_element {
    my ( $self, $element ) = @_;

    ## store and reset elements that can have multiple values
    if ( $element->{ Name } eq 'adminEmail' ) {
	push( @{ $self->{ adminEmails } }, $self->{ adminEmail } );
	$self->{ adminEmail } = '';
    }
    elsif ( $element->{ Name } eq 'compression' ) { 
	push( @{ $self->{ compressions } }, $self->{ compression } );
	$self->{ compression } = '';
    }
    pop( @{ $self->{ tagStack } } );

}

sub characters {
    my ( $self, $characters ) = @_;
    $self->{ $self->{ tagStack }[-1] } .= $characters->{ Data };
}

1;
