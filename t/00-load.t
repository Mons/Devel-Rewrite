#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Devel::Rewrite' );
}

diag( "Testing Devel::Rewrite $Devel::Rewrite::VERSION, Perl $], $^X" );
