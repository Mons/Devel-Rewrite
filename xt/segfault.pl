#!/usr/bin/env perl

use lib::abs '../lib';
use uni::perl ':dumper';
use Test::More tests => 4;
use Test::NoWarnings;
use Time::HiRes 'alarm';
alarm 0.1;
# use Devel::Rewrite;

unshift @INC, sub {
	#print STDERR "# @_\n";
	open my $fh, '<:raw',lib::abs::path('lib/'.$_[1]) or return;
	return ($fh,sub { print STDERR "@_ | $_ ";return length($_) ? 1 : 0 },'zzz');
};
use_ok 't::inc::test1';
is t::inc::test1::ok(), 'ok1', 'method 1';
is t::inc::test2::ok(), 'ok2', 'method 2';
#delete $INC{'t/inc/test1.pm'};
#delete $INC{'t/inc/test2.pm'};

warn dumper \%t::inc::test1::;

__END__
pop @INC;
undef *t::inc::test1::ok;
undef *t::inc::test2::ok;

unshift @INC, sub {
	#print STDERR "# @_\n";
	open my $fh, '<',lib::abs::path('lib/'.$_[1]) or return;
	return ($fh,sub { s{ok(\d)}{okk$1}s; print STDERR "@_ | $_ "; return length($_) ? 1 : 0 },'zzz');
};

use_ok 't::inc::test1';
is t::inc::test1::ok(), 'okk1', 'method 1';
is t::inc::test2::ok(), 'okk2', 'method 2';
