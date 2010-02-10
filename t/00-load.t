#!/usr/bin/env perl

use lib::abs '../lib';
use Test::More tests => 3;
use Test::NoWarnings;

BEGIN {
	use_ok( 'Devel::Rewrite' );
	ok Devel::Rewrite::in_effect, 'in effect';
}

diag( "Testing Devel::Rewrite $Devel::Rewrite::VERSION, Perl $], $^X" );
