package Net::OAI::Record::Header;

use strict;
use base qw( XML::SAX::Base );
use Carp qw( carp );
our $VERSION = 'v1.01.0';


=head1 NAME

Net::OAI::Record::Header - class for record header representation

=head1 SYNOPSIS

=head1 DESCRIPTION

Actually this class implements the filtering SAX parser for the 
complete C<record> OAI-PMH element. The contents of the C<header> 
child are collected into a header object and can be accessed by the
methods documented here.

Events will be traditionally forwarded only from the subelement(s) of 
the C<metadata> child which makes it difficult to access data 
contained in the (possibly multiple) C<about> containers which may follow 
the C<metadata> in the C<record>.

Beginning from OAI-Harvester v1.17 a new "recordHandler" argument
may be given to the harvester functions C<getRecord()> and C<listRecords()>:
In contrast to a "metadataHandler" argument this will pass the "fwdAll"
argument to the constructor of this Header class and result in 
forwarding all events in the C<record> (including C<record> itself) to 
the handler specified, not only those from C<metadata> children.

The SAX filter implemented by this class purposefully does not generate 
any start_document() or end_document() events.


=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ status } = $self->{ identifier } = $self->{ datestamp } = '';
    $self->{ _tagStack } = [];
    $self->{ sets } = [];
    $self->{ _insideHeader } = $self->{ _insideMetadata } = $self->{ _insideAbout } = 0;
    return( $self );
}

=head2 status()

=cut 

sub status {
    my ( $self, $status ) = @_;
    if ( $status ) { $self->{ headerStatus } = $status; }
    return( $self->{ headerStatus } );
}

=head2 identifier()

=cut

sub identifier {
    my ( $self, $id ) = @_;
    if ( $id ) { $self->{ identifier } = $id; }
    return( $self->{ identifier } );
}

=head2 datestamp()

=cut

sub datestamp {
    my ( $self, $datestamp ) = @_;
    if ( $datestamp ) { $self->{ datestamp } = $datestamp; }
    return( $self->{ datestamp } );
}

=head2 setSpecs()
=head2 sets()  DEPRECATED

=cut

sub setSpecs {
    my ( $self, @sets ) = @_;
    if ( @sets ) { $self->{ sets } = \@sets; }
    return( @{ $self->{ sets } } );
}

sub sets {
    return setSpecs(@_);
}

## SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    unless ( $element->{ NamespaceURI } eq Net::OAI::Harvester::XMLNS_OAI ) {
        $self->SUPER::start_element($element) if $self->{ fwdAll } or $self->{ _insideMetadata };
        return;
    }

    my $tagName = $element->{ LocalName };
    push( @{$self->{ _tagStack }}, $tagName );
    if ( $tagName eq 'record' ) { 
	$self->{ _insideHeader } = $self->{ _insideMetadata } = $self->{ _insideAbout } = 0}
    elsif ( $tagName eq 'header' ) { 
	$self->{ _insideHeader } = 1;
        $self->{ headerStatus } = ( exists $element->{ Attributes }{ '{}status' } )
                                ? $element->{ Attributes }{ '{}status' }{ Value }
                                : "";
    }
    elsif ( $self->{ _insideHeader } ) {
    }
    elsif ( $tagName eq 'metadata' ) {
	$self->{ _insideMetadata } = 1;
    }
    elsif ( $tagName eq 'about' ) {
	$self->{ _insideAbout } = 1;
    }
    else {
warn "who am I? ($tagName)";
        return $self->SUPER::start_element($element);
    };
    return $self->SUPER::start_element($element) if $self->{ fwdAll };
}

sub end_element {
    my ( $self, $element ) = @_;
    unless ( $element->{ NamespaceURI } eq Net::OAI::Harvester::XMLNS_OAI ) {
        $self->SUPER::end_element($element) if $self->{ fwdAll } or $self->{ _insideMetadata };
        return;
    }

    pop( @{$self->{ _tagStack }} );
    my $tagName = $element->{ LocalName };
    if ( $tagName eq 'header' ) {
	$self->{ _insideHeader } = 0;
        (defined $self->{header}) && ($self->{header} =~ /\S/) && carp "Excess content in record header: ".$self->{ header };
    }
    elsif ( $tagName eq 'setSpec' ) { 
	push( @{ $self->{ sets } }, $self->{ setSpec } );
    }
    elsif ( $self->{ _insideHeader } ) {
    }
    elsif ( $tagName eq 'metadata' ) {
	$self->{ _insideMetadata } = 0;
    }
    elsif ( $tagName eq 'about' ) {
#	push( @{ $self->{ sets } }, $self->{ setSpec } );
	$self->{ _insideAbout } = 0;
    }
    elsif ( $tagName eq 'record' ) {
        delete $self->{ _insideHeader };
	delete $self->{ _insideMetadata };
	delete $self->{ _insideAbout };
	delete $self->{ _tagStack };
    }
    else {
warn "who am I? ($tagName)";
        return $self->SUPER::end_element( $element );
    };
    return $self->SUPER::end_element($element) if $self->{ fwdAll };
}


sub ignorable_whitespace {
    my ( $self, $characters ) = @_;
    return $self->SUPER::ignorable_whitespace( $characters ) if $self->{ fwdAll } or $self->{ _insideMetadata };
}

sub characters {
    my ( $self, $characters ) = @_;
    $self->{ $self->{ _tagStack }[-1] } .= $characters->{ Data } if $self->{ _insideHeader };
    return $self->SUPER::characters( $characters ) if $self->{ fwdAll } or $self->{ _insideMetadata };
}

1;

