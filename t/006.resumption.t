use Test::More tests=>5;

use strict;
use_ok( 'Net::OAI::ResumptionToken' );

my $token = Net::OAI::ResumptionToken->new();
isa_ok( $token, 'Net::OAI::ResumptionToken' );

$token->expirationDate( 'May-28-1969' );
is( $token->expirationDate(), 'May-28-1969', 'expirationDate()' );

$token->completeListSize( 2000 );
is( $token->completeListSize(), 2000, 'completeListSize()' );

$token->cursor( 1000 );
is( $token->cursor(), 1000, 'cursor()' );

