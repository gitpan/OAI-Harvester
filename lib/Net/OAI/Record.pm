package Net::OAI::Record;

use strict;

=head1 NAME

Net::OAI::Record - An OAI-PMH record.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

probably don't want to instantiate this yourself

=cut

sub new {
    my ( $class, %opts ) = @_;
    return bless {
	header	    => $opts{ header },
	metadata    => $opts{ metadata }
    }, ref( $class ) || $class;
}

=head2 header()

=cut

sub header {
    my $self = shift;
    return( $self->{ header } );
}

=head2 metadata()

=cut 

sub metadata {
    my $self = shift;
    return( $self->{ metadata } );
}

=head1 TODO

=head1 SEE ALSO

=back

=head1 AUTHORS

=over 4 

=item * Ed Summers <ehs@pobox.com>

=back

=cut


1;
