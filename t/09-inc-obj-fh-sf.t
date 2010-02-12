#!/usr/bin/env perl -w

use lib::abs '../lib';
use Test::More tests => 16;
use Test::NoWarnings;
use Devel::Rewrite;
alarm 1;

sub t::INC {
	my $f = $_[1];
	open my $fh, '<',lib::abs::path('lib/'.$f) or return;
	return ($fh,sub {
		is $_[1], 's:'.$f, 'arg '.$f;
		s{ok(\d)}{okk$1}s;
		return length($_) ? 1 : 0
	},'s:'.$f);
}

unshift @INC, bless {},'t';
use_ok 't::inc::test1';
is t::inc::test1::ok(), 'okk1', 'method 1';
is t::inc::test2::ok(), 'okk2', 'method 2';
is $INC{'t/inc/test1.pm'}, $INC[0], '%INC';
