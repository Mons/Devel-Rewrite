#!/usr/bin/env perl -w

use lib::abs '../lib';
use Test::More tests => 22;
use Test::NoWarnings;
#use Devel::Rewrite;
alarm 1;

unshift @INC, my $code = sub {
	#print STDERR "# @_\n";
	my $f = $_[1];
	open my $fh, '<:raw',lib::abs::path('lib/'.$f) or return;
	if ($f =~ /test2/) {
		$INC{$f} = '/custom/path/'.$f;
	}
	return (sub {
		is $_[1], 's:'.$f, 'arg '.$f;
		defined( $_ = <$fh> ) and return 1;
		close($fh);
		return 0;
	},'s:'.$f);
};


use_ok 't::inc::test1';
is t::inc::test1::ok(), 'ok1', 'method 1';
is t::inc::test2::ok(), 'ok2', 'method 2';
(my $ref) = "$code" =~ /\((0x.+)\)/;
ok $ref, 'have refaddr' or diag "$INC[0]";
is t::inc::test1::cl(), "/loader/$ref/t/inc/test1.pm", 'caller';
is t::inc::test1::fl(), "/loader/$ref/t/inc/test1.pm", '__FILE__';
is t::inc::test2::cl(), "/custom/path/t/inc/test2.pm", 'caller';
is t::inc::test2::fl(), "/custom/path/t/inc/test2.pm", '__FILE__';
is $INC{'t/inc/test1.pm'}, $code, '%INC 1';
is $INC{'t/inc/test2.pm'}, '/custom/path/t/inc/test2.pm', '%INC 2';
