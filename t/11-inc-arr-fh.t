#!/usr/bin/env perl -w

use lib::abs '../lib';
use Test::More tests => 7;
use Test::NoWarnings;
use Devel::Rewrite;
alarm 1;

unshift @INC, [ sub {
	# print STDERR "# @_\n";
	is_deeply [ @{$_[0]}[1..$#{$_[0]}] ], [qw(x y)], 'args '.$_[1];
	open my $fh, '<:raw',lib::abs::path('lib/'.$_[1]) or return;
	return ($fh);
}, qw(x y)];
use_ok 't::inc::test1';
is t::inc::test1::ok(), 'ok1', 'method 1';
is t::inc::test2::ok(), 'ok2', 'method 2';
is $INC{'t/inc/test1.pm'}, $INC[0], '%INC';

