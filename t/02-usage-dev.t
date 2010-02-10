#!/usr/bin/env perl

use lib::abs '../lib', 'lib';
use Test::More tests => 18;
use Test::NoWarnings;

use Devel::Rewrite;
use t::ok::test1;
{
	no Devel::Rewrite;
	use t::no::test3;
}
BEGIN{ eval 'use t::ok::test5'; }

is t::ok::test1::test1(), 'rewritten', 't1.1';
is t::ok::test1::test2(), 'rewritten', 't1.2';
is t::ok::test1::test3(), 'rwok',      't1.3';

is t::ok::test2::test1(), 'rewritten', 't2.1';
is t::ok::test2::test2(), 'rewritten', 't2.2';
is t::ok::test2::test3(), 'rwok',      't2.3';

is t::no::test3::test1(), 'not rewritten', 't3.1';
is t::no::test3::test2(), 'not rewritten', 't3.2';

is t::no::test4::test1(), 'not rewritten', 't4.1';
is t::no::test4::test2(), 'not rewritten', 't4.2';

is t::ok::test5::test1(), 'rewritten', 't5.1';
is t::ok::test5::test2(), 'rewritten', 't5.2';
is t::ok::test5::test3(), 'rwok',      't5.3';

is t::ok::test6::test1(), 'rewritten', 't6.1';
is t::ok::test6::test2(), 'rewritten', 't6.2';
is t::ok::test6::test3(), 'rwok',      't6.3';

ok ! eval q'use t::no::test7; 1', 'strict inside works';