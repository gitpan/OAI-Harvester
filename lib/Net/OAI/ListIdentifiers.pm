package Net::OAI::ListIdentifiers;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );
use Net::OAI::Record::Header;
use File::Temp qw( tempfile );
use IO::File;
use Storable qw( store_fd fd_retrieve );

=head1 NAME

Net::OAI::ListIdentifiers - Results of the ListIdentifiers OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    
    ## open a temp file for storing identifiers
    my ($fh,$filename) = tempfile();
    $self->{ headerFileHandle } = $fh;
    $self->{ headerFilename } = $filename;
    ## so we can store code refs
    $Storable::Deparse = 1;
    $Storable::Eval = 1;
    return( $self );
}

=head2 next()

=cut

sub next { 
    my $self = shift;

    if ( ! $self->{ headerFileHandle } ) {
	$self->{ headerFileHandle } = 
	    IO::File->new( $self->{ headerFilename } )
	    || die "unable to open temp file: ".$self->{ headerFilename };
    }

    if ( $self->{ headerFileHandle }->eof() ) {
	$self->{ headerFileHandle }->close();
	return( $self->handleResumptionToken( 'listIdentifiers' ) );
    }

    my $header = fd_retrieve( $self->{ headerFileHandle } );
    return( $header );
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'header' ) {
	$self->{ OLD_Handler } = $self->get_handler();
	$self->set_handler( Net::OAI::Record::Header->new() );
    }
    $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;
    $self->SUPER::end_element( $element );
    if ( $element->{ Name } eq 'header' ) {
	my $header = $self->get_handler();
        Net::OAI::Harvester::debug( "committing header to object store" );
	store_fd( $header, $self->{ headerFileHandle } );
	$self->set_handler( $self->{ OLD_Handler } );
    } elsif ( $element->{ Name } eq 'ListIdentifiers' ) {
        Net::OAI::Harvester::debug( "finished reading identifiers" );
	$self->{ headerFileHandle }->close();
	$self->{ headerFileHandle } = undef;
    }
}

1;

