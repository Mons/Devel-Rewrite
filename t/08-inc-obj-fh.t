#!/usr/bin/env perl -w

use lib::abs '../lib';
use Test::More tests => 5;
use Test::NoWarnings;
use Devel::Rewrite;
alarm 1;

sub t::INC {
	open my $fh, '<',lib::abs::path('lib/'.$_[1]) or return;
	return ($fh);
}

unshift @INC, bless {},'t';
use_ok 't::inc::test1';
is t::inc::test1::ok(), 'ok1', 'method 1';
is t::inc::test2::ok(), 'ok2', 'method 2';
is $INC{'t/inc/test1.pm'}, $INC[0], '%INC';
