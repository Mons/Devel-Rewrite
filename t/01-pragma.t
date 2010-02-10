#!/usr/bin/env perl

use lib::abs '../lib';
use Test::More tests => 6;
use Test::NoWarnings;

use Devel::Rewrite;
ok Devel::Rewrite::in_effect, 'in effect l1 before';
{
	no Devel::Rewrite;
	ok !Devel::Rewrite::in_effect, '!in effect l2 before';
	{
		use Devel::Rewrite;
		ok Devel::Rewrite::in_effect, 'in effect l3';
	}
	ok !Devel::Rewrite::in_effect, '!in effect l2 after';
	
}
ok Devel::Rewrite::in_effect, 'in effect l1 after';
