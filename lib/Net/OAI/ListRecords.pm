package Net::OAI::ListRecords;

use strict;
use base qw( XML::SAX::Base );
use base qw( Net::OAI::Base );
use Net::OAI::Record;
use Net::OAI::Record::Header;
use Net::OAI::Record::OAI_DC;
use File::Temp qw( tempfile );
use YAML;

$YAML::DumpCode = 0;

=head1 NAME

Net::OAI::ListRecords - Results of the ListRecords OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    my ( $fh, $tempfile ) = tempfile();
    binmode( $fh, ':utf8' );
    $self->{ recordsFileHandle } = $fh; 
    $self->{ recordsFilename } = $tempfile;
    return( $self );
}

=head2 next()

=cut

sub next { 
    my $self = shift;

    if ( ! $self->{ recordsFileHandle } ) {
	$self->{ recordsFileHandle } = 
	    IO::File->new( $self->{ recordsFilename } )
	    || die "unable to open temp file: ".$self->{ recordsFilename };
        binmode( $self->{ recordsFileHandle }, ':utf8' );
    }

    local $/ = "__END_OF_RECORD__\n";
    my $data = $self->{ recordsFileHandle }->getline();
    chomp( $data );

    if ( ! defined( $data ) ) {
	$self->{ recordsFileHandle }->close();
	return( undef );
    }

    my $record = Load( $data );
    return( $record );
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    if ( $element->{ Name } eq 'record' ) { 
	$self->{ OLD_Handler } = $self->get_handler();
	my $metadata = Net::OAI::Record::OAI_DC->new();
	my $header = Net::OAI::Record::Header->new( Handler => $metadata );
	$self->set_handler( $header );
    }
    $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;
    $self->SUPER::end_element( $element );
    if ( $element->{ Name } eq 'record' ) {
	my $header = $self->get_handler();
	my $metadata = $header->get_handler();
	$header->set_handler( undef ); ## remove reference to $record
	$self->set_handler( $self->{ OLD_Handler } );
	my $record = Net::OAI::Record->new( 
	    header	=> $header,
	    metadata	=> $metadata,
	);
	$self->{ recordsFileHandle }->print( 
	    Store( $record ),"\n",
	    "__END_OF_RECORD__\n"
	);
    } 
    elsif ( $element->{ Name } eq 'ListRecords' ) {
	$self->{ recordsFileHandle }->close();
	$self->{ recordsFileHandle } = undef;
    }
}

sub DESTROY {
    my $self = shift;
    if ( $self->{ recordsFilename } ) {
	unlink( $self->{ recordsFilename } );
    }
    $self->SUPER::DESTROY;
}

1;


