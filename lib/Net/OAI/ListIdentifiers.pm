package Net::OAI::ListIdentifiers;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );
use Net::OAI::Record::Header;
use File::Temp qw( tempfile );
use YAML;

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

    local $/ = "__END_OF_RECORD__\n";
    my $data = $self->{ headerFileHandle }->getline();
    chomp( $data );

    if ( ! defined($data) ) {
	$self->{ headerFileHandle }->close();
	return( undef );
    }

    my $header = Load( $data );
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
	$self->{ headerFileHandle }->print( Dump($header), 
	    "\n__END_OF_RECORD__\n" );
	$self->set_handler( $self->{ OLD_Handler } );
    } elsif ( $element->{ Name } eq 'ListIdentifiers' ) {
	$self->{ headerFileHandle }->close();
	$self->{ headerFileHandle } = undef;
    }
}

sub DESTROY {
    # remove header temp file
    my $self = shift;
    if ( $self->{ headerFilename } ) {
	unlink( $self->{ headerFilename } );
    }
    $self->SUPER::DESTROY;
}


1;

