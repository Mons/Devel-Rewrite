#!/usr/bin/env perl

use lib::abs '../lib', 'lib';
use Test::More tests => 28;
use Test::NoWarnings;

use Devel::Rewrite 0.03;
use t::ok::test1;
{
	no Devel::Rewrite;
	use t::no::test3;
}
BEGIN{ eval 'use t::ok::test5'; }
for (qw( 5 v5 5.000 5.010 5.010000 5.008008 v5.010 5.10.0 )) {
	ok eval 'use '.$_.'; 1',    'use '.$_ or diag "  $@";
}

my $include;
my $rewrite;

is t::ok::test1::test1(), 'rewritten', 'enabled t1.rewrite' and $rewrite++;
is t::ok::test1::test2(), 'rewritten', 'enabled t1.include' and $include++;
is t::ok::test1::test3(), 'rwok',      'enabled t1.include..' and $include++;

is t::ok::test2::test1(), 'rewritten', 'enabled t2.rewrite (nested)';
is t::ok::test2::test2(), 'rewritten', 'enabled t2.include (nested)';
is t::ok::test2::test3(), 'rwok',      'enabled t2.include.. (nested)';

is t::no::test3::test1(), 'not rewritten', 'disabled t3.rewrite';
is t::no::test3::test2(), 'not rewritten', 'disabled t3.include';

is t::no::test4::test1(), 'not rewritten', 'disabled t4.rewrite (nested)';
is t::no::test4::test2(), 'not rewritten', 'disabled t4.include (nested)';

is t::ok::test5::test1(), 'rewritten', 'enabled t5.rewrite' and $rewrite++;
is t::ok::test5::test2(), 'rewritten', 'enabled t5.include' and $include++;
is t::ok::test5::test3(), 'rwok',      'enabled t5.include..' and $include++;

is t::ok::test6::test1(), 'rewritten', 'enabled t6.rewrite (nested)' and $rewrite++;
is t::ok::test6::test2(), 'rewritten', 'enabled t6.include (nested)' and $include++;
is t::ok::test6::test3(), 'rwok',      'enabled t6.include.. (nested)' and $include++;

ok ! eval q'use t::no::test7; 1', 'strict inside works';

ok $rewrite, 'rewrite works';
ok $include, 'inculde works';
