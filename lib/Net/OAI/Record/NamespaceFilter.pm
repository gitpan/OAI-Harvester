package Net::OAI::Record::NamespaceFilter;

use strict;
use base qw( XML::SAX::Base );
use Storable;
our $VERSION = 'v1.01.0';

our $AUTOLOAD;

=head1 NAME

Net::OAI::Record::NamespaceFilter - general filter class

=head1 SYNOPSIS

=head1 DESCRIPTION

This SAX filter takes a hashref C<namespaces> as argument, with
namespace URIs for keys and SAX filters/builders (or undef) for values.
It will forward any element belonging to a namespace from this list 
to the associated SAX filter and all of its children (regardless of their 
respective namespace) to the same one. It can be used either as a 
C<metadataHandler> or C<recordHandler>.

 my $parsed;
 $builder = XML::SAX::Writer->new(Output => \$parsed);
 $builder->start_document();
 my $rootEL = { Name => '{}ROOT',
           LocalName => 'ROOT',
        NamespaceURI => "",
              Prefix => "",
          Attributes => {}
              };
 $builder->start_element($rootEL);

 # filter for OAI-Namespace in records: forward all
 $filter = Net::OAI::Harvester::Record::NamespaceFilter(
      'http://www.openarchives.org/OAI/2.0/' => $builder);
 $harvester = Net::OAI::Harvester->new( [
     baseURL => ...,
     recordHandler => $filter,
     ] );

 $list = $harvester->listRecords( 
    metadataPrefix  => 'a_strange_one',
    recordHandler => $filter,
  );

 $builder->end_element($rootEL);
 $builder->end_document();
 print $parsed;



If the list of namespaces ist empty or no handler (builder) is connected to 
a filter, it effectively acts as a plug to Net::OAI::Harvester. This
might come handy if you are planning to get to the raw result gy other
means, e.g. by tapping the user agent or accessing the result's xml() method:

 $plug = Net::OAI::Harvester::Record::NamespaceFilter();
 $harvester = Net::OAI::Harvester->new( [
     baseURL => ...,
     recordHandler => $plug,
     ] );

 my $unparsed;
 open (my $TAP, ">", \$unparsed);
 $harvester->userAgent()->add_handler(response_data => sub { 
        my($response, $ua, $h, $data) = @_;
        print $TAP $data;
     });

 $list = $harvester->listRecords( 
    metadataPrefix  => 'a_strange_one',
    recordHandler => $plug,
  );

 print $unparsed;     # complete OAI response
 print $list->xml();  # should be the same


=head1 METHODS


=head2 new()


=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless { namespaces => {%opts} }, ref( $class ) || $class;
    $self->{ _activeStack } = [];
    $self->{ _tagStack } = [];
    $self->{ _result } = [];
    $self->set_handler( undef );
    delete $self->{ _noHandler };  # follows set_handler()
    return( $self );
}


## SAX handlers

sub STORABLE_freeze {
  my ($obj, $cloning) = @_;
  return if $cloning;
  return "", @{$obj->{ _result }};   # || undef;
}

sub STORABLE_thaw {
  my ($obj, $cloning, $serialized, @list) = @_;
  return if $cloning;
  $obj->{ _result } = [@list];
}


## SAX handlers

sub start_element {
    my ( $self, $element ) = @_;

    if ( $self->{ _activeStack }->[0] ) {   # handler already set up
      }
    elsif ( exists $self->{ namespaces }->{$element->{ NamespaceURI }} ) {
        my $hdl = $self->{ namespaces }->{$element->{ NamespaceURI }};
        if ( defined $hdl ) {
            $self->set_handler($hdl);
            $hdl->start_document();
            $self->{ _noHandler } = 0;
          };
      }
    else {
        push (@{$self->{ _tagStack }}, $element->{ Name });
        return;
      };

    push (@{$self->{ _activeStack }}, $element->{ Name });
    $self->SUPER::start_element($element) unless $self->{ _noHandler };
}

sub end_element {
    my ( $self, $element ) = @_;
    unless ( $self->{ _activeStack }->[0] ) {
        pop (@{$self->{ _tagStack }});
        return;
      };

    pop (@{$self->{ _activeStack }});
    $self->SUPER::end_element($element) unless $self->{ _noHandler };

    unless ( $self->{ _activeStack }->[0] ) {
        unless ( $self->{ _noHandler } ) {
            push(@{$self->{ _result }}, $self->get_handler()->end_document());
            $self->set_handler(undef);
            $self->{ _noHandler } = 1;
          }
    };

}

sub characters {
    my ( $self, $characters ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::characters( $characters );
}

sub ignorable_whitespace {
    my ( $self, $characters ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::ignorable_whitespace( $characters );
}

sub comment {
    my ( $self, $comment ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::comment( $comment );
}

sub processing_instruction {
    my ( $self, $pi ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::processing_instruction( $pi );
}

1;

