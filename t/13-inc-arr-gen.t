#!/usr/bin/env perl -w

use lib::abs '../lib';
use Test::More tests => 18;
use Test::NoWarnings;
use Devel::Rewrite;
alarm 1;

unshift @INC, [ sub {
	# print STDERR "# @_\n";
	my $f = $_[1];
	is_deeply [ @{$_[0]}[1..$#{$_[0]}] ], [qw(x y)], 'args '.$f;
	open my $fh, '<:raw',lib::abs::path('lib/'.$f) or return;
	return (sub {
		is $_[1], 's:'.$f, 'arg';
		defined( $_ = <$fh> ) and return 1;
		close($fh); return 0;
	},'s:'.$f);
}, qw(x y)];

use_ok 't::inc::test1';
is t::inc::test1::ok(), 'ok1', 'method 1';
is t::inc::test2::ok(), 'ok2', 'method 2';
is $INC{'t/inc/test1.pm'}, $INC[0], '%INC';
